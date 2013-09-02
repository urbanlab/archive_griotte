#!/usr/bin/env ruby
#
#video client for Raspéomix
#handles communication between scheduler
#and OMXPlayer ruby wrapper

module Raspeomix
  
  class VideoClient < MMClient

    def initialize(server_ip)
      @handler = ROMXWrapper.new(server_ip)
      super(:video, server_ip)
    end

    def load(file)
      if @handler.load(file)
        change_state(:ready)
      else
        change_state(:error)
      end
    end

    def start(time)
      if @handler.start
        change_state(:playing)
      else
        change_state(:error)
      end
    end

    def play
      if @handler.play
        change_state(:playing)
      else
        change_state(:error)
      end
    end

    def pause
      if @handler.pause
        change_state(:paused)
      else
        change_state(:error)
      end
    end

    def set_level(level)
      if @handler.set_level(level)
        level_ack(level)
      else
        level_ack(:error)
      end
    end

    def stop
      @handler.stop
    end

  end
end
