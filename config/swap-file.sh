#!/bin/bash
#call via 'sudo bash /srv/config/swap-file.sh'

/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1