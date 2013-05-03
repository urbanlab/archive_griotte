require 'raspeomix/system'

module Raspeomix

  class VolumeOutOfBoundsError < ArgumentError; end

  class SoundHandler
    def initialize(channel=nil)
    end

    def mute!
      raise "Not implemented"
    end

    def unmute!
      raise "Not implemented"
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

  class SoundHandlerAlsa < SoundHandler
    def initialize(channel=nil)
      @status = Hash.new
      @status['channel'] = channel
      detect_channel unless channel
      parse_amixer("amixer get #{@status['channel']}")
    end

    def mute!
      parse_amixer("amixer set #{@status['channel']} mute")
    end

    def unmute!
      parse_amixer("amixer set #{@status['channel']} unmute")
    end

    def muted?
      @status['muted']
    end

    def volume
      @status['volume']
    end

    def volume=(value)
      value >= 0 or raise VolumeOutOfBoundsError
      value <= 100 or raise VolumeOutOfBoundsError

      parse_amixer("amixer set Master #{value}%")
    end

    private

    def detect_channel
      output = %x(amixer scontrols)
      controls = Array.new
      re = %r{Simple mixer control '(.*)'}
      output.each_line do |l|
        controls << re.match(l)[1].to_sym
      end

      # Preferred channels from least to most wanted
      [ :PCM, :Master ].each do |c|
        @status['channel'] = c if controls.include?(c)
      end
    end

    def parse_amixer(command)
      output = %x(#{command})

      mixer = Hash.new

      output.each_line do |l|
        k,v = l.chomp.split(/:/).map(&:lstrip)
        # v will be mepty for the first line since it doesn't contain ':'
        mixer[k] = v if v
      end

      # Parses sound status (volume, mute)
      line = mixer[mixer['Playback channels']]

      matches = %r{\[([^\[]*)\] \[([^\[]*)\] \[([^\[]*)\]}.match(line)
      mixer['muted'] = case matches[3]
                       when 'off'; true
                       when 'on';  false
                       else nil
                       end

      mixer['db']     = matches[2].gsub('dB','').to_i
      mixer['volume'] = matches[1].gsub('%','').to_i

      @status.merge!(mixer)
    end


  end

  class Sound
    include FayeClient

    def initialize(handler = SoundHandler.new)
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
