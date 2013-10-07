require 'rake'

namespace :server do
  desc "Starts the faye and web server"
  task :start do
    `bundle exec thin -e production -R server/config.ru -d start`
  end
  task :stop do
    `bundle exec thin -e production -R server/config.ru -d stop`
  end
end
