#!/usr/bin/env ruby
#event handler for raspéomix
#
#Catches and transmits exterior events to Scheduler

module Raspeomix

  module Client

    class EventHandler

      def initialize(type)
        $log.debug("starting event handler...")
        @properties { :event_type => type }
        start_client('localhost', 9292)
      end

      def pause
        publish("/events", { :type => event, :event => :pause }
      end

    end

    class Keyboard < EventHandler
      def initialize
        super(:keyboard)
      end
    end

  end
end
