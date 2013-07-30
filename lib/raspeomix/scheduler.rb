#!/usr/bin/env ruby

require 'json'
require 'eventmachine'
require 'faye'

$log = Logger.new(STDOUT)
$log.level =Logger::DEBUG

module Raspeomix

  class Scheduler

    def initialize(server_ip="#{ARGV[0]}")
      @server_add = "http://#{server_ip}:9292/faye"
      $log.debug ("server address is : #{@server_add}")
      #mount key if not already mounted
      if Dir.entries("/media/external").size == 2 then
        $log.debug ("mounting key")
        %x{sudo mount /dev/sda /media/external}
      end
      $log.debug ("available files are : #{Dir.entries("/media/external")}")
    end

    def run_video_test_sequence
      EM.run {
        $log.debug ("creating client")
        client = Faye::Client.new(@server_add)
        $log.debug ("client created")

        $log.debug("sending load command")
        client.publish('/video/command', { :action => "load", :arg => "/media/external/videofinale.mp4"}.to_json)

        EM.add_timer(3){
          $log.debug ("sending start command")
          client.publish('/video/command', { :action => "start"}.to_json)
        }
        EM.add_timer(6){
          $log.debug ("sending change level command")
          client.publish('/video/command', { :action => "change_level", :arg => "0.1"}.to_json)
        }
        EM.add_timer(12){
          $log.debug ("sending stop command")
          client.publish('/video/command', { :action => "stop"}.to_json)
        }
        EM.add_timer(15){
          EM.stop_event_loop
        }
      }
    end
  end
end
