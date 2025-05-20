resource "gitlab_user" "mike" {
  name             = "Miguel Silva"
  username         = "mike"
  email            = "miguelsilva5989@gmail.com"
  is_admin         = true
  reset_password   = true
}

resource "gitlab_user_sshkey" "mike" {
  user_id    = gitlab_user.mike.id
  title      = "garuda-9900x"
  key        = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLLV9ehqs+sUZlER6k/MWjkdF6vQQ/Kein3agLuqcU3 miguelsilva5989@gmail.com"
}

resource "gitlab_user" "renovate-bot" {
  name             = "Renovate Bot"
  username         = "renovate-bot"
  email            = "renovate-bot@milanchis.com"
}

