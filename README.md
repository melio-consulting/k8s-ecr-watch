## Usage

1. Create namespace (e.g. cd)

## Create a service account

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: get-pods-k8s-ecr-watch
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: ["extensions", "apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: get-pods
  namespace: cd
subjects:
- kind: ServiceAccount
  name: eks-ecr-readonly
  namespace: cd
roleRef:
  kind: ClusterRole
  name: get-pods-k8s-ecr-watch
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-ecr-readonly
  namespace: cd
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::12345678:role/eks-ecr-readonly"
```
