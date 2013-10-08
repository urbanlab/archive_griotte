#!/usr/bin/env ruby
#
#OMXPlayer ruby wrapper
#inputs and outputs are handled with EventMachine::Connection

require 'securerandom'
require 'eventmachine'
require 'faye'
require 'json'
require 'raspeomix/liveprocess'

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
    end

    def load(file)
      @iq = EM::Queue.new
      @oq = EM::Queue.new
      EM.add_periodic_timer(0.1) {
        @oq.pop {
          |omxmsg| send_omx_state(omxmsg)
        }
      }
      @file = file
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :ready })
    end

    def send_omx_state(msg)
      case msg.split[0]
      when "Video"
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :playing })
      when "have"
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :stopped })
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :idle })
      when "Current"
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_level, :level => msg.split[3] })
      end
    end

    def start(time) #time not used for now
      EM.popen("omxplayer -s #{@file}", EM::LiveProcess, @iq, @oq)
#      @fifo.start
      @playing = true
 #     @iq.push('q')
      return true
    end

    def play
      toggle_pause unless @playing
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :playing })
      return true
    end

    def pause
      toggle_pause unless !@playing
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :paused })
      return true
    end

    def toggle_pause
      @iq.push(PAUSECHAR)
      @playing = !@playing
    end

    def stop
      @iq.push(QUITCHAR)
      #sleep 1
      #@fifo.close
      #can be done better
      #Process::waitpid(@pipe.pid)
      return true
    end

    def set_level(lvl)
      if lvl==0
        lvl=1
      end
      lvl = Math.log10(lvl.to_f/100)*10 #percent to db
      real_lvl = (lvl/3).round*3 #OMXPlayer changes level per 3db (7db -> 6db or -20db -> -21db)
      while @level != real_lvl
        if @level > real_lvl
          @iq.push(LVLDWN)
          @level -= 3
        else
          @iq.push(LVLUP)
          @level += 3
        end
      end
      return true
    end

  end
end
