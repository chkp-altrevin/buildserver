# run our commands for demo and local clusters
# kubectl --context <CLUSTER_NAME>-<NODE_NAME> get nodes
# kubectl config get-contexts --kubeconfig /custom/path/kube.config
# 
kubectl --kubeconfig $HOME/.kube/kube.config --context k3d-demo-cluster-<NODE_NAME> get pods
