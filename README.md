# Homelab Infrastructure & Configuration

This repository documents my end-to-end journey in architecting and deploying a robust homelab environment from the ground up.

## Architecture Overview

My goal is to build a scalable and maintainable virtualized infrastructure using:

- **Proxmox VE** as the hypervisor platform for running multiple VMs.
- **Packer**, **OpenTofu (Terraform alternative)**, and **Ansible** for automated VM creation, provisioning, and configuration management.
- **k3s** lightweight Kubernetes distribution for container orchestration and workload management.
- **FluxCD** for GitOps-based continuous deployment of Kubernetes manifests, enabling declarative infrastructure and application lifecycle management.

This tech stack enables me to develop Infrastructure as Code (IaC) capabilities while gaining hands-on experience with modern DevOps and cloud-native concepts.

---

## Infrastructure Details

### Primary Server: Bare-Metal Host for Virtualization

This server is dedicated to running Proxmox VE and hosting the main VM workloads.

| Component       | Specification                        |
|-----------------|------------------------------------|
| Motherboard     | Supermicro MBD-H13SSL-N-O           |
| CPU             | AMD EPYC 9124 Genoa (16 cores)      |
| RAM             | 4 x 32GB Micron DDR5 4800 MHz       |
| OS              | Proxmox VE (virtualization platform)|

---

### Secondary Server: Existing Hyperconverged Node

Currently running legacy VMs and Docker workloads. Acts as a backup node or experimental environment.

| Component            | Specification                  |
|----------------------|--------------------------------|
| CPU                  | AMD Ryzen 5 5600G              |
| GPU                  | Intel ARC A380                 |
| Storage               | 2 x 16TB Toshiba disks (RAID-like with 1 parity disk) |
| OS                   | Unraid 7.0.1                  |

---

### Kubernetes Edge Nodes

Lightweight nodes for Kubernetes High Availability (HA) testing and edge workloads.

| Device            | Specification         |
|-------------------|-----------------------|
| Raspberry Pi 4    | 8GB RAM, ARM-based SoC|

2 nodes currently configured to run k3s cluster pods, providing HA and cluster resiliency.

---

## Summary

This layered infrastructure combines enterprise-grade bare-metal hardware, virtualization, container orchestration, and GitOps practices. The stack is designed to facilitate rapid deployment, stateful infrastructure management, and iterative learning about cloud-native operations and automation tooling.
