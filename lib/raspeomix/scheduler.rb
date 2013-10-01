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
        register
      end

      def play_scenario
        @scenario_handler = ScenarioHandler.new("/home/pi/dev/raspeomix/tests")
        @playing = true
        play_step
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
        publish("/#{@scenario_handler.current_step["mediatype"]}/in", { :type => :command, :action => :stop }.to_json)
        @playing = false
      end

      def set_level(level, client)
        $log.debug("setting #{client} level to #{level}")
        publish("/#{client}/in", { :type => :command, :action => :set_level, :arg => "#{level}" }.to_json)
      end

      def handle_client_message(client, message)
        if isplaying?
          $log.debug (" ------------------ client \"#{client}\" sent message : #{message}.")
          #parse json message
          parsed_msg = parse(message)
          
          #start client if ready
          case parsed_msg[:state]
          when "ready" then
            start(client, @scenario_handler.current_step[:time]) if @scenario_handler.is_client_active?(client)
          #load next media or wait for next event if conditions are fullfilled
          when "..." then
            #...
          else
          @scenario_handler.next_step_conditions.each { |condition|
            if client.to_s == condition[:expected_client].to_s and check_condition(client.to_s, parsed_msg[:state].to_s, condition[:condition].to_s)
              @scenario_handler.go_to_next_step
              play_step
            end
          }
          end
        else
          $log.debug (" ------------------ client \"#{client}\" sent message : #{message}, no scenario playing, ignoring message.")
        end
      end

      def check_condition(client, client_state, condition)
        case client
        when "image", "sound", "video"
          return client_state == condition
        when "sensor" #pas exactement ça
          return (client_state.to_i > condition[0] and condition[1] > client_state.to_i)
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

      def play_step
        case @scenario_handler.current_step[:step]
        when "read_media"
          load(@scenario_handler.current_step[:file], @scenario_handler.current_step[:mediatype])
        when "pause_reading"
          load("black", "image")
        when "wait_for_event"
          #TODO
        end
      end

    end
  end
end
