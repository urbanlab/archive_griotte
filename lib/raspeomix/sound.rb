require 'raspeomix/system'

module Raspeomix
  class Sound
    include FayeClient

    def initialize()
      register
    end


    def register
      publish('/system/register', { :text => "alive", :origin => self.class.to_s } )

      subscribe('/sound') do |message|
        puts message.inspect
        if message['state']
          `amixer set Master unmute`
        else
          `amixer set Master mute`
        end
      end
    end

    def start_heartbeat
      EM.add_periodic_timer(2) {
        puts "Sending heartbeat"
        publish('/heartbeats', { :text => "alive", :origin => self.class.to_s } )
      }
    end
  end
end
