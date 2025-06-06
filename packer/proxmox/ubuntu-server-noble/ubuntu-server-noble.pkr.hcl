# Ubuntu Server 24
# ---
# Packer Template to create an Ubuntu Server (24) on Proxmox

# Variable Definitions
packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-server-24" {

    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true

    # VM General Settings
    node = "matrix"
    vm_id = "100"
    vm_name = "ubuntu-server-24-noble"
    template_description = "Ubuntu Server 24 (Noble) Image"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
    # (Option 2) Download ISO
    # iso_url = "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
    iso_checksum = "d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
    iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true
    machine = "q35"

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "80G"
        format = "raw"
        storage_pool = "local-zfs"
        storage_pool_type = "zfs"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "2"
    cpu_type = "x86-64-v4" # Compatible with Intel CPU >= Skylake, AMD CPU >= EPYC v4 Genoa. Added CPU flags compared to x86-64-v3: +avx512f, +avx512bw, +avx512cd, +avx512dq, +avx512vl.

    # VM Memory Settings
    memory = "16384"

    # VM Network Settings
    network_adapters {
        model = "virtio" # needs to have DHCP - if not create an adapter that allows it
        bridge = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-zfs"

     # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]

    boot                    = "c"
    boot_wait               = "10s"
    communicator            = "ssh"

    # PACKER Autoinstall Settings
    http_directory = "http"
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "mike"

    # (Option 1) Password
    # ssh_password = "your-password"
    # (Option 2) Private Key
    ssh_private_key_file = "~/.ssh/id_ed25519"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "15m"
    ssh_pty     = true
}

build {
    name = "ubuntu-server-24"
    sources = ["proxmox-iso.ubuntu-server-24"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync",
            "sudo echo 'Ubuntu 24.04 Template by Packer' | sudo tee /etc/issue"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # # Docker installation
    # provisioner "shell" {
    #     inline = [
    #         "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
    #         "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
    #         "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
    #         "sudo apt-get -y update",
    #         "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    #     ]
    # }
}