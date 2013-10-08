require 'rake'

namespace :server do
  desc "Starts the faye and web server"

  task :start do
    log = ENV['RASP_LOG']
    log = "/dev/null" if log.size == 0
    `bundle exe thin -e production -R server/config.ru -p #{ENV['RASP_PORT']} --log #{log} -d start`
  end

  task :stop do
    `bundle exec thin -e production -R server/config.ru -p #{ENV['RASP_PORT']} -d stop`
  end
end

