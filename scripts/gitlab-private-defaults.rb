# Run once inside the new GitLab instance, before creating users or projects:
# kubectl -n gitlab exec -i deploy/zion-gitlab -- gitlab-rails runner - < scripts/gitlab-private-defaults.rb
# Link the recovery administrator to the approved OIDC identity before running this.
# This changes application settings only; it does not create users or print secrets.
root = User.find_by(username: 'root')
raise 'Link the recovery administrator to the approved OIDC identity first' unless root&.identities&.exists?(provider: 'openid_connect')

Gitlab::CurrentSettings.update!(
  signup_enabled: false,
  default_project_visibility: Gitlab::VisibilityLevel::PRIVATE,
  default_group_visibility: Gitlab::VisibilityLevel::PRIVATE,
  default_snippet_visibility: Gitlab::VisibilityLevel::PRIVATE,
  restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC],
  enabled_git_access_protocol: 'http',
  password_authentication_enabled_for_git: false,
  password_authentication_enabled_for_web: false,
  shared_runners_enabled: false,
  vscode_extension_marketplace_single_origin_fallback_enabled: false
)
File.write('/var/opt/gitlab/gitlab-rails/.homelab-private-defaults-ready', "ready\n", perm: 0o600)
puts 'Private defaults applied; browser login requires the configured OIDC provider.'
