#!/usr/bin/env ruby
#
#Faye client for Raspéomix
#Wraps Faye functions used by clients

require 'faye'

module Raspeomix

  module Client

    module FayeClient

      def start_client(host='localhost', port='9292')
        @faye = Faye::Client.new("http://#{host}:#{port}/faye")
        publish('/system', { :sender => self.class, :msg => "starting" })
        @faye
      end

      def publish(channel, value)
        # The key must start with /
        channel[0] == '/' or raise ArgumentError
        $log.debug(" ---- FAYE : publishing #{value} to #{"/#{nick}#{channel}"}")
        faye.publish("/#{nick}#{channel}", value)
      end

      def subscribe(channel)
        channel[0] == '/' or raise ArgumentError
        publish("/debug", { :msg => "Subscribing to #{nick}#{channel}" })
        $log.debug(" ---- FAYE : subscribing to #{"/#{nick}#{channel}"}")
        faye.subscribe("/#{nick}#{channel}") do |message|
          yield message if block_given?
        end
      end

      def nick
        @nick ||= `hostname`.chomp
      end

      def faye
        @faye ||= start
      end
    end
  end
end
