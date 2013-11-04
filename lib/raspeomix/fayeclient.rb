#!/usr/bin/env ruby
#
#Faye client for Raspéomix
#Wraps Faye functions used by clients

require 'faye'

module Raspeomix

  module Client

    module FayeClient

      def start_client(host='localhost', port=ENV['RASP_PORT'])
        @faye = Faye::Client.new("http://#{host}:#{port}/faye")
        publish('/system', { :sender => self.class, :msg => "starting" })
        @faye
      end

      # Publish a message on Faye bus
      #
      # @params [String] channel The channel to publish on. Channels are always
      # prefixed with short hostname . It *must* start with '/'
      # @params [Hash] value Hash cotaining the message to pass
      # @note The key must start with /
      # @note DO NOT call Raspeomix.logger#level in this method. It will crash
      # the stack in RASP_LOG=FAYE mode
      def publish(channel, value)
        # The key must start with /
        # !! DO NOT call Raspeomix.logger#level HERE !!
        # THIS WILL CRASH THE STACK IN RASP_LOG=FAYE MODE !
        #
        channel[0] == '/' or raise ArgumentError
        faye.publish("/#{nick}#{channel}", value)
      end

      def subscribe(channel)
        channel[0] == '/' or raise ArgumentError
        publish("/debug", { :msg => "Subscribing to #{nick}#{channel}" })
        Raspeomix.logger.debug(" ---- FAYE : subscribing to #{"/#{nick}#{channel}"}")
        faye.subscribe("/#{nick}#{channel}") do |message|
          yield message if block_given?
        end
      end

      def nick
        @nick ||= `hostname`.chomp
      end

      def faye
        @faye ||= start_client
      end
    end
  end
end
