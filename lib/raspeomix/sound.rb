require 'raspeomix/system'

module Raspeomix

  class VolumeOutOfBoundsError < ArgumentError; end

  class SoundHandler
    def initialize(target="Master")
      @target = target
    end

    def mute!
      system("amixer set #{target} unmute")
    end

    def unmute!
      system("amixer set #{target} unmute")
    end

    def muted?
      raise "Not implemented"
    end

    def volume
      raise "Not implemented"
    end

    def volume=(value)
      raise "Not implemented"
    end
  end

  class Sound
    include FayeClient

    def initialize( handler=SoundHandler.new("PCM") )
      @handler = handler
      register
    end


    def register
      publish('/system/register', { :text => "alive", :origin => self.class.to_s } )

      subscribe('/sound') do |message|
        puts message.inspect
        if message['state']
          unmute
        else
          mute
        end
      end
    end

    def mute!
      @handler.mute!
    end

    def muted?
      @handler.muted?
    end

    def unmute!
      @handler.unmute!
    end

    def volume=(value)
      (0..100) === value or raise VolumeOutOfBoundsError
      @handler.volume = value
    end

    def volume
      @handler.volume
    end

    def start_heartbeat
      EM.add_periodic_timer(2) {
        puts "Sending heartbeat"
        publish('/heartbeats', { :text => "alive", :origin => self.class.to_s } )
      }
    end
  end
end
