resource "proxmox_vm_qemu" "architect_01" {
    name = "architect-03"
    desc = "CICD Ubuntu Server 24"
    vmid = "113"
    target_node = "matrix"

    agent = 1 # qemu

    clone = "ubuntu-server-24-noble" # name of the template VM to clone from
    cores = 2
    memory = 16384

    os_type = "cloud-init"
    ipconfig0 = "ip=10.69.5.13/16,gw=10.69.0.1"
    nameserver = "10.69.0.1"

    ciuser = "mike"
    sshkeys = file(var.ssh_public_key_path)
}