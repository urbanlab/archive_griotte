#!/usr/bin/env ruby
#
#OMXPlayer ruby wrapper
#sends inputs with named pipe
#receives outputs with popen3

require 'securerandom'
require 'eventmachine'
require 'faye'
require 'liveprocess'

module Raspeomix

  #class sending input to OMXPlayer
  class Fifo

    attr_reader :path

    def initialize(path = "/tmp/fifo_#{SecureRandom.uuid}")
      @path = path
      %x{mkfifo #{@path}}
    end

    def start
      send('.')
    end

    def send(char)
      open(@path, "w+") { |f| f.write(char) }
    end

    def close
      %x{rm #{@path}}
    end

  end

  class OMXWrapper

    PAUSECHAR = 'p'
    QUITCHAR = 'q'
    LVLDWN = '-'
    LVLUP = '+'

    def initialize(type, host, port)
      @type = type
      @playing = false
      @fifo = Fifo.new
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
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :ready }.to_json)
    end

    def send_omx_state(msg)
      case msg.split[0]
      when "Video"
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :playing }.to_json)
      when "have"
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :stopped }.to_json)
        @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :idle }.to_json)
      end
    end

    def start(time) #time not used for now
      #EM.popen("omxplayer -s --pos 110 #{@file} < #{@fifo.path}", EM::LiveProcess, @q)
      EM.popen("omxplayer -s --pos 110 #{@file}", EM::LiveProcess, @iq, @oq)
#      @fifo.start
      @playing = true
 #     @iq.push('q')
      return true
    end

    def play
      toggle_pause unless @playing
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :playing }.to_json)
      return true
    end

    def pause
      toggle_pause unless !@playing
      @client.publish("/#{@hostname}/#{@type}/handler", { :type => :omx_state, :state => :paused }.to_json)
      return true
    end

    def toggle_pause
      puts "toggling pause, @playing : #{@playing}"
      @iq.push(PAUSECHAR)
      @playing = !@playing
      puts "toggled pause, @playing : #{@playing}"
    end

    def stop
      @iq.push(QUITCHAR)
      sleep 1
      @fifo.close
      #can be done better
      #Process::waitpid(@pipe.pid)
      return true
    end

    def set_level(lvl)
      lvl = Math.log10(lvl.to_f/100)*10 #percent to db
      real_lvl = (lvl/3).round*3 #OMXPlayer changes level per 3db (7db -> 6db or -20db -> -21db)
      while @level != real_lvl
        if @level > real_lvl
          @iq.push(LVLDWN)
          sleep 0.05 #quickfix to avoid fifo spamming
          @level -= 3
        else
          @iq.push(LVLUP)
          sleep 0.05
          @level += 3
        end
      end
      return true
    end

  end
end
