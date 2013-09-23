#!/usr/bin/env ruby
#event handler for raspéomix
#
#Catches and transmits exterior events to Scheduler

require 'eventmachine'
require 'faye'

module Raspeomix

  module Client

    class EventHandler

      include FayeClient

      def initialize(type)
        $log.debug("starting event handler...")
        @properties = { :sensor_type => type }
        start_client('localhost', 9292)
        start_sensor
      end

      def start_sensor
        #start sensor
      end

      def start
        publish("/sensor/out", { :type => :event, :event => :start }.to_json)
      end

      def pause
        publish("/sensor/out", { :type => :event, :event => :pause }.to_json)
      end

      def play
        publish("/sensor/out", { :type => :event, :event => :play }.to_json)
      end

      def stop
        publish("/sensor/out", { :type => :event, :event => :stop, :arg => :media }.to_json)
      end

      def stop_all
        publish("/sensor/out", { :type=> :event, :event =>:stop, :arg => :all }.to_json)
      end

    end

    class Keyboard < EventHandler

      def initialize(layout)
        super(:keyboard)
        @properties[:layout] = layout
      end

      def start_sensor
        EM.add_periodic_timer(0.5) {
          gets.chomp.each_byte { |i|
            handle_input(i.chr)
          }
        }
      end

      def handle_input(char)
        $log.info ("received #{char}")
        if @properties[:layout] == :azerty
          case char
          when "a"
            pause
          when "z"
            play
          when "e"
            stop
          when "q"
            start
          when "s"
            stop_all
          end
        end
      end

    end

  end
end
