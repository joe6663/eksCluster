
kubernetes_role_rules = [
  {
    apiGroups = [""]
    resources = ["pods", "configmaps"]
    verbs     = ["get", "list", "watch", "create", "update", "delete"]
  },
  {
    apiGroups = ["apps"]
    resources = ["deployments"]
    verbs     = ["get", "list", "watch", "create", "update", "delete"]
  }
]

aws_namespaced_user_name = ["joe", "alice", "bob"]