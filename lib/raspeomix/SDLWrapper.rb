#!/usr/bin/env 
#Ruby SDL wrapper using rubygame to display images
#TODO : checking function effects before returning true

require 'eventmachine'
require 'faye'
require 'rubygame'

module Raspeomix

  class SDLWrapper

    include Rubygame

    def initialize(host, port)
      @resolution = Screen.get_resolution
      @client = Faye::Client.new("http://#{host}:#{port}/faye")
    end

    def send_sdl_state(state)
      @client.publish("/#{`hostname`.chomp}/image/handler", { :type => :sdl_state, :state => state }.to_json)
    end

    def load(file)
      @image = Surface.load(file)
      send_sdl_state(:ready)
      true
    end

    def start(time)
      @screen = Screen.open(@resolution)
      @screen.show_cursor = false
      @image.blit(@screen,[0,0])
      @screen.update
      EM.add_timer(time) {
        stop
      }
      send_sdl_state(:playing)
      true
    end

    def play
      toggle_pause
    end

    def pause
      toggle_pause
    end

    def toggle_pause
      #not implemented
    end

    def stop
      send_sdl_state(:stopped)
      send_sdl_state(:idle)
      Screen.close
      true
    end
  end
end
