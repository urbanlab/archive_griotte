require 'rake'

namespace :client do
  desc "Starts a Raspeomix client"
  task :start, :client do |t,args|
    `nohup ruby -I./lib clients/#{args[:client]}.rb > log/#{args[:client]}.log 2>&1 &`
  end
#  task :stop do
#    `bundle exec thin -e production -R server/config.ru -p #{ENV['RASP_PORT']} -d stop`
#  end
end
