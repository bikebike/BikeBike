rails_env = ENV['RAILS_ENV'] || 'production'

dir = 'rails'

if ENV['RAILS_ENV'] == 'preview'
  worker_processes 1
  directory = '/home/preview'
  port = 8081
else
  worker_processes 2
  directory = '/home/rails'
  port = 8080
end

working_directory directory

# Listen on unix socket
listen "127.0.0.1:#{port}", :backlog => 64

pid "/home/unicorn/#{ENV['RAILS_ENV']}.pid"

stderr_path "#{directory}/log/unicorn.log"
stdout_path "#{directory}/log/unicorn.log"
