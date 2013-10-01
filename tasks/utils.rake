require 'rake'


namespace :utils do
  desc "Clears screen"
  task :clearfb do
    `setterm -cursor off`
    `dd if=/dev/zero of=/dev/fb0 > /dev/null 2>&1`
  end
end
