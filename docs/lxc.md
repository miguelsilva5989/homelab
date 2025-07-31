# NOPE - not good for kubernetes - problems with longhorn, etc
# LXC Kubernetes

<https://gist.github.com/triangletodd/02f595cd4c0dc9aac5f7763ca2264185>

## On the host

### Ensure these modules are loaded

```shell
cat /proc/sys/net/bridge/bridge-nf-call-iptables
```

#### Disable swap

```shell
sysctl vm.swappiness=0
swapoff -a
```

#### Enable IP Forwarding

The first time I tried to get this working, once the cluster was up, the traefik pods were in CrashloopBackoff due to ip_forwarding being disabled. Since LXC containers share the host's kernel, we need to enable this on the host.

```sh
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl --system
```

## Create the k3s container

### Uncheck unprivileged container

#### Set swap to 0

#### Enable DHCP

## Back on the Host

Edit the config file for the container (`/etc/pve/lxc/$ID.conf`) and add the following:

```text
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
lxc.mount.auto: "proc:rw sys:rw"
```

Mine was like this

```sh
arch: amd64
cores: 2
hostname: architect-N
memory: 16384
net0: name=eth0,bridge=vmbr0,firewall=1,gw=10.69.0.1,hwaddr=BC:24:11:D8:F6:61,ip=10.69.6.1/16,ip6=dhcp,type=veth
ostype: ubuntu
rootfs: local-zfs:subvol-200-disk-0,size=80G
swap: 0

lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
lxc.mount.auto: "proc:rw sys:rw"
```

## In the container

### /etc/rc.local

/etc/rc.local doesn't exist in the default 20.04 LXC template provided by Rroxmox. Create it with these contents:

```sh
#!/bin/sh -e

# Kubeadm 1.15 needs /dev/kmsg to be there, but it's not in lxc, but we can just use /dev/console instead
# see: https://github.com/kubernetes-sigs/kind/issues/662
if [ ! -e /dev/kmsg ]; then
    ln -s /dev/console /dev/kmsg
fi

# https://medium.com/@kvaps/run-kubernetes-in-lxc-container-f04aa94b6c9c
mount --make-rshared /
```

Then run this:

```shell
chmod +x /etc/rc.local
reboot
```

Some extras

```sh
sh root@10.69.6.1
apt-get update
apt install curl
```

On host

```sh
ssh-copy-id root@10.69.6.1
k3sup join --ip 10.69.6.1 --server-ip 10.69.69.1 --user root --server-user mike
```
