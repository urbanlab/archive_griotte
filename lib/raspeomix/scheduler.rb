#!/usr/bin/env ruby
#
#scheduler for Raspéomix
#handles synchronisation between events and multimedia clients

require 'json'
require 'eventmachine'
require 'faye'
require 'logger'

module Raspeomix

  module Client

    class Scheduler

      include FayeClient

      def initialize
        Raspeomix.logger.debug("initializing...")
        start_client('localhost', 9292)
        @server_add = "http://localhost:9292/faye"
        register
      end

      def play_scenario(scenarios_path)
        @scenario_handler = ScenarioHandler.new(scenarios_path)
        @playing = true
        play_step
      end

      def isplaying?
        return @playing
      end

      def register
        Raspeomix.logger.debug("registering...")
        subscribe("/video/out") { |message| handle_client_message(:video, message) }
        subscribe("/image/out") { |message| handle_client_message(:image, message) }
        subscribe("/sensors/analog/an0") { |message| handle_client_message("sensors/analog/an0", message) }
        subscribe("/sound") {|message| handle_sound_command(message) }
        subscribe("/scenario") {|message| handle_scenario_command(message) }
        Raspeomix.logger.debug("registered")
      end

      def load(file, client)
        Raspeomix.logger.debug("loading #{file} on #{client}")
        publish("/#{client}/in", { :type => :command, :action => :load, :arg => file }.to_json)
      end

      def start(client, time)
        Raspeomix.logger.debug("starting #{client}")
        publish("/#{client}/in", { :type => :command, :action => :start, :arg => time }.to_json)
      end

      def play(client)
        Raspeomix.logger.debug("sending play to #{client}")
        publish("/#{client}/in", { :type => :command, :action => :play }.to_json)
      end

      def pause(client)
        Raspeomix.logger.debug("sending pause to #{client}")
        publish("/#{client}/in", { :type => :command, :action => :pause }.to_json)
      end

      def stop(client)
        Raspeomix.logger.debug("stopping #{client}")
        publish("/#{client}/in", { :type => :command, :action => :stop }.to_json)
      end

      def stop_scenario
        Raspeomix.logger.debug("ending scenario")
        publish("/#{@scenario_handler.current_step["mediatype"]}/in", { :type => :command, :action => :stop }.to_json)
        @playing = false
      end

      def set_level(level, client)
        Raspeomix.logger.debug("setting #{client} level to #{level}")
        publish("/#{client}/in", { :type => :command, :action => :set_level, :arg => level }.to_json)
      end

      def handle_client_message(client, message)
        if isplaying?
          Raspeomix.logger.debug (" ------------------ client \"#{client}\" sent message : #{message}.")
          #parse json message
          parsed_msg = parse(message)
          #start client if ready
          if parsed_msg[:type]=="property_update" and parsed_msg[:state]=="ready"
            case parsed_msg[:state]
            when "ready" then
              start(client, @scenario_handler.current_step[:time]) if @scenario_handler.is_client_active?(client)
              #load next media or wait for next event if conditions are fullfilled
            when "..." then
              #...
            end
          else
            @scenario_handler.next_step_conditions.each { |condition|

              if client.to_s == condition[:expected_client].to_s and check_condition(client.to_s, parsed_msg, condition[:condition])
                @scenario_handler.go_to_next_step
                play_step
              end
            }
          end
        else
          Raspeomix.logger.debug (" ------------------ client \"#{client}\" sent message : #{message}, no scenario playing, ignoring message.")
        end
      end

      def check_condition(client, parsed_msg, condition)
        case client
        when "image", "sound", "video"
          return parsed_msg[:state] == condition
        else #TODO : mettre la vraie condition
          if condition[0] == "down"
            return parsed_msg[:analog_value][:converted_value].to_i>condition[1]
          else
            return parsed_msg[:analog_value][:converted_value].to_i<condition[1]
          end
        end
      end

      def handle_sound_command(message)
          Raspeomix.logger.debug (" ------------------ command received : #{message}.")
        message=parse(message) #unless message.class==Hash
        if message[:state]=="off"
          level = 0
        else
          level = message[:level]
        end
        set_level(level, @scenario_handler.current_step[:mediatype])
      end

      def handle_scenario_command(message)
          Raspeomix.logger.debug (" ------------------ command received: #{message}.")
        message=parse(message) #unless message.class==Hash
        case message[:command]
        when "pause"
          pause(@scenario_handler.current_step[:mediatype])
        when "play"
          play(@scenario_handler.current_step[:mediatype])
        end
      end

      def handle_webclient_message(message)
        parsed_msg = parse(message)
        if parsed_msg[:type]=="event"
          case parsed_msg[:event]
          when "pause"
            pause(@scenario_handler.current_step[:mediatype])
          when "play"
            play(@scenario_handler.current_step[:mediatype])
          when "level"
            set_level(parsed_msg[:arg], @scenario_handler.current_step[:mediatype])
          end
        end
      end

      def handle_input_message(message)
        parsed_msg = parse(message)
        Raspeomix.logger.debug (" ------------------ sensor sent message : #{parsed_msg}")
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
