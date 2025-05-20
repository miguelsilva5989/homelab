resource "gitlab_project" "homelab" {
  namespace_id = gitlab_group.homelab.id
  name         = "homelab"
  description  = "Homelab repo"

  visibility_level = "private"
}

resource "gitlab_group_membership" "homelab-renovate" {
  user_id      = gitlab_user.renovate-bot.id
  group_id     = gitlab_group.homelab.id
  access_level = "developer"
}

resource "gitlab_group_hook" "homelab-renovatehook" {
  group                   = gitlab_group.homelab.id
  url                     = var.RENOVATE_WEBHOOK_URL
  token                   = var.RENOVATE_WEBHOOK_SECRET
  push_events             = false
  issues_events           = true
  enable_ssl_verification = false
}
