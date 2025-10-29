# 🏠 Homelab Infrastructure & Configuration

This repository documents my end-to-end journey in architecting and deploying a robust homelab environment from the ground up.

## Architecture Overview

My goal is to build a scalable and maintainable virtualized infrastructure using:

- **Proxmox VE** as the hypervisor platform for running multiple VMs.
- **Packer**, **Terraform**, and **Ansible** for automated VM creation, provisioning, and configuration management.
- **k3s** lightweight Kubernetes distribution for container orchestration and workload management.
- **FluxCD** for GitOps-based continuous deployment of Kubernetes manifests, enabling declarative infrastructure and application lifecycle management.
- **GitLab** to automate build, test, and deployment pipelines.

This integrated CI/CD approach enables full automation of infrastructure and application workflows, ensuring repeatability, consistency, and rapid iteration based on Git-driven triggers.

---

## Infrastructure Details

### Primary Server: Bare-Metal Host for Virtualization

This server is dedicated to running Proxmox VE and hosting the main VM workloads.

| Component       | Specification                        |
|-----------------|------------------------------------|
| OS              | Proxmox VE (virtualization platform)|
| Motherboard     | Supermicro MBD-H13SSL-N-O           |
| CPU             | AMD EPYC 9124 Genoa (16 cores)      |
| RAM             | 128GB - 4 x 32GB Micron DDR5 4800 MHz       |
| GPU                  | Intel ARC A380                 |
| Storage (OS/VM)        | 2x 2TB Samsung 990 Pro NVME (ZFS RAID 1)       |
| Storage (Media)              | 2 x 16TB Toshiba disks (RAID-like with 1 parity disk) |
| Case | Silverstone SST-RM44 4U |

---

### Kubernetes Edge Nodes

Lightweight nodes for Kubernetes High Availability (HA) testing and edge workloads.

| Device            | Specification         |
|-------------------|-----------------------|
| Raspberry Pi 4    | 8GB RAM, ARM-based SoC|

2 nodes currently configured to run k3s cluster pods, providing HA and cluster resiliency.

---

### Network

| Component | Specification |
|-----------|---------------|
| Router | Ubiquiti UDM-SE |

---

## Summary

This layered infrastructure combines enterprise-grade bare-metal hardware, virtualization, container orchestration, and GitOps practices. The stack is designed to facilitate rapid deployment, stateful infrastructure management, and iterative learning about cloud-native operations and automation tooling.
