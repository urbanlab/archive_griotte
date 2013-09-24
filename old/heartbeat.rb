require 'raspeomix/system'

module Raspeomix
  class Heartbeat
    include FayeClient

    def initialize()
      register
      start_heartbeat
    end


    def register
      publish('/system/register', { :text => "alive", :origin => self.class.to_s } )
    end

    def start_heartbeat
      EM.add_periodic_timer(2) {
        puts "Sending heartbeat"
        publish('/heartbeats', { :text => "alive", :origin => self.class.to_s } )
      }
    end
  end
end
