# Kubernetes Intel GPU

https://jonathangazeley.com/2025/02/11/intel-gpu-acceleration-on-kubernetes/



kubectl label node matrix-01 intel.feature.node.kubernetes.io/gpu=true
kubectl label node matrix-01 gpu.intel.com/device-id.0300-56a5.present=true
kubectl label node matrix-01 gpu.intel.com/device-id.0300-56a5.count=1

