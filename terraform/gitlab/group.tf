resource "gitlab_group" "homelab" {
  name        = "homelab"
  path        = "homelab"
  description = "Homelab group"
}

resource "gitlab_group_label" "renovate" {
  group       = gitlab_group.homelab.id
  name        = "renovate"
  description = "used in dependency dashboard"
  color       = "#bf5e13"  
}
