cd proxmox/ubuntu-server-noble

packaer init ubuntu-server-noble.pkr.hcl 

packer build --var-file=../credentials.pkr.hcl ubuntu-server-noble.pkr.hcl 
