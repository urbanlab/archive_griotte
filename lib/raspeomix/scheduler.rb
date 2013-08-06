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
      #mount key if not already mounted
      if Dir.entries("/media/external").size == 2 then
        %x{sudo mount /dev/sda /media/external}
      end
      register
    end

    def register
      $log.debug("registering...")
      @client = Faye::Client.new(@server_add)
      @client.subscribe("/video/status") { |status| handle_status(:video, status) }
      @client.subscribe("/image/status") { |status| handle_status(:image, status) }
      @client.subscribe("/captors/signal") { |signal| handle_captor_signal(signal) }
      $log.debug("registered")
    end

    def load(file, client)
      @client.publish("/#{client}/command", { :action => :load, :arg => file }.to_json)
      $log.debug("loading #{file} on #{client}")
    end

    def start(client)
      @client.publish("/#{client}/command", { :action => :start }.to_json)
      $log.debug("starting #{client}")
    end

    def play(client)
      @client.publish("/#{client}/command", { :action => :play }.to_json)
      $log.debug("sending play to #{client}")
    end

    def pause(client)
      @client.publish("/#{client}/command", { :action => :pause }.to_json)
      $log.debug("sending pause to #{client}")
    end

    def stop(client)
      @client.publish("/#{client}/command", { :action => :stop }.to_json)
      $log.debug("stopping #{client}")
    end

    def set_level(level, client)
      @client.publish("/#{client}/command", { :action => :set_level, :arg => "#{level}" }.to_json)
      $log.debug("setting #{client} level to #{level}")
    end

    def handle_status(client, status)
      #not implemented yet
    end

    def handle_captor_signal(signal)
      #not implemented yet
    end

    def finalize
      EM.stop_event_loop
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
