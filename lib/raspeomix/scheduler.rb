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
      @scenario_handler = ScenarioHandler.new
      register
    end

    def register
      $log.debug("registering...")
      subscribe("/video/out") { |message| handle_state(:video, message, @scenario_handler) }
      subscribe("/image/out") { |message| handle_state(:image, message, @scenario_handler) }
      subscribe("/OMX") { |message| handle_state(:video, message, @scenario_handler) }
      subscribe("/captors/signal") { |signal| handle_captor_signal(signal) }
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

    def set_level(level, client)
      $log.debug("setting #{client} level to #{level}")
      publish("/#{client}/in", { :type => :command, :action => :set_level, :arg => "#{level}" }.to_json)
    end

    def handle_state(client, message, scenario_handler)
      $log.debug (" ------------------ client \"#{client}\" sent message : #{message}.")
      parsed_msg = JSON.parse(message, :symbolize_names => true)
      case parsed_msg[:state]
      when "ready" then
        start(client, scenario_handler.playing_media[:time]) if scenario_handler.is_client_active?(client)
      when "stopped" then
        scenario_handler.load_next_media
        load(scenario_handler.playing_media[:file], scenario_handler.playing_media[:type])
      end
    end

    def handle_captor_signal(signal)
      #not implemented yet
    end

    def finalize
      EM.stop_event_loop
    end

    def play_scenario
      load(@scenario_handler.playing_media[:file], @scenario_handler.playing_media[:type])
    end

    def run_video_test
      EM.run {
        load("/media/external/videofinale.mp4", :video)
        EM.add_timer(3){
          start(:video)
        }
        EM.add_timer(6){
          pause(:video)
        }
        EM.add_timer(9){
          play(:video)
        }
        EM.add_timer(12){
          set_level(90, :video)
        }
        EM.add_timer(15){
          stop(:video)
        }
      }
    end

    def run_image_test
      EM.run {
        load("/media/external/P1040851.JPG", :image)
        EM.add_timer(1){
          start(:image)
        }
        EM.add_timer(5){
          stop(:image)
        }
      }
    end
  end
end
end
