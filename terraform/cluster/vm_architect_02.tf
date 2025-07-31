resource "proxmox_vm_qemu" "architect_02" {
    name = "architect-02"
    desc = "CICD Ubuntu Server 24"
    vmid = "112"
    target_node = "matrix"
    onboot  = true

    agent = 1 # qemu

    clone = "ubuntu-server-24-noble" # name of the template VM to clone from

    cores = 4
    cpu_type = "x86-64-v4"
    memory = 24000

    network {
        id  = 0
        bridge = "vmbr0"
        model = "virtio"
    }

    scsihw = "virtio-scsi-single"

    disks {
        ide {
            ide0 {
                cloudinit {
                    storage = "local-zfs"
                }
            }
        }
        virtio {
            virtio0 {
                disk {
                    storage = "local-zfs"
                    size = "80G"
                    # NOTE Enable IOThread for better disk performance in virtio-scsi-single
                    #      and enable disk replication
                    iothread = true
                    replicate = true
                }
            }
        }
    }

    os_type = "cloud-init"
    ipconfig0 = "ip=10.69.5.12/16,gw=10.69.0.1"
    nameserver = "10.69.0.1"

    ciuser = "mike"
    sshkeys = file(var.ssh_public_key_path)
}
