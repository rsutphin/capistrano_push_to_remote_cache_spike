# Push To Remote Cache strategy

This repo contains a trivial Rails app that demos a git-specific Capistrano
deployment strategy called `:push_to_remote_cache`. The implementation here is
for Capistrano 2.

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

Inspecting the output from Capistrano, you can see that it uses `git push` to
get the code onto the Vagrant VM. You can inspect the results:

* `$ vagrant ssh`
* `vagrant@precise64:~$ ls -al apps/hello`
* `vagrant@precise64:~$ ls -al apps/hello/current`

## How it works

* Creates a bare repo in the shared section of the deployment directories
* Starts a temporary git daemon on the server that only serves that repo
  - The daemon listens on a port on localhost only, so this is secure against
    even well-timed external attacks
* Sets up an SSH tunnel from the local machine to the server, piggybacking on
  Capistrano's SSH connection
* Pushes the code from the local machine over this SSH tunnel to the server
* Hands the code off to Capistrano's built-in `:remote_cache` strategy to handle
  cloning from the local repo, etc

The interesting files are

* `lib/capistrano/recipes/deploy/strategy/push_to_remote_cache.rb`
* `config/deploy.rb`

## Future work

This is just a spike, so there are some features missing.

* git submodules. It should be possible to use a similar strategy to push
  submodules — the reason for the separation between the `git submodule init`
  and `git submodule update` commands is to allow rewriting of the submodules'
  remote URLs. It should be possible to take advantage of this to handle
  submodules via pushes from the local machine as well.
* More robust handling of the temporary daemon.
  * While an attempt is made to kill the temporary daemon if the
    deployment is interrupted, it is possible that it could stick around. When
    that happens, the only solution is to SSH into the server and kill it
    manually.
  * The local and remote ports used for the daemon are hard-coded.
* There are no defaults for the variables the strategy depends on.
* Automated tests.
* Capistrano 3 support.
