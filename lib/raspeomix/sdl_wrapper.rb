#!/usr/bin/env ruby 
#Ruby SDL wrapper using rubygame to display images
#TODO : checking function effects before returning true

require 'eventmachine'
require 'faye'
require 'rubygame'

module Raspeomix

  class SDLWrapper

    include Rubygame

    def initialize(host, port)
      @playing = false
      @play_time = 0
      @resolution = Screen.get_resolution
      @client = Faye::Client.new("http://#{host}:#{port}/faye")
    end

    def send_sdl_state(state)
      @client.publish("/#{`hostname`.chomp}/image/handler", { :type => :sdl_state, :state => state })
    end

    def load(file)
      case file
      when "black"
        @image = Surface.new([100,100])
      else
        @image = Surface.load(file)
      end
      send_sdl_state(:ready)
      true
    end

    def start(time)
      @play_time = time
      #@screen = Screen.open(@resolution)
      #@screen.show_cursor = false
      #@image.blit(@screen,[0,0])
      #@screen.update
      play_until_end
      send_sdl_state(:playing)
      true
    end

    def play
      toggle_pause unless @playing
    end

    def pause
      toggle_pause unless !@playing
    end

    def toggle_pause
      if @playing
        @timebuffer = Time.now
      else
        @play_time += @timebuffer-Time.now
      end
      @playing = !@playing
    end

    def play_until_end
      Raspeomix.logger.debug( "---------------- SDLWRAPPER play time : #{@play_time}")
      if @play_time == 0
        stop
      else
        time = @play_time
        @play_time = 0
        EM.add_timer(time){
          play_until_end
        }
      end
    end

    def stop
      send_sdl_state(:stopped)
      send_sdl_state(:idle)
      #Screen.close
      true
    end
  end
end
