/etc/systemd/system/actions-runner.service


[Unit]
Description=GitHub Actions Runner 1
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



## More runners

mkdir actions-runner-2 && cd actions-runner-2

vim /etc/systemd/system/actions-runner-2.service


[Unit]
Description=GitHub Actions Runner 2
After=network.target

[Service]
User=root
WorkingDirectory=/root/actions-runner-2
Environment=RUNNER_ALLOW_RUNASROOT=1
ExecStart=/root/actions-runner-2/run.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target


systemctl enable actions-runner-2.service
systemctl start actions-runner-2.service
systemctl status actions-runner-2.service
sudo journalctl -u actions-runner-2.service -f



## Runner 3

mkdir actions-runner-3 && cd actions-runner-3

vim /etc/systemd/system/actions-runner-3.service


[Unit]
Description=GitHub Actions Runner 3
After=network.target

[Service]
User=root
WorkingDirectory=/root/actions-runner-3
Environment=RUNNER_ALLOW_RUNASROOT=1
ExecStart=/root/actions-runner-3/run.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target


systemctl enable actions-runner-3.service
systemctl start actions-runner-3.service
systemctl status actions-runner-3.service
sudo journalctl -u actions-runner-3.service -f
