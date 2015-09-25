# Remote Cache From Local strategy

This repo contains a trivial Rails app that demos a git-specific Capistrano
deployment strategy called `:remote_cache_from_local`. The implementation here
is for Capistrano 2.

The purpose is to ensure that an application is always deployable, even if the
service hosting the application's git repo is not available.

Capistrano's `:copy` strategy can do this, at the cost of re-copying the entire
codebase from the local machine to the server on every deploy. This strategy
takes advantage of git to only transfer what has changed.

## See it in action

Prereqs for the demo: [Vagrant](https://www.vagrantup.com/), VirtualBox, Ruby, Bundler.

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
* `vagrant@precise64:~$ ls -al apps/hello`
* `vagrant@precise64:~$ ls -al apps/hello/current`

## How it works

* Starts a temporary git daemon on the deploying machine that only serves the
  local repo from which capistrano is running.
  - The daemon listens on a port on localhost only, so this is secure against
    even well-timed external attacks
* Sets up an SSH tunnel from the server to the deploying machine, piggybacking
  on Capistrano's SSH connection
* Hands the deploying off to Capistrano's built-in `:remote_cache` strategy to
  clone or fetch across the ssh tunnel.

The interesting files are

* `lib/capistrano/recipes/deploy/strategy/remote_cache_from_local.rb`
* `config/deploy.rb`

## Future work

This is just a spike, so there are some features missing.

* git submodules. It should be possible to use a similar strategy to pull
  submodules — the reason for the separation between the `git submodule init`
  and `git submodule update` commands is to allow rewriting of the submodules'
  remote URLs. It should be possible to take advantage of this to handle
  submodules also.
* More robust handling of the temporary daemon.
  * While an attempt is made to kill the temporary daemon if the
    deployment is interrupted, it is possible that it could stick around. When
    that happens, you have to kill it manually.
  * The local and remote ports used for the daemon are hard-coded.
* There are no defaults for the variables the strategy depends on. The
  `:repository` in particular must have a specific value in order for the
  strategy to work at all.
* Automated tests.
* Capistrano 3 support.
