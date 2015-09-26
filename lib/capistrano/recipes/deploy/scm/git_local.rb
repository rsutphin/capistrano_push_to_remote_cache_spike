require 'capistrano/recipes/deploy/scm/git'

module Capistrano::Deploy::SCM
  ##
  # An SCM that works in tandem with the :remote_cache_from_local strategy
  # to support git submodules being retrieved via the local SSH tunnel also.
  # Does not currently support recursive submodules.
  #
  # To enable this special git submodule support, the following properties must
  # be set:
  #
  # # Disable the base submodules support
  # set :git_enable_submodules, false
  # # Enable the special support here
  # set :git_local_enable_submodules, true
  # # Use this SCM
  # set :scm, :git_local
  #
  # … in addition to the configuration for :remote_cache_from_local.
  class GitLocal < Git
    default_command "git" # Not inherited

    def checkout(revision, destination)
      super_command = super

      if variable(:git_local_enable_submodules)
        [super_command, update_submodules(destination)].join(' && ')
      else
        super_command
      end
    end

    def sync(revision, destination)
      super_command = super

      if variable(:git_local_enable_submodules)
        [super_command, update_submodules(destination)].join(' && ')
      else
        super_command
      end
    end

    private

    def update_submodules(main_checkout)
      git = command
      repo_prefix = repository.sub(/\.git$/, '')
      execute = []

      submodules_root = File.expand_path('../cached-submodules', main_checkout)
      execute << "mkdir -p #{submodules_root}"
      execute << "cd #{main_checkout}"
      execute << "#{git} submodule #{verbose} init"
      # This mess does the following:
      # - Parses .gitmodules to extract a list of [path-property-name, path-value] pairs
      # - For each of these pairs,
      #   - Transforms the path property name to the URL property name
      #   - Uses git-config to set the local URL property of the submodule to the version available via the SSH tunnel
      # N.b.: `git submodule foreach` could do this slightly cleaner, but it doesn't work until after `update` for some reason.
      execute << %Q[#{git} config -f .gitmodules --get-regexp 'submodule.*path' | awk '{ gsub("path", "url", $1); system(sprintf("git config %s #{repo_prefix}%s/.git", $1, $2)) }']
      execute << "#{git} config --get-regexp submodule" if variable(:scm_verbose)
      execute << "#{git} submodule #{verbose} update"

      execute.join(' && ')
    end
  end
end
