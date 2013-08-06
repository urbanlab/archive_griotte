#!/usr/bin/env ruby
#
#OMXPlayer ruby wrapper
#sends inputs with named pipe
#receives outputs with popen3

require 'securerandom'

module Raspeomix

  #this class is used to send input to OMXPlayer
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
      puts "char #{char} sent"
    end

    def close
      %x{rm #{@path}}
    end

  end

  class ROMXWrapper

    PAUSECHAR = 'p'
    QUITCHAR = 'q'
    LVLDWN = '-'
    LVLUP = '+'

    def initialize(server_ip)
      @playing = false
      @level = 0
      #Faye client will warn videoclient when playback is over
      @client = Faye::Client.new("http://#{server_ip}:9292/faye")
    end

    def load(file)
      @fifo = Fifo.new
      @pipe = EM.popen3( "omxplayer -s #{file} < #{@fifo.path}", {
        :stdout => Proc.new { |data|
          data.each_line { |line| parse_line(line) }
        },
        :stderr => Proc.new { |err| puts "error while loading : #{err}" }
      })

    end

    def start
      @fifo.start
      @playing = true
      return true
    end

    def play
      toggle_pause unless @playing
      return true
    end

    def toggle_pause
      @fifo.send(PAUSECHAR)
      @playing = !@playing
    end

    def pause
      toggle_pause unless !@playing
      return true
    end

    def stop
      @fifo.send(QUITCHAR)
      sleep 1
      @fifo.close
      #Process::waitpid(@pipe.pid)
      #this is ugly, fix this
      return true
    end

    def set_level(lvl)
      lvl = Math.log10(lvl.to_f/100)*10 #percent to db
      real_lvl = (lvl/3).round*3 #OMXPlayer changes level per 3db (7db -> 6db or -20db -> -21db)
      while @level != real_lvl
        if @level > real_lvl
          @fifo.send(LVLDWN)
          sleep 0.05 #quickfix to avoid fifo spamming
          @level -= 3
        else
          @fifo.send(LVLUP)
          sleep 0.05
          @level += 3
        end
      end
      return true
    end


    def parse_line(line)
      case line.scan(/\w+/)[0]
      when "have"
        @client.publish("/OMX", 'stopped')
      end
    end

  end
end
