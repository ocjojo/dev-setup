#!/bin/bash
#
# provision.sh
#
# This file is specified in Vagrantfile and is loaded by Vagrant as the primary
# provisioning script whenever the commands `vagrant up`, `vagrant provision`,
# or `vagrant reload` are used.

# By storing the date now, we can calculate the duration of provisioning at the
# end of this script.
start_seconds="$(date +%s)"

# PACKAGE INSTALLATION
#
# Build a bash array to pass all of the packages we want to install to a single
# yum command. This avoids doing all the leg work each time a package is
# set to install. It also allows us to easily comment out or add single
# packages. We set the array as empty to begin with so that we can append
# individual packages to it as required.
yum_package_install_list=()

# Start with a bash array containing all packages we want to install in the
# virtual machine. We'll then loop through each of these and check individual
# status before adding them to the yum_package_install_list array.
yum_package_check_list=(

  # PHP7.1
  #
  # Our base packages for php7.1. As long as php7.1-fpm and php7.1-cli are
  # installed, there is no need to install the general php7.1 package, which
  # can sometimes install apache as a requirement.
  php71w-fpm
  php71w-cli

  # Common, see https://webtatic.com/packages/php71/
  # contains php-api, php-bz2, php-calendar, php-ctype, 
  # php-curl, php-date, php-exif, php-fileinfo, php-filter,
  # php-ftp, php-gettext, php-gmp, php-hash, php-iconv, php-json,
  # php-libxml, php-openssl, php-pcre, php-pecl-Fileinfo, php-pecl-phar,
  # php-pecl-zip, php-reflection, php-session, php-shmop, php-simplexml,
  # php-sockets, php-spl, php-tokenizer, php-zend-abi, php-zip, php-zlib
  php71w-common
  # dev
  php71w-devel

  # Extra PHP modules that we find useful
  php71w-bcmath
  php71w-gd
  php71w-mbstring
  php71w-mcrypt
  php71w-mysql
  php71w-imap
  php71w-soap
  php71w-xml

  # nginx is installed as the default web server
  nginx

  # mariadb (drop-in replacement on mysql) is the default database
  mariadb-server

  # other packages that come in handy
  git
  curl
  make
  vim
  nano

  # ntp service to keep clock current
  ntp

  # Req'd for i18n tools
  gettext

  # nodejs
  # temporarily install http-parser directly, b/c of https://bugzilla.redhat.com/show_bug.cgi?id=1481470
  https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm

  # to build e.g. node modules
  gcc-c++
  #to build newest guest additions
  kernel-devel
)

### FUNCTIONS

network_detection() {
  # Network Detection
  #
  # Make an HTTP request to google.com to determine if outside access is available
  # to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
  # skip a few things further in provisioning rather than create a bunch of errors.
  if [[ "$(wget --tries=3 --timeout=5 --spider --recursive --level=2 http://google.com 2>&1 | grep 'connected')" ]]; then
    echo "Network connection detected..."
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach google.com..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}

repo_install() {
  yum -y install epel-release
  # Add webtatic repo for php71
  echo "Adding webtatic repo"
  rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
}

noroot() {
  sudo -EH -u "vagrant" "$@";
}

profile_setup() {
  # Copy custom dotfiles and bin file for the vagrant user from local
  cp "/srv/config/bash_profile" "/home/vagrant/.bash_profile"

  echo " * Copied /srv/config/bash_profile                      to /home/vagrant/.bash_profile"
}

not_installed() {
  rpm -q "$1" 2>&1 | grep -q 'not installed'
  # returns 0 if string 'not installed' is found, truthy value otherwise
  return "$?"
}

package_check() {
  # Loop through each of our packages that should be installed on the system. If
  # not yet installed, it should be added to the array of packages to install.
  local pkg

  for pkg in "${yum_package_check_list[@]}"; do
    if not_installed "${pkg}"; then
      echo " *" "$pkg" [not installed]
      yum_package_install_list+=($pkg)
    else
      rpm -q "${pkg}"
    fi
  done
}

package_install() {
  package_check

  if [[ ${#yum_package_install_list[@]} = 0 ]]; then
    echo -e "No yum packages to install.\n"
  else
    # Update all of the package references before installing anything
    echo "Running yum update..."
    yum -y update

    # Install required packages
    echo "Installing yum packages..."
    yum -y install ${yum_package_install_list[@]}

    # Remove unnecessary packages
    echo "Removing unnecessary packages..."
    yum autoremove -y
  fi
}

tools_install() {
  # NODEJS
  if not_installed "nodejs"; then
    curl -sL https://rpm.nodesource.com/setup_8.x | bash -
    yum install -y nodejs
  fi
  # install gulp
  /usr/bin/npm install -g gulp-cli
  # install json-server for expa mock server
  # /usr/bin/npm install -g json-server

  # create bin dir if it does not exist yet
  mkdir -p /usr/local/bin

  # COMPOSER
  #
  # Install Composer if it is not yet available.
  if [[ ! -n "$(/usr/local/bin/composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Installing Composer..."
    curl -sS "https://getcomposer.org/installer" | php -- --install-dir=/usr/local/bin --filename=composer
  fi

  if [[ -f /vagrant/provision/github.token ]]; then
    ghtoken=`cat /vagrant/provision/github.token`
    /usr/local/bin/composer config --global github-oauth.github.com $ghtoken
    echo "Your personal GitHub token is set for Composer."
  fi

  # Update both Composer and any global packages. Updates to Composer are direct from
  # the master branch on its GitHub repository.
  if [[ -n "$(/usr/local/bin/composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Updating Composer..."
    COMPOSER_HOME=/usr/local/src/composer /usr/local/bin/composer self-update
    COMPOSER_HOME=/usr/local/src/composer /usr/local/bin/composer -q global require phpunit/phpunit
    COMPOSER_HOME=/usr/local/src/composer /usr/local/bin/composer -q global config bin-dir /usr/local/bin
    COMPOSER_HOME=/usr/local/src/composer /usr/local/bin/composer global update
  fi

  # SYMFONY
  # 
  # Install symfony install tool, if not yet available
  if [[ ! -f /usr/local/bin/symfony ]]; then
    curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony
    chmod a+x /usr/local/bin/symfony
  fi
}

adminer_setup() {
  if [[ ! -d "/var/www/default/database-admin" ]]; then
    mkdir "/var/www/default/database-admin"
  fi
  if [[ ! -e /var/www/default/database-admin/index.php ]]; then
    wget https://github.com/vrana/adminer/releases/download/v4.3.1/adminer-4.3.1.php -O /var/www/default/database-admin/index.php
  fi 
}

nginx_setup() {
  if [[ ! -d "/etc/nginx/ssl" ]]; then
    mkdir -p "/etc/nginx/ssl/"
  fi

  # Create an SSL key and certificate for HTTPS support.
  if [[ ! -e /etc/nginx/ssl/server.key ]]; then
    echo "Generate Nginx server private key..."
    vvvgenrsa="$(openssl genrsa -out /etc/nginx/ssl/server.key 2048 2>&1)"
    echo "$vvvgenrsa"
  fi

  if [[ ! -e /etc/nginx/ssl/server.crt ]]; then
    echo "Sign the certificate using the above root ca..."
    vvvsigncert="$(openssl req -new -x509 \
    -key /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt \
    -days 730 \
    -config /srv/config/san_config 2>&1)"
    echo "$vvvsigncert"
  fi

  # change nginx user uid and gid, so vagrant permissions fit
  usermod -u 5000 nginx

  # make rootCA available in host os
  cp "/etc/nginx/ssl/server.crt" "/srv/config/nginx-config/local.dev.crt"

  echo -e "\nSetup configuration files..."

  # Copy nginx configuration from local
  cp "/srv/config/nginx-config/nginx.conf" "/etc/nginx/nginx.conf"
  cp "/srv/config/nginx-config/ssl.conf" "/etc/nginx/ssl.conf"

  if [[ ! -d "/etc/nginx/sites-enabled" ]]; then
    mkdir "/etc/nginx/sites-enabled/"
  fi
  rsync -rvzh --delete "/srv/config/nginx-config/sites/" "/etc/nginx/sites-enabled/"

  echo " * Copied /srv/config/nginx-config/nginx.conf           to /etc/nginx/nginx.conf"
  echo " * Rsync'd /srv/config/nginx-config/sites/              to /etc/nginx/sites-enabled"
}

etc_setup() {
  # Copy configuration from local
  rsync -rvzh "/srv/config/etc-config/" "/etc/"

  echo " * Copied /srv/etc-config/* to /etc/*"

  # create session dir
  if [[ ! -d "/var/lib/php/session" ]]; then
    mkdir "/var/lib/php/session"
    chown -R nginx:nginx "/var/lib/php/session"
  fi
}

mysql_setup() {
  # If MariaDB/MySQL is installed, go through the various imports and service tasks.
  local exists_mysql

  exists_mysql="$(systemctl status mariadb)"
  if [[ "mysql: unrecognized service" != "${exists_mysql}" ]]; then

    systemctl restart mariadb

    # MariaDB/MySQL
    # secure sql
    mysql --user=root <<_EOF_
      UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';
      DELETE FROM mysql.user WHERE User='';
      DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
      DROP DATABASE IF EXISTS test;
      DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
      FLUSH PRIVILEGES;
_EOF_

  else
    echo -e "\nMySQL is not installed. No databases imported."
  fi
}

services_enable() {
  # ENABLE SERVICES
  systemctl enable nginx
  systemctl enable php-fpm
  systemctl enable mariadb
}

###############
# Setup Order #
###############

network_check
# Profile_setup
echo "Bash profile setup and directories."
profile_setup

network_check
# Package and Tools Install
echo " "
echo "Main packages check and install."
repo_install
package_install
tools_install
adminer_setup
nginx_setup
etc_setup
mysql_setup
services_enable

network_check
echo " "

#set +xv
# And it's done
end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$(( end_seconds - start_seconds ))" seconds"
