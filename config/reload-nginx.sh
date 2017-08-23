#!/bin/bash
#call via 'sudo bash /srv/config/reload-nginx.sh'

#sync nginx configs
rsync -rvzh --delete "/srv/config/nginx-config/sites/" "/etc/nginx/sites-enabled/"
# restart nginx
systemctl restart nginx