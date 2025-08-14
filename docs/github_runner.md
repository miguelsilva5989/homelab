/etc/systemd/system/actions-runner.service


[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
User=root
WorkingDirectory=/root/actions-runner
Environment=RUNNER_ALLOW_RUNASROOT=1
ExecStart=/root/actions-runner/run.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target




systemctl enable actions-runner.service
reboot

systemctl status actions-runner.service

sudo journalctl -u actions-runner.service -f

