set :application, "hello"
set :user, 'vagrant'
set :ssh_options, { keys: ['.vagrant/machines/default/virtualbox/private_key'] }
set :deploy_to, '/home/vagrant/apps/hello'
set :use_sudo, false

set :scm, :git
set :repository,  "."
set :deploy_via, :copy

VAGRANT_SERVER="192.168.36.36"
role :web, VAGRANT_SERVER                          # Your HTTP server, Apache/etc
role :app, VAGRANT_SERVER                          # This may be the same as your `Web` server

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end