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

  class MMClient

    attr_reader :properties

    def initialize(clienttype, server_ip)
      $log.debug("initializing...")
      @properties = { :type => clienttype, :state => :launching, :level => nil }
      register(server_ip)
    end

    def register(server_ip)
      $log.debug("registering...")
      @client = Faye::Client.new("http://#{server_ip}:9292/faye")
      @client.subscribe("/#{@properties[:type].to_s}/command") { |m| handle_message(:command, m) }
      #if this client is sound or video, we have to check when the playback is over
      case @properties[:type]
      when :video,  :sound
        @client.subscribe("/OMX") { |m| change_state(:idle) if m["state"] = "stopped" }
      end
      change_state(:idle)
      $log.debug("registered")
    end

    def handle_message(messagetype, message)
      $log.debug("message received : #{message}")
      if messagetype == :command
        command = JSON.parse(message, :symbolize_names => true)
        if method(command[:action]).arity != 0
          self.send(command[:action], command[:arg])
        else
          self.send(command[:action])
        end
      else
        #no other message type implemented for now
      end
    end

    def change_state(state)
      $log.debug("changing state to #{state}")
      @state = state
      @client.publish("/#{@properties[:type].to_s}/state", { :state => @state })
    end

    def level_ack(level)
      $log.debug("changing level to #{level}")
      @client.publish("/#{@properties[:type].to_s}/state", { :level => level })
    end

    def send_message
      #no use for now
    end

  end

end
