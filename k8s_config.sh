#!/bin/bash
######################
#  Set the variables #
######################
read -p "Enter your namespace: " ns
export namespace=$ns
read -p "Enter your service-account: " sa
export serviceAccount=$sa
read -p "Enter your secretName: " sn
export secretName=$sn

printf 'Create ServiceAccount, Role and RoleBinding (y/n)? '
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${serviceAccount}
  namespace: ${namespace}
EOF

    kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${namespace}
  name: ${serviceAccount}
rules:
- apiGroups: ["*"] 
  resources: ["*"]
  verbs: ["*"]
EOF

    kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${serviceAccount}
  namespace: ${namespace}
subjects:
- kind: ServiceAccount
  name: ${serviceAccount}
  namespace: ${namespace}
roleRef:
  kind: Role
  name: ${serviceAccount}
  apiGroup: rbac.authorization.k8s.io
EOF

    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${serviceAccount}
  namespace: ${namespace}
  annotations:
    kubernetes.io/service-account.name: ${serviceAccount}
type: kubernetes.io/service-account-token
EOF

else
  echo "No"
fi

######################
#       Script       #
######################
clusterName="cluster.local"
server="https://10.0.0.1:6443"
ca=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.ca\.crt}')
token=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.token}' | base64 --decode)

echo "
---
apiVersion: v1
kind: Config
clusters:
  - name: ${server}
    cluster:
      certificate-authority-data: ${ca}
      server: ${server}
contexts:
  - name: ${serviceAccount}@${clusterName}
    context:
      cluster: ${server}
      namespace: ${namespace}
      user: ${serviceAccount}
current-context:  ${serviceAccount}@${clusterName}
users:
  - name: ${serviceAccount}
    user:
      token: ${token}
" > ${serviceAccount}.kubeconfig
