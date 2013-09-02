#!/usr/bin/env ruby
#
#basic multimedia client for Raspéomix
#handles communication with scheduler

require 'faye'
require 'eventmachine'
require 'json'
require 'logger'

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

module Raspeomix

  module Client

    module Communication

      include FayeClient

      attr_reader :properties

      def initialize
        start(localhost, 9292)
        @properties = { :state => initializing, :out_level => nil }
      end

      def in_register
        register("/#{self.class}/in")
        update_state(:idle)
      end

      def register(path)
        subscribe(path) { |message| receive_message(message) }
      end

      def receive_message(message)
        $log.debug("message received : #{message}")
        parsed_msg = JSON.parse(message, :symbolize_names => true)
        if parsed_msg[:type] == :command
          if method(parsed_msg[:command]).arity != 0
            self.send(parsed_msg[:action], parsed_msg[:arg])
          else
            self.send(parsed_msg[:action])
          end
        elsif parsed_msg[:type] == :sdl_state
          self.send(update_handled_state(parsed_msg[:state]))
        elsif parsed_msg[:type] == :omx_state
          self.send(update_handled_state(parsed_msg[:state]))
        else
          $log.error("message type #{parsed_msg[:type]} not recognized, message is : #{message}")
        end
      end

      def update_state(state)
        update_property(:state, state)
      end

      def update_out_level(level)
        update_property(:out_level, level)
      end

      def update_property(property_type, property)
        @properties[property_type] = property
        publish_property(property_type, property)
        $log.debug("#{property_type} changed to #{property}")
      end

      def publish_property(property_type, property)
        publish("/#{self.class}/out", { :type => :property_update, property_type => property })
      end

    end
  end
end
