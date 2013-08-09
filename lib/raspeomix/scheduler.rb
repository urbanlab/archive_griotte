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

  class Scheduler

    def initialize(server_ip)
      $log.debug("initializing...")
      @server_add = "http://#{server_ip}:9292/faye"
      @scenario_handler = ScenarioHandler.new
      register
    end

    def register
      $log.debug("registering...")
      @client = Faye::Client.new(@server_add)
      @client.subscribe("/video/state") { |message| handle_state(:video, message, @scenario_handler) }
      @client.subscribe("/image/state") { |message| handle_state(:image, message, @scenario_handler) }
      @client.subscribe("/OMX") { |message| handle_state(:video, message, @scenario_handler) }
      @client.subscribe("/captors/signal") { |signal| handle_captor_signal(signal) }
      $log.debug("registered")
    end

    def load(file, client)
      $log.debug("loading #{file} on #{client}")
      @client.publish("/#{client}/command", { :action => :load, :arg => file }.to_json)
    end

    def start(client, time)
      $log.debug("starting #{client}")
      @client.publish("/#{client}/command", { :action => :start, :arg => time }.to_json)
    end

    def play(client)
      $log.debug("sending play to #{client}")
      @client.publish("/#{client}/command", { :action => :play }.to_json)
    end

    def pause(client)
      $log.debug("sending pause to #{client}")
      @client.publish("/#{client}/command", { :action => :pause }.to_json)
    end

    def stop(client)
      $log.debug("stopping #{client}")
      @client.publish("/#{client}/command", { :action => :stop }.to_json)
    end

    def set_level(level, client)
      $log.debug("setting #{client} level to #{level}")
      @client.publish("/#{client}/command", { :action => :set_level, :arg => "#{level}" }.to_json)
    end

    def handle_state(client, message, scenario_handler)
      $log.debug (" ------------------ client \"#{client}\" sent message : #{message}")
      case message["state"]
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
