require 'rake'

namespace :server do
  desc "Starts the faye/web server"

  # TODO: STDOUT ??
  if $log_dir == "/dev/null"
    log = $log_dir
  else 
    log = "#{$log_dir}/thin.log" 
  end

  task :start do
    `thin -e production -R server/config.ru -p #{$server_port} --log #{log} -d start`
  end

  task :stop do
    `thin -e production -R server/config.ru -p #{$server_port} -d stop`
  end
end

