#!/usr/bin/env ruby
#
#OMXPlayer ruby wrapper
#inputs and outputs are handled with EventMachine::Connection

require 'securerandom'
require 'eventmachine'
require 'faye'
require 'json'
require 'raspeomix/liveprocess'
require 'raspeomix/rpn_calculator'

module Raspeomix

  class OMXWrapper

    PAUSECHAR = 'p'
    QUITCHAR = 'q'
    LVLDWN = '-'
    LVLUP = '+'

    def initialize(type, host, port)
      @type = type
      @playing = false
      @level = 0
      #Faye client will warn videoclient when playback is over
      @client = Faye::Client.new("http://#{host}:#{port}/faye")
      @file = nil
      @hostname = `hostname`.chomp
      @iq = EM::Queue.new
      @oq = EM::Queue.new
    end

    def publish_omx_state(msg)
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => read_omx_state(msg)})
    end

    def read_omx_state(msg)
      hash = {}
      if (msg.split(',')[0][0]=='d') #checking this is actually an information line
        hash["type"] = "info"
        msg.split(',').each { |item|
          hash[item.split(':')[0]] = item.split(':')[1]
        }
      elsif (msg.split(',')[0]=="omx")
        hash["type"] = "raw_update"
        hash["update"] = msg.split(',')[1]
      end
      return hash
    end

    def get_info
      send_char('?')
    end

    def send_char(char)
      @iq.push(char)
    end

    def load(file)
      @iq = EM::Queue.new
      @oq = EM::Queue.new
      EM.add_periodic_timer(0.1) {
        @oq.pop {
          |omxmsg| publish_omx_state(omxmsg)
        }
      }
      EM.add_periodic_timer(1) {
        get_info
      }
      @file = file
    end

    def start(time,level) #time not used for now
      EM.popen("/home/pi/omxplayer --vol #{level} #{@file}", EM::LiveProcess, @iq, @oq)
      @playing = true
      return true
    end

    def play
      toggle_pause unless @playing
      return true
    end

    def pause
      toggle_pause unless !@playing
      return true
    end

    def stop
      @iq.push(QUITCHAR)
      return true
    end

    def vol_to_command(vol)
      case vol
      when "muted"
        return 'A'
      when 0..10
        return 'B'
      when 10..20
        return 'C'
      when 20..30
        return 'D'
      when 30..40
        return 'E'
      when 40..50
        return 'F'
      when 50..60
        return 'G'
      when 60..70
        return 'H'
      when 70..80
        return 'I'
      when 80..90
        return 'J'
      when 90..100
        return 'K'
      when 100..110
        return 'L'
      when 110..120
        return 'M'
      end
    end

    def set_level(lvl)
      @iq.push(vol_to_command(lvl))
      return true
    end

    def toggle_pause
      @iq.push(PAUSECHAR)
      @playing = !@playing
    end

  end
end
