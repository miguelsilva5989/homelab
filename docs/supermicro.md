# Supermicro Motherboard

## Network

Do not set any fixed IP address in the router 😀
Keep router VLAN in DHCP mode and configure the IPs statically inside every machine.

## Fans

The case fans (Arctict) have a 0db low RPM mode so we need to lower their threshold in order for them no not be ramping up and down all the time.

```sh
[🔴] × ipmitool -I lanplus -H 10.69.0.69 -U ADMIN -P <PW> sensor thresh "FAN1" lower 100 200 300
Locating sensor record 'FAN1'...
Setting sensor "FAN1" Lower Non-Recoverable threshold to 100,000
Error setting threshold: Command illegal for specified sensor or record type
Setting sensor "FAN1" Lower Critical threshold to 200,000
Setting sensor "FAN1" Lower Non-Critical threshold to 300,000
Error setting threshold: Command illegal for specified sensor or record type

 ╭─mike@garudamus in ~ as 🧙 took 0s
[🔴] × ipmitool -I lanplus -H 10.69.0.69 -U ADMIN -P <PW> sensor thresh "FANA" lower 100 200 300
Locating sensor record 'FANA'...
Setting sensor "FANA" Lower Non-Recoverable threshold to 100,000
Error setting threshold: Command illegal for specified sensor or record type
Setting sensor "FANA" Lower Critical threshold to 200,000
Setting sensor "FANA" Lower Non-Critical threshold to 300,000
Error setting threshold: Command illegal for specified sensor or record type
```
