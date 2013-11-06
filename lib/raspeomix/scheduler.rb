#!/usr/bin/env ruby
#
#scheduler for Raspéomix
#handles synchronisation between events and multimedia clients

require 'eventmachine'
require 'faye'

module Raspeomix

  module Client

    class Scheduler

      include FayeClient

      def initialize(start_vol = 100)
        Raspeomix.logger.debug("initializing...")
        start_client('localhost', ENV['RASP_PORT'])
        @server_add = "http://localhost:#{ENV['RASP_PORT']}/faye"
        @global_vol = start_vol
        @muted = false
        register
      end

      def play_scenario(scenarios_path)
        @scenario_handler = ScenarioHandler.new(scenarios_path)
        @playing = true
        play_step
      end

      def subscribe_to_clients

      end

      def instanciate_clients(client_array)
        #client_array.each { |client|
        #  case 
        #}
      end

      def register
        Raspeomix.logger.debug("registering...")
        subscribe("/video/out") { |message| handle_client_message(message) }
        subscribe("/image/out") { |message| handle_client_message(message) }
        subscribe("/sensors/analog/an0") { |message| handle_client_message(message) }
        subscribe("/sound") {|message| handle_sound_command(message) }
        subscribe("/scenario") {|message| handle_scenario_command(message) }
        Raspeomix.logger.debug("registered")
      end

      def handle_client_message(message)
        check_next_step(message)
        check_sound(message)
      end

      def check_sound(message)
        unless message["client"]==nil
          if (message["client"]=="video" or message["client"]=="sound")
            if (message["properties"]["volume"]!=@global_vol and !@muted)
              Raspeomix.logger.debug("received volume (#{message["properties"]["volume"]}) does not match global volume, setting it to #{@global_vol}")
              set_level(message["properties"]["client"], @global_vol)
            end
            if (message["properties"]["muted"]!=@muted)
              mute(message["properties"]["client"])
            end
          end
        end
      end

      def check_next_step(message)
        Raspeomix.logger.debug (" ------------------ received message : #{message}.")
        if message["type"] == "client_update"
          if compare_conditions(@scenario_handler.next_step_conditions, message["properties"])
            @scenario_handler.go_to_next_step
            play_step
          end
        end
      end

      def compare_conditions(conditions_array, message)
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
        args=[file]
        Raspeomix.logger.debug("loading #{file} on #{client}")
        publish("/#{client}/in", { :type => :command, :action => :load, :args => args })
      end

      def start(client, time, vol)
        args=[time,vol]
        Raspeomix.logger.debug("starting #{client}")
        publish("/#{client}/in", { :type => :command, :action => :start, :args => args })
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

      def set_level(client, level)
        Raspeomix.logger.debug("setting #{client} level to #{level}")
        publish("/#{client}/in", { :type => :command, :action => :set_level, :args => [level]})
      end

      def mute(client)
        Raspeomix.logger.debug("muting #{client}")
        publish("/#{client}/in", { :type => :command, :action => :mute })
      end

      def stop_scenario
        Raspeomix.logger.debug("ending scenario")
        publish("/#{@scenario_handler.current_step[:mediatype]}/in", { :type => :command, :action => :stop })
        @playing = false
      end

      def set_global_level(level)
        @global_vol = level
      end

      def handle_sound_command(message)
        Raspeomix.logger.debug (" ------------------ /sound channel received : #{message}.")
        case message["type"]
        when "set_level"
          set_level(@scenario_handler.current_step[:mediatype], message["level"])
          set_global_level(message["level"])
          @muted = false
        when "mute"
          Raspeomix.logger.debug("seeting mute to #{@muted}")
          mute(@scenario_handler.current_step[:mediatype])
          @muted = !@muted
        end
      end

      def handle_scenario_command(message)
        Raspeomix.logger.debug (" ------------------ /scenario channel received: #{message}.")
        case message["command"]
        when "pause"
          pause(@scenario_handler.current_step[:mediatype])
        when "play"
          play(@scenario_handler.current_step[:mediatype])
        end
      end

      def finalize
        EM.stop_event_loop
      end

      def play_step
        case @scenario_handler.current_step[:step]
        when "read_media"
          load(@scenario_handler.current_step[:file], @scenario_handler.current_step[:mediatype])
          start(@scenario_handler.current_step[:mediatype], 0, @global_vol)
        when "pause_reading"
          load("black", "image")
          start("image", @scenario_handler.current_step[:time], @global_vol)
        when "wait_for_event"
          Raspeomix.logger.debug("waiting for event")
        end
      end

    end
  end
end
