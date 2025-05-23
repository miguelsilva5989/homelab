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
| Storage         | 2x 2TB Samsung 990 Pro NVME (ZFS RAID 1)       |
| Case | Silverstone SST-RM44 4U |

---

### Secondary Server: Existing Hyperconverged Node

Currently running legacy VMs and Docker workloads. Acts as a backup node or experimental environment.

| Component            | Specification                  |
|----------------------|--------------------------------|
| OS                   | Unraid 7.0.1                  |
| CPU                  | AMD Ryzen 5 5600G              |
| RAM             | 32GB - 2x 16GB       |
| GPU                  | Intel ARC A380                 |
| Storage               | 2 x 16TB Toshiba disks (RAID-like with 1 parity disk) |

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
