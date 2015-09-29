require 'capistrano/recipes/deploy/strategy/remote_cache'

module Capistrano::Deploy::Strategy
  ##
  # A deployment strategy which has the app server pull the code from the
  # deploying machine via an SSH tunnel. The strategy behaves like :remote_cache
  # otherwise.
  #
  # You must have the following variables set to use this strategy:
  #
  # set :scm, :git
  # set :deploy_via, :remote_cache_from_local
  #
  # # The root of your local checkout, relative to the Capfile
  # set :local_repository, '.'
  #
  # # This exact value (which is where the SSH tunnel will end up on the server)
  # set :repository,  'git://127.0.0.1:50123/.git'
  class RemoteCacheFromLocal < RemoteCache
    private

    def update_repository_cache
      with_tunneled_local_daemon { super }
    end

    def with_tunneled_local_daemon
      execute_on_servers do |servers|
        servers.each do |s|
          begin
            # Run a git daemon locally (listening on localhost only)
            daemon_port = 50123
            pid_file = "tmp/git-daemon.pid"
            execute "Run local git daemon" do
              system "git daemon --verbose --listen=127.0.0.1 --port=#{daemon_port} --reuseaddr --export-all --base-path=#{local_repository} --detach --pid-file=#{pid_file}"
            end

            # Forward remote connections to local git daemon via capistrano's SSH session
            remote_port = daemon_port
            session = sessions[s]
            session.forward.remote(daemon_port, '127.0.0.1', remote_port)
            keep_looping = true
            Thread.new { session.loop { sleep(0.1); keep_looping } }

            yield
          ensure
            keep_looping = false
            if pid_file
              execute "Kill local git daemon if running" do
                system "if [ -e #{pid_file} ]; then kill `cat #{pid_file}`; fi"
              end
            end
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
