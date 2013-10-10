require 'rake'

namespace :config do
  desc "Shows current config"

  task :show do
    puts "Clients to start    : #{$clients}"
    puts "Logs are written in : #{$log_dir}"
    puts "Server port is      : #{$server_port}"
  end

end

