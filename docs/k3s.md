# install

curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik --cluster-init --tls-san=192.168.69.13 --tls-san=test.local --tls-san=0.0.0.0 --write-kubeconfig-mode 640 --write-kubeconfig-group sudo


# agent


curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik --server http://192.168.69.13:6443  --write-kubeconfig-mode 640 --write-kubeconfig-group sudo

curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik --server https://192.168.69.13:6443 -write-kubeconfig-mode 640 --write-kubeconfig-group sudo

curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik --server https://192.168.69.13:6443 --write-kubeconfig-mode 640 --write-kubeconfig-group sudo




curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik server --server https://192.168.69.13:6443 -write-kubeconfig-mode 640 --write-kubeconfig-group sudo

curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN sh -s - --disable traefik --server https://192.168.69.13:6443 --write-kubeconfig-mode 640 --write-kubeconfig-group sudo --debug



curl -sfL https://get.k3s.io | K3S_URL=https://192.168.69.13:6443 K3S_TOKEN=$K3S_TOKEN sh -

this worked to launch agent
sudo k3s agent --server https://192.168.69.13:6443 --token $K3S_TOKEN
