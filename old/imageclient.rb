#!/usr/bin/env ruby
#
#image client for Raspéomix
#handles scheduler messages
#displays files with rubygame

require 'faye'
require 'eventmachine'
require 'rubygame'

include Rubygame
include Rubygame::Events

module Raspeomix

  class ImageClient < MMClient

    def initialize(server_ip)
      super(:image, server_ip)
    end

    def load(file)
      @image = Surface.load file
      change_state(:ready)
    end

    def start(time)
      resolution = Screen.get_resolution
      @screen = Screen.open(resolution)
      @image.blit(@screen,[0,0])
      @screen.update
      @screen.show_cursor = false
      change_state(:playing)
      EM.add_timer(time) {
        stop
      }
    end

    def stop
      Screen.close
      change_state(:stopped)
      change_state(:idle)
    end

  end
end
