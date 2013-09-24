#!/usr/bin/env ruby
#
#scheduler for Raspéomix
#handles synchronisation between events and multimedia clients

require 'json'
require 'eventmachine'
require 'faye'
require 'logger'

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

module Raspeomix

  module Client

    class Scheduler

      include FayeClient

      def initialize
        $log.debug("initializing...")
        start_client('localhost', 9292)
        @server_add = "http://localhost:9292/faye"
        @scenario_handler = ScenarioHandler.new("/home/pi/dev/raspeomix/tests")
        register
        @playing = true
      end

      def isplaying?
        return @playing
      end

      def register
        $log.debug("registering...")
        subscribe("/video/out") { |message| handle_client_message(:video, message) }
        subscribe("/image/out") { |message| handle_client_message(:image, message) }
        subscribe("/keyboard/out") { |message| handle_input_message(message) }
        $log.debug("registered")
      end

      def load(file, client)
        $log.debug("loading #{file} on #{client}")
        publish("/#{client}/in", { :type => :command, :action => :load, :arg => file }.to_json)
      end

      def start(client, time)
        $log.debug("starting #{client}")
        publish("/#{client}/in", { :type => :command, :action => :start, :arg => time }.to_json)
      end

      def play(client)
        $log.debug("sending play to #{client}")
        publish("/#{client}/in", { :type => :command, :action => :play }.to_json)
      end

      def pause(client)
        $log.debug("sending pause to #{client}")
        publish("/#{client}/in", { :type => :command, :action => :pause }.to_json)
      end

      def stop(client)
        $log.debug("stopping #{client}")
        publish("/#{client}/in", { :type => :command, :action => :stop }.to_json)
      end

      def stop_scenario
        $log.debug("ending scenario")
        publish("/#{@scenario_handler.playing_media[:type]}/in", { :type => :command, :action => :stop }.to_json)
        @playing = false
      end

      def set_level(level, client)
        $log.debug("setting #{client} level to #{level}")
        publish("/#{client}/in", { :type => :command, :action => :set_level, :arg => "#{level}" }.to_json)
      end

      def handle_client_message(client, message)
        if isplaying?
          $log.debug (" ------------------ client \"#{client}\" sent message : #{message}.")
          parsed_msg = parse(message)
          case parsed_msg[:state]
          when "ready" then
            start(client, @scenario_handler.playing_media[:time]) if @scenario_handler.is_client_active?(client)
          when "stopped" then
            @scenario_handler.load_next_media
            load(@scenario_handler.playing_media[:file], @scenario_handler.playing_media[:type])
          end
        else
          $log.debug (" ------------------ client \"#{client}\" sent message : #{message}, no scenario playing, ignoring message.")
        end
      end

      def handle_input_message(message)
        parsed_msg = parse(message)
        $log.debug (" ------------------ sensor sent message : #{parsed_msg}")
        if parsed_msg[:type]=="event"
          case parsed_msg[:event]
          when "pause"
            pause(@scenario_handler.playing_media[:type])
          when "play"
            play(@scenario_handler.playing_media[:type])
          when "stop"
            case parsed_msg[:arg]
            when "media"
              stop(@scenario_handler.playing_media[:type])
            when "all"
              stop_scenario
            end
          end
        end
      end

      def parse(msg)
        return JSON.parse(msg, :symbolize_names => true)
      end

      def finalize
        EM.stop_event_loop
      end

      def play_scenario
        load(@scenario_handler.playing_media[:file], @scenario_handler.playing_media[:type])
      end

    end
  end
end
