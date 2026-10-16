"""Offline checks: render manifests, never contact or mutate the Kubernetes cluster."""
import ipaddress
import os
from pathlib import Path
import subprocess
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]


def render(path):
    result = subprocess.run(['kubectl', 'kustomize', str(ROOT / path)],
                            check=True, capture_output=True, text=True)
    return [d for d in yaml.safe_load_all(result.stdout) if d]


class GitLabHomelabTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = render('apps/overlays/zion/gitlab')
        cls.ingress = render('infrastructure/network/gitlab-ingress')
        cls.values = yaml.safe_load((ROOT / 'infrastructure/network/gitlab-ingress/values.yaml').read_text())

    def one(self, kind):
        items = [d for d in self.app if d['kind'] == kind]
        self.assertEqual(len(items), 1)
        return items[0]

    def test_gitlab_has_no_direct_external_service(self):
        service = self.one('Service')['spec']
        self.assertEqual(service['type'], 'ClusterIP')
        self.assertNotIn('externalIPs', service)
        self.assertEqual([p['port'] for p in service['ports']], [80])
        self.assertTrue(all('nodePort' not in p for p in service['ports']))

    def test_every_route_is_private_and_filtered(self):
        ingress = self.one('IngressRoute')
        self.assertEqual(ingress['metadata']['annotations']['kubernetes.io/ingress.class'], 'gitlab-lan')
        for route in ingress['spec']['routes']:
            self.assertEqual(route['middlewares'], [{'name': 'zion-gitlab-lan-only'}])
            self.assertEqual(route['services'], [{'name': 'zion-gitlab', 'port': 80}])
        spec = self.one('Middleware')['spec']
        self.assertEqual(set(spec), {'ipAllowList'})
        allowed = spec['ipAllowList']
        self.assertNotIn('ipStrategy', allowed, 'Client-supplied headers must not select the allowed IP')
        nets = [ipaddress.ip_network(c) for c in allowed['sourceRange']]
        self.assertEqual(set(allowed['sourceRange']), {'10.69.10.0/24', '10.69.174.49/32'})
        for address, expected in [('10.69.10.20', True), ('10.69.174.49', True),
                                  ('10.69.174.50', False), ('10.69.99.69', False),
                                  ('192.168.1.1', False), ('1.1.1.1', False)]:
            self.assertEqual(any(ipaddress.ip_address(address) in n for n in nets), expected, address)
        self.assertEqual(allowed['sourceRange'], self.values['service']['spec']['loadBalancerSourceRanges'])

    def test_backend_accepts_only_private_ingress_pods(self):
        policy = self.one('NetworkPolicy')['spec']
        self.assertEqual(policy['podSelector'], {'matchLabels': {'app': 'gitlab'}})
        self.assertEqual(policy['policyTypes'], ['Ingress'])
        self.assertEqual(len(policy['ingress']), 1)
        rule = policy['ingress'][0]
        self.assertEqual(rule['ports'], [{'protocol': 'TCP', 'port': 80}])
        self.assertEqual(rule['from'], [{
            'namespaceSelector': {'matchLabels': {'kubernetes.io/metadata.name': 'gitlab-ingress'}},
            'podSelector': {'matchLabels': {'homelab.milanchis.com/role': 'gitlab-ingress'}},
        }])

    def test_persistent_storage_has_single_writer(self):
        deployment = self.one('Deployment')['spec']
        self.assertEqual(deployment['strategy'], {'type': 'Recreate'})
        self.assertEqual(deployment['replicas'], 1)
        pod = deployment['template']['spec']
        self.assertFalse(pod['automountServiceAccountToken'])
        claims = {d['metadata']['name']: d for d in self.app if d['kind'] == 'PersistentVolumeClaim'}
        self.assertEqual(claims['zion-gitlab-data']['spec']['resources']['requests']['storage'], '50Gi')
        for claim in claims.values():
            self.assertEqual(claim['spec']['storageClassName'], 'longhorn')
            self.assertEqual(claim['metadata']['annotations']['kustomize.toolkit.fluxcd.io/prune'], 'disabled')
        mounts = {m['mountPath']: m['name'] for m in pod['containers'][0]['volumeMounts']}
        volumes = {v['name']: v for v in pod['volumes']}
        for path in ['/etc/gitlab', '/var/opt/gitlab', '/var/log/gitlab']:
            self.assertIn(volumes[mounts[path]]['persistentVolumeClaim']['claimName'], claims)

    def test_oidc_requires_secret_and_approval_for_new_users(self):
        pod = self.one('Deployment')['spec']['template']['spec']
        secret = next(v for v in pod['volumes'] if v['name'] == 'oidc')['secret']
        self.assertEqual(secret['secretName'], 'zion-gitlab-oidc')
        self.assertFalse(secret.get('optional', False))
        config = next(e['value'] for e in pod['containers'][0]['env'] if e['name'] == 'GITLAB_OMNIBUS_CONFIG')
        self.assertIn("['omniauth_block_auto_created_users'] = true", config)
        self.assertIn("['omniauth_auto_link_user'] = []", config)
        self.assertIn("File.read('/run/secrets/gitlab-oidc/client-secret')", config)
        result = subprocess.run(['ruby', '-c'], input=config, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_backend_stays_unready_until_private_bootstrap(self):
        container = self.one('Deployment')['spec']['template']['spec']['containers'][0]
        command = container['readinessProbe']['exec']['command']
        self.assertEqual(command[:2], ['bash', '-ec'])
        self.assertIn('test -f /var/opt/gitlab/gitlab-rails/.homelab-private-defaults-ready &&', command[2])
        self.assertIn('/-/readiness?all=1', command[2])

    def test_credentials_are_strict_scope_sealed_secrets(self):
        secrets = [d for d in self.app if d['kind'] == 'SealedSecret']
        self.assertEqual({d['metadata']['name'] for d in secrets},
                         {'zion-gitlab-credentials', 'zion-gitlab-oidc'})
        self.assertFalse(any(d['kind'] == 'Secret' for d in self.app))
        for secret in secrets:
            self.assertEqual(secret['metadata']['namespace'], 'gitlab')
            self.assertEqual(secret['metadata']['name'], secret['spec']['template']['metadata']['name'])
            self.assertNotIn('sealedsecrets.bitnami.com/namespace-wide', secret['metadata'].get('annotations', {}))
            self.assertNotIn('sealedsecrets.bitnami.com/cluster-wide', secret['metadata'].get('annotations', {}))
            self.assertTrue(all(value.startswith('Ag') and len(value) > 500
                                for value in secret['spec']['encryptedData'].values()))
            self.assertNotIn('data', secret['spec']['template'])
            self.assertNotIn('stringData', secret['spec']['template'])

    def test_oidc_uses_the_private_authentik_route(self):
        pod = self.one('Deployment')['spec']['template']['spec']
        self.assertIn({'ip': '10.69.99.69', 'hostnames': ['authentik.milanchis.com']}, pod['hostAliases'])
        self.assertEqual(self.values['service']['annotations']['metallb.universe.tf/loadBalancerIPs'], '10.69.70.21')

    def test_ingress_configmap_reference_resolves(self):
        cm = next(d for d in self.ingress if d['kind'] == 'ConfigMap')
        hr = next(d for d in self.ingress if d['kind'] == 'HelmRelease')
        self.assertEqual(hr['spec']['valuesFrom'][0]['name'], cm['metadata']['name'])
        self.assertEqual(hr['spec']['install']['crds'], 'Skip')
        self.assertEqual(hr['spec']['upgrade']['crds'], 'Skip')

    @unittest.skipUnless(os.environ.get('HOMELAB_TRAEFIK_CHART'), 'Set HOMELAB_TRAEFIK_CHART to the pinned chart archive')
    def test_actual_helm_chart_renders_security_controls(self):
        result = subprocess.run(['helm', 'template', 'gitlab-ingress', os.environ['HOMELAB_TRAEFIK_CHART'],
                                 '--namespace', 'gitlab-ingress', '--kube-version', '1.33.3',
                                 '--values', str(ROOT / 'infrastructure/network/gitlab-ingress/values.yaml')],
                                check=True, capture_output=True, text=True)
        docs = [d for d in yaml.safe_load_all(result.stdout) if d]
        self.assertFalse(any(d['kind'] in ['ClusterRole', 'ClusterRoleBinding', 'IngressRoute'] for d in docs))
        service = next(d for d in docs if d['kind'] == 'Service')['spec']
        self.assertEqual(service['loadBalancerSourceRanges'], ['10.69.10.0/24', '10.69.174.49/32'])
        self.assertEqual(service['externalTrafficPolicy'], 'Local')
        self.assertFalse(service['allocateLoadBalancerNodePorts'])
        self.assertEqual([p['port'] for p in service['ports']], [443])
        deployment = next(d for d in docs if d['kind'] == 'Deployment')['spec']['template']
        self.assertEqual(deployment['metadata']['labels']['homelab.milanchis.com/role'], 'gitlab-ingress')
        container = deployment['spec']['containers'][0]
        self.assertEqual(container['image'], 'docker.io/traefik:v3.7.15')
        args = container['args']
        self.assertIn('--providers.kubernetescrd.ingressClass=gitlab-lan', args)
        self.assertIn('--providers.kubernetescrd.namespaces=gitlab', args)
        self.assertFalse(any('insecure=true' in a or '--api.dashboard=true' == a for a in args))


if __name__ == '__main__':
    unittest.main()
