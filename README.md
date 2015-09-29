# Remote Cache From Local strategy

This repo contains a trivial Rails app that demos a git-specific Capistrano
deployment strategy called `:remote_cache_from_local`. The implementation here
is for Capistrano 2.

The strategy is available as a gem called [`capistrano2-remote_cache_from_local`](https://github.com/cdd/capistrano2-remote_cache_from_local).

The purpose is to ensure that an application is always deployable, even if the
service hosting the application's git repo is not available.

Capistrano's `:copy` strategy can do this, at the cost of re-copying the entire
codebase from the local machine to the server on every deploy. This strategy
takes advantage of git to only transfer what has changed.

## See it in action

Prereqs for the demo: [Vagrant](https://www.vagrantup.com/), VirtualBox, Ruby, Bundler.

The Vagrant VM is configured so that, once it has been provisioned, it cannot
make network connections out, other than for DNS, communications with Vagrant
itself, and connecting to localhost.

### Set up the app and deployment environment

* Clone this repo & `cd` into its directory
* `$ vagrant up`
* `$ bundle install`
* `$ bin/cap deploy:setup`

### Deploy

* `$ bin/cap deploy`

Inspecting the output from Capistrano, you can see that it clones from the SSH
tunnel (git://127.0.0.1:50123/.git) to get the code onto the Vagrant VM. You can
inspect the results:

* `$ vagrant ssh`
* `vagrant@precise64:~$ ls -al apps/hello/shared/cached-copy` (the cloned repo)
* `vagrant@precise64:~$ ls -al apps/hello/current` (the deployed application)
* `vagrant@precise64:~$ ls -al apps/hello/current/vendor/globalid` (a submodule)

## How it works

* Starts a temporary git daemon on the deploying machine that only serves the
  local repo from which capistrano is running.
  - The daemon listens on a port on localhost only, so this is secure against
    even well-timed external attacks
* Sets up an SSH tunnel from the server to the deploying machine, piggybacking
  on Capistrano's SSH connection
* Hands the deploying off to Capistrano's built-in `:remote_cache` strategy to
  clone or fetch across the ssh tunnel.
* Reconfigures any git submodules so that they also fetch across the tunnel.
