#!/usr/bin/env ruby
#
#TODO
#volume en %
#initialisation (volume de départ, position de départ)
#position du lecteur en fonction de l'écran ?
#vitesse de lecture ?
#sous titres ?

require 'securerandom'
require 'json'
require 'logger'
require 'eventmachine'
require 'faye'
require 'open3'
require '~/dev/raspeomix/lib/popen3'

require 'raspeomix/system' #???

$log = Logger.new(STDOUT)
$log.level =Logger::DEBUG


module Raspeomix

  class Fifo

    attr_reader :path

    def initialize(path="/tmp/fifo_#{SecureRandom.uuid}")
      @path = path
      @started = false
      %x{mkfifo #{@path}}
      $log.debug("fifo initialized @ #{@path}")
    end

  end

  class OMXInputFifo < Fifo

    def start
      $log.debug("starting")
      sleep(1)
      send('.') unless @started
      @started = true
      $log.debug("started")
    end

    def send(char)
      open(@path, "w+") do |f|
        f.write char
        $log.debug("command #{char} sent")
        sleep(0.05)
      end
    end

    def close
      %x{rm #{@path}} #todo rewrite this in ruby
    end
  end

  class VideoHandlerOMX
    PAUSECHAR = 'p'
    QUITCHAR = 'q'
    LVLDWN = '-'
    LVLUP = '+'

    def initialize
      @fifo = OMXInputFifo.new()
      @level = 0
      @playing = false
      @OMX_state = { :state => "stopped" , :level => 0 }
    end

    def set_level(lvl, options = { :units => "percent" })
      if options[:units] == "percent" then
        lvl = Math.log10(lvl.to_f/100)*10
      end
      $log.debug("asked level is #{lvl}")
      real_lvl = (lvl/3).round*3
      $log.debug("real level is #{real_lvl}")
      buff_lvl = @level
      $log.debug("asked lvl is #{lvl}, real lvl is #{real_lvl}")
      while @level != real_lvl
        if @level > real_lvl
          @fifo.send(LVLDWN)
          @level -= 3
          $log.debug("#{@level}")
        else
          @fifo.send(LVLUP)
          @level += 3
          $log.debug("{#@level}")
        end
      end
      $log.debug("level changed from #{buff_lvl} to #{@level}")
    end

    def load(file)

      @queue = EM::Queue.new
      cmd = "omxplayer -s #{file} < #{@fifo.path}"
      #cmd = "./tests/output.sh"
      @pipe = EM.popen3(cmd , {
        :stdout => Proc.new {
#          |data| puts "data received : \n #{data}"
         |data| @queue.push "#{data}"
        },
        :stderr => Proc.new { |data| puts "stderr: #{data}" }
      })
      @pipe.errback do |err_code|
        $log.error( "Error: #{err_code}")
      end
      EM.add_periodic_timer(1){
        inc = 1
        while !@queue.empty? do
          @queue.pop { |msg|
            #            msg.gsub(/\r/,'\n').each_line { |l|
            msg.each_line { |l|
              puts l
              parse_state(l)
              puts " state is now : #{@OMX_state}"
            }
          }
        end
      }

          #@pipe = Open3.popen3 ("omxplayer -s #{file} < #{@fifo.path}") do |@stdin, @stdout, @stderr|
          #  stdout.each do |line| puts line end
          # end
          ##########################################################################$log.debug("spawned #{@pipe.pid}")
          # @pipe = IO.popen("omxplayer #{file} < #{@fifo.path}")

          #      EM.popen("omxplayer #{file} < #{@fifo.path}") do |p|
          #        def p.receive_data(data)
          #          if command = @queue.pop
          #            EM.next_tick {
          #              # version EM sans fifo : self.send_data command
          #              # version avec fifo : @fifo.send(command)
          #              self.send_data command
          #              if @queue.size 
          #            }
          #          end
          #          # do something
          #        end
          # end

    end

    def parse_state (line)
      puts "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww"
      #      puts "line to scan : #{line.gsub(/\r/,'')}"
      puts "line to scan : #{line}"

      case line.scan(/\w+/)[0]
      when "Video","Audio"
        @OMX_state[:state] = "initializing"
      when "Subtitle"
        @OMX_state[:state] = "playing"
      when "Current"
        @OMX_state[:level] = line.scan(/\w+/)[2].gsub(/[^0-9]/,'').to_i
      when "have"
        @OMX_state[:state] = "stopped"
      end
    end

    def start
      @fifo.start
      @playing = true
    end

    def play
      toggle_play unless @playing
    end

    def pause
      toggle_play if @playing
    end

    def stop
      @fifo.send(QUITCHAR)
      #Process::waitpid(@pipe.pid)
      sleep 2 # in reality well wait for "have a good day"
      $log.debug("process seems finished")
      @fifo.close
      $log.debug("fifo deleted")
    end

    def toggle_play
      @fifo.send(PAUSECHAR)
      @playing = !@playing
    end
  end

  class Video
    attr_reader :state

    def initialize(handler = VideoHandlerOMX.new)
      @handler = handler
      register
    end

    def register(server_ip="#{ARGV[0]}") #todo : arg[0] ou ip par défaut
      @videoclient = Faye::Client.new("http://#{server_ip}:9292/faye")
      @state = :idle
      @videoclient.subscribe('/video/command') do |message|
        handle_command(message)
      end
      #publish('/system/register')
    end

    def handle_command(message)
      command = JSON.parse(message, :symbolize_names => true)
      $log.debug("action recognized : #{command[:action]}")
      if method(command[:action]).arity != 0
        self.send(command[:action],command[:arg])
      else
        self.send(command[:action])
      end
    end

    def load(arg)
      @handler.load(arg)
      change_state(:ready)
    end

    def change_level(arg)
      @handler.set_level(arg)
    end

    def start()
      @handler.start
      change_state(:playing)
    end

    def play()
      @handler.play
      change_state(:playing)
    end

    def pause()
      @handler.pause
      change_state(:paused)
    end

    def stop()
      @handler.stop
      change_state(:idle)
    end

    private
    def change_state(state)
      @state = state
      @videoclient.publish('/video/state', { :state => @state })
    end
  end
end
