#!/usr/bin/env ruby
#
#basic multimedia client for Raspéomix
#handles communication with scheduler

require 'faye'
require 'eventmachine'
require 'json'
require 'logger'
require '/home/pi/dev/raspeomix/lib/popen3.rb'

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

module Raspeomix

  module Client

    class Multimedia < Faye

      def initialize(server_ip)
        @properties = { :type => :multimedia, :state => :launching, :level => nil }
        register(server_ip)
      end

      def register
        start(localhost, 9292)
        subscribe("/#{self.class}/in") { |message| receive_message(message) }
        #case @properties[:type]
        #when :video,  :sound
        #  @client.subscribe("/OMX") { |m| change_state(:idle) if m["state"] = "stopped" }
        #end
        change_state(:idle)
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
        else
          $log.error("message type #{parsed_msg[:type]} not recognized")
        end
      end

      def update_state(state)
        update_property(:state, state)
      end

      def update_level(level)
        update_property(:level, level)
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
