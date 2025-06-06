# Proxmox

## Network configuration

Credits https://github.com/saudiqbal

https://saudiqbal.github.io/Proxmox/proxmox-IPv6-interface-setup-DHCPv6-or-static.html

Proxmox IPv6 interface setup DHCPv6 or static
Proxmox host setup instructions for setting up IPv6 using DHCPv6 or static configuration. This configuration example also allows the default port 8006 on 443 so that you can directly access your Proxmox server without typing :8006 in the end. Iptable example for Proxmox IP addresses are fd00::10 and 192.168.1.10 for allowing direct Proxmox access on port 443.

Static config

Proxmox bridge example with static IPv6 and IPv4, change the IPs accordingly.

/etc/network/interfaces

```sh
# network interface settings; autogenerated
# Please do NOT modify this file directly, unless you know what
# you're doing.
#
# If you want to manage parts of the network configuration manually,
# please utilize the 'source' or 'source-directory' directives to do
# so.
# PVE will preserve these directives, but will NOT read its network
# configuration from sourced files, so do not attempt to move any of
# the PVE managed interfaces into external files!

auto lo
iface lo inet loopback

iface eno1 inet manual

auto vmbr0
iface vmbr0 inet static
	address 192.168.1.10/24
	gateway 192.168.1.1
	bridge-ports eno1
	bridge-stp off
	bridge-fd 0
	post-up iptables -t nat -A PREROUTING -p tcp -d 192.168.1.10 --dport 443 -j REDIRECT --to-ports 8006

iface vmbr0 inet6 static
	address fd00::10/64
	gateway fd00::1
	accept_ra 2
	post-up ip6tables -t nat -A PREROUTING -p tcp -d fd00::10 --dport 443 -j REDIRECT --to-ports 8006
```

DHCP config

Proxmox bridge example with DHCPv6 for IPv6 and DHCPv4 for IPv4, change the IPs accordingly.

/etc/network/interfaces

```sh
# network interface settings; autogenerated
# Please do NOT modify this file directly, unless you know what
# you're doing.
#
# If you want to manage parts of the network configuration manually,
# please utilize the 'source' or 'source-directory' directives to do
# so.
# PVE will preserve these directives, but will NOT read its network
# configuration from sourced files, so do not attempt to move any of
# the PVE managed interfaces into external files!

auto lo
iface lo inet loopback

iface eno1 inet manual

auto vmbr0
allow-hotplug vmbr0
iface vmbr0 inet dhcp
	gateway 192.168.1.1
	bridge-ports eno1
	bridge-stp off
	bridge-fd 0
	post-up iptables -t nat -A PREROUTING -p tcp -d 192.168.1.10 --dport 443 -j REDIRECT --to-ports 8006


iface vmbr0 inet6 dhcp
	gateway fd00::1
	accept_ra 2
	post-up ip6tables -t nat -A PREROUTING -p tcp -d fd00::10 --dport 443 -j REDIRECT --to-ports 8006
```

Copy Code

Now edit the file /etc/dhcp/dhclient.conf and add this code at the bottom of the file.

```sh
/etc/dhcp/dhclient.conf
interface "vmbr0" {
send dhcp6.client-id 00:03:00:01:bc:24:11:00:00:00;
}
```

Copy Code
Then run these commands in the Proxmox terminal `rm /var/lib/dhcp/*` and `systemctl restart networking`

Finally don't forget to add `net.ipv6.conf.vmbr0.accept_ra=2` to your `/etc/sysctl.conf` file and reboot ProxMox.
