

// Role for dev_user_group to access resources in the dev namespace

resource "kubernetes_role" "dev_namespaced_role" {
  metadata {
    name = "dev-namespaced-role"
    // namespace = "dev" // specify the namespace for the role
  }
  dynamic "rule" {
    for_each = var.kubernetes_role_rules
    content {
      api_groups = rule.value.apiGroups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}


// Role binding for dev_namespaced_role to dev_user_group

resource "kubernetes_role_binding" "dev_namespaced_role_binding" {
  metadata {
    name = "dev-namespaced-role-binding"
    // namespace = "dev" // specify the namespace for the role binding
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.dev_namespaced_role.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "dev_user_group"
    api_group = "rbac.authorization.k8s.io"
  }
}