# dev-setup
This repository contains everything you need to setup a local web development environment.

## Install

1. Install VirtualBox: follow instructions on https://www.virtualbox.org/
2. Install Vagrant: follow instructions on https://www.vagrantup.com/
3. Install GIT.
4. Clone this repo: `git clone git@github.com:ocjojo/dev-setup.git [optional name]`
5. `vagrant up`, this takes a while the first time
6. add `config/nginx-config/local.dev.crt` to your trusted certificates

## Troubleshooting
Vagrant cannot mount shared folders.

- Install `vagrant plugin install vagrant-vbguest`
- run `vagrant vbguest`
- run `vagrant reload`

## Usage

Start your server via `vagrant up` in the respective directory.
On first start-up it will take some time to install and configure the server. Subsequent start-ups should be much faster.

Go to the [Dashboard](https://local.dev) for an overview of the tools and projects.

### Console access
Connect to the vagrant box via `vagrant ssh`.

To run a single command in the box you can use `vagrant ssh -c 'command'`.
e.g. `vagrant ssh -c 'cd /var/www/projectDir && composer install'`

### Projects

1. To use this setup you need to create/clone a project in the `www` directory.
2. import the database, if needed.

If you setup a new project, make sure you create an nginx configuration.
To reload the nginx configuration use the alias `nginx-restart` or the provided script `sudo bash /srv/config/reload-nginx.sh`.

### SSH Forwarding
Make sure you have added your ssh key as identity `ssh-add keyfile` on your host machine, if you want to communicate with external services from within the vagrant box.

## Dev URLs
URLs are read automatically from the `[alt_names]` section in `config/san_config`. If you need a new one, add it there.

The vagrant box is configured to route the projects on different development URLs. To make them available, you have to edit your hosts file or let vagrant update your hosts file using the [hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater) plugin.

Writing the hosts file usually requires admin rights, watch for a password promt or make the hosts file writable to your current user (this is recommended for windows).

## Updates
Just use `git pull` within the dev-setup directory and re-provision the vagrant box with `vagrant up --provision`

## Credits
This is a heavily modified version of [Varying Vagrant Vagrants](https://github.com/Varying-Vagrant-Vagrants/VVV)
