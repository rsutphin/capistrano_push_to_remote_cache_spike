require 'capistrano/recipes/deploy/strategy/remote_cache'

module Capistrano::Deploy::Strategy
  ##
  # Provides a strategy which pushes the application repo from the local checkout
  # to the server. The server then uses the pushed repo in the same way that
  # the `remote_cache` strategy uses the remote repo.
  #
  # You must have the following variables set to use this strategy:
  #
  # set :scm, :git
  # set :deploy_via, :push_to_remote_cache
  #
  # # The root of your local checkout, relative to the Capfile
  # set :local_repository, '.'
  #
  # # The path on the server to which the local repo will be pushed
  # set :repository,  File.join(shared_path, 'push-repo')
  #
  # # The branch that will be pushed and deployed.
  # set :branch, :master
  class PushToRemoteCache < RemoteCache
    private

    def update_repository_cache
      init_remote_repo_if_necessary
      push_from_local_to_server
      super
    end

    def init_remote_repo_if_necessary
      command = "if [ ! -d #{repository} ]; then " +
        "#{source.command} init --bare #{repository}; " +
        "fi"
      scm_run(command)
    end

    def push_from_local_to_server
      execute_on_servers do |servers|
        servers.each do |s|
          begin
            # Run a git daemon on the remote server (listening on the server's localhost only)
            daemon_port = 50123
            pid_file = "#{shared_path}/git-daemon.pid"
            run "git daemon --verbose --listen=127.0.0.1 --port=#{daemon_port} --reuseaddr --enable=receive-pack --export-all --strict-paths --detach --pid-file=#{pid_file} #{repository}"

            # Forward local connections to remote git daemon via capistrano's SSH session
            local_port = daemon_port
            session = sessions[s]
            session.forward.local(local_port, '127.0.0.1', daemon_port)
            keep_looping = true
            Thread.new { session.loop { sleep(0.1); keep_looping } }

            execute "push local repository to remote temporary git daemon" do
              system("#{source.command} push git://127.0.0.1:#{local_port}#{repository} #{branch}")
            end
          ensure
            keep_looping = false
            run "if [ -e #{pid_file} ]; then kill `cat #{pid_file}`; fi" if pid_file
          end
        end
      end
    end

    # Local execution methods copied from the copy strategy

    def execute(description, &block)
      logger.debug description
      handle_system_errors(&block)
    end

    def handle_system_errors(&block)
      block.call
      raise_command_failed if last_command_failed?
    end

    def raise_command_failed
      raise Capistrano::Error, "shell command failed with return code #{$?}"
    end

    def last_command_failed?
      $? != 0
    end
  end
end
