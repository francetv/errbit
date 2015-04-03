# Deploy Config
# =============
#
# Copy this file to config/deploy.rb and customize it as needed.
# Then run `cap errbit:setup` to set up your server and finally
# `cap deploy` whenever you would like to deploy Errbit. Refer
# to the Readme for more information.

config = YAML.load_file('config/config.yml')['deployment'] || {}

require 'bundler/capistrano'
load 'deploy/assets'

set :application, "errbit"
set :repository,  config['repository']

role :web, config['hosts']['web']
role :app, config['hosts']['app']
role :db,  config['hosts']['db'], :primary => true

set :user, config['user']
set :use_sudo, false
if config.has_key?('ssh_key')
  set :ssh_options,      { :forward_agent => true, :keys => [ config['ssh_key'] ] }
else
  set :ssh_options,      { :forward_agent => true }
end
default_run_options[:pty] = true

set :deploy_to, config['deploy_to']
set :deploy_via, :remote_cache
set :copy_cache, true
set :copy_exclude, [".git"]
set :copy_compression, :bz2

set :scm, :git
set :scm_verbose, true
set :branch, config['branch'] || 'master'

before 'deploy:assets:symlink', 'errbit:symlink_configs'
# if unicorn is started through something like runit (the tool which restarts the process when it's stopped)
# after 'deploy:restart', 'unicorn:stop'
after 'deploy:restart'

namespace :deploy do
  desc 'Start unicorn'
  task :start, :roles => :app, :except => { :no_release => true } do
    unicorn_conf = "#{current_path}/config/unicorn.rb"
    run "cd #{current_path} && bundle exec unicorn_rails -c #{unicorn_conf} -E production -D"
  end

  desc 'Stop unicorn'
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "kill -QUIT #{unicorn_pid}"
  end

  desc 'Restart unicorn'
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "kill -USR2 #{unicorn_pid}"
  end
end
>>>>>>> williamhenry/master

namespace :errbit do
  desc "Setup config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/pids"
      execute "touch #{shared_path}/.env"

      {
        'config/newrelic.example.yml' => 'config/newrelic.yml',
        'config/unicorn.default.rb' => 'config/unicorn.rb',
      }.each do |src, target|
        unless test("[ -f #{shared_path}/#{target} ]")
          upload! src, "#{shared_path}/#{target}"
        end
      end
    end
  end
end

namespace :db do
  desc "Create and setup the mongo db"
  task :setup do
    on roles(:db) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'errbit:bootstrap'
        end
      end
    end
  end
end

set :unicorn_pidfile, "#{fetch(:deploy_to)}/shared/tmp/pids/unicorn.pid"
set :unicorn_pid, "`cat #{fetch(:unicorn_pidfile)}`"

namespace :unicorn do
  desc 'Start unicorn'
  task :start do
    on roles(:app) do
      within current_path do
        if test " [ -s #{fetch(:unicorn_pidfile)} ] "
          warn "Unicorn is already running."
        else
          with "UNICORN_PID" => fetch(:unicorn_pidfile) do
            execute :bundle, :exec, :unicorn, "-D -c ./config/unicorn.rb"
          end
        end
      end
    end
  end

  desc 'Reload unicorn'
  task :reload do
    on roles(:app) do
      execute :kill, "-HUP", fetch(:unicorn_pid)
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app) do
      if test " [ -s #{fetch(:unicorn_pidfile)} ] "
        execute :kill, "-QUIT", fetch(:unicorn_pid)
      else
        warn "Unicorn is not running."
      end
    end
  end

  desc 'Reexecute unicorn'
  task :reexec do
    on roles(:app) do
      execute :kill, "-USR2", fetch(:unicorn_pid)
    end
  end
end
