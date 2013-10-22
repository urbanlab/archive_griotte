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
        subscribe("/video/out") { |message| check_next_step(message) }
        subscribe("/image/out") { |message| check_next_step(message) }
        subscribe("/sensors/analog/an0") { |message| check_next_step(message) }
        subscribe("/sound") {|message| handle_sound_command(message) }
        subscribe("/scenario") {|message| handle_scenario_command(message) }
        Raspeomix.logger.debug("registered")
      end

      def check_next_step(message)
        Raspeomix.logger.debug (" ------------------ received message : #{message}.")
        if message["type"] == "client_update"
          if compare(@scenario_handler.next_step_conditions, message["properties"])
            @scenario_handler.go_to_next_step
            play_step
          end
        end
      end

      def compare(conditions_array, message)
        bool = true
        conditions_array.each { |conditions|
          conditions.keys.each { |key|
            unless key == "RPN_condition"
              #simple comparison
              unless message[key]==nil
                bool = bool & (message[key]==conditions[key])
              else
                bool = false
              end
            else
              #compares using RPN to check if value is superior or inferior
              unless message[conditions[key]["checked_value"].to_s]==nil
                bool = bool & (RPNCalculator.evaluate(conditions["RPN_condition"]["RPNexp"].sub!("x",  message[conditions["RPN_condition"]["checked_value"].to_s].to_s)))
              else
                bool = false
              end
            end
          }
          return true if bool
          bool = true
        }
        return false
      end

      def load(file, client)
        Raspeomix.logger.debug("loading #{file} on #{client}")
        publish("/#{client}/in", { :type => :command, :action => :load, :arg => file })
      end

      def start(client, time)
        Raspeomix.logger.debug("starting #{client}")
        publish("/#{client}/in", { :type => :command, :action => :start, :arg => time })
      end

      def play(client)
        Raspeomix.logger.debug("sending play to #{client}")
        publish("/#{client}/in", { :type => :command, :action => :play })
      end

      def pause(client)
        Raspeomix.logger.debug("sending pause to #{client}")
        publish("/#{client}/in", { :type => :command, :action => :pause })
      end

      def stop(client)
        Raspeomix.logger.debug("stopping #{client}")
        publish("/#{client}/in", { :type => :command, :action => :stop })
      end

      def stop_scenario
        Raspeomix.logger.debug("ending scenario")
        publish("/#{@scenario_handler.current_step[:mediatype]}/in", { :type => :command, :action => :stop })
        @playing = false
      end

      def set_level(level, client)
        Raspeomix.logger.debug("setting #{client} level to #{level}")
        publish("/#{client}/in", { :type => :command, :action => :set_level, :arg => level })
      end

      def handle_client_message(client, message)
        if isplaying?
          #parse json message
          #start client if ready
          if message["type"]=="property_update" and message["state"]=="ready"
            case message["state"]
            when "ready" then
              start(client, @scenario_handler.current_step[:time]) if @scenario_handler.is_client_active?(client)
              #load next media or wait for next event if conditions are fullfilled
            when "..." then
              #...
            end
          else
            @scenario_handler.next_step_conditions.each { |condition|
              if client.to_s == condition[:expected_client].to_s and check_condition(client.to_s, message, condition[:condition])
                @scenario_handler.go_to_next_step
                play_step
              end
            }
          end
        else
          Raspeomix.logger.debug (" ------------------ client \"#{client}\" sent message : #{message}, no scenario playing, ignoring message.")
        end
      end

      def check_condition(client, message, condition)
        case client
        when "image", "sound", "video"
          return message["state"] == condition
        else #TODO : mettre la vraie condition
          if condition[0] == "down"
            return message["analog_value"]["converted_value"].to_i>condition[1]
          else
            return message["analog_value"]["converted_value"].to_i<condition[1]
          end
        end
      end

      def handle_sound_command(message)
        Raspeomix.logger.debug (" ------------------ command received : #{message}.")
        if message["state"]=="off"
          level = 0
        else
          level = message["level"]
        end
        set_level(level, @scenario_handler.current_step[:mediatype])
      end

      def handle_scenario_command(message)
        Raspeomix.logger.debug (" ------------------ command received: #{message}.")
        case message["command"]
        when "pause"
          pause(@scenario_handler.current_step[:mediatype])
        when "play"
          play(@scenario_handler.current_step[:mediatype])
        end
      end

      def handle_input_message(message)
        Raspeomix.logger.debug (" ------------------ sensor sent message : #{message}")
        if message["type"]=="event"
          case message["event"]
          when "pause"
            pause(@scenario_handler.playing_media[:type])
          when "play"
            play(@scenario_handler.playing_media[:type])
          when "stop"
            case message["arg"]
            when "media"
              stop(@scenario_handler.playing_media[:type])
            when "all"
              stop_scenario
            end
          end
        end
      end

      def finalize
        EM.stop_event_loop
      end

      def play_step
        case @scenario_handler.current_step[:step]
        when "read_media"
          load(@scenario_handler.current_step[:file], @scenario_handler.current_step[:mediatype])
          start(@scenario_handler.current_step[:mediatype], 0)
        when "pause_reading"
          load("black", "image")
          start("image", @scenario_handler.current_step[:time])
        when "wait_for_event"
          Raspeomix.logger.debug("waiting for event")
        end
      end

    end
  end
end
