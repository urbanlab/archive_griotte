#!/usr/bin/env ruby
#event handler for raspéomix
#
#Catches and transmits exterior events to Scheduler
#For now only uses kayboard inputs

require 'eventmachine'
require 'faye'

module Raspeomix

  module Client

    class EventHandler

      include FayeClient

      def initialize(type)
        Raspeomix.logger.debug("starting event handler...")
        @properties = { :sensor_type => type }
        start_client('localhost', 9292)
        start_sensor
      end

      def start_sensor
        #start sensor
      end

      def start
        publish("/#{@properties[:sensor_type]}/out", { :type => :event, :event => :start })
      end

      def pause
        publish("/#{@properties[:sensor_type]}/out", { :type => :event, :event => :pause })
      end

      def play
        publish("/#{@properties[:sensor_type]}/out", { :type => :event, :event => :play })
      end

      def stop
        publish("/#{@properties[:sensor_type]}/out", { :type => :event, :event => :stop, :arg => :media })
      end

      def stop_all
        publish("/#{@properties[:sensor_type]}/out", { :type=> :event, :event =>:stop, :arg => :all })
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
        Raspeomix.logger.info ("received #{char}")
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
