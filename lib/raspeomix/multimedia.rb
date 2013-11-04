#!/usr/bin/env ruby

require 'raspeomix/fayeclient'
#
#multimedia client for Raspéomix
#can be used to read images, sound and video

require 'eventmachine'
require 'faye'
require 'json'

module Raspeomix

  module Client

    class Multimedia

      include FayeClient

      def initialize(type, handler)
        @type = type
        @properties = {:client => @type, :state => :initializing, :volume => 0, :position => 0}
        start_client('localhost', 9292)
        in_register(type)
        register("/#{type}/handler")
        @handler = handler
      end

      def update_wrapped_state(state)
        Raspeomix.logger.debug("wrapper sent state : #{state}")
        update_state(state)
      end

      def send_char(char) # for testing purposes only
        @handler.send_char char
      end

      def load(args)
        file = args[0]
        if @handler.load(file)
          update_state(:ready?)
        else
          Raspeomix.logger.error("error while loading #{file} to #{self.name} client")
          update_state(:error)
        end
      end

      def start(args)
        time=args[0]
        level=to_db(args[1])
        Raspeomix.logger.debug("starting client, args : time : #{time}, level : #{level}")
        if @handler.start(time, level)
          update_state(:playing?)
        else
          Raspeomix.logger.error("error while starting #{self.name} client")
          update_state(:error)
        end
      end

      def pause
        if @handler.pause
          update_state(:paused?)
        else
          Raspeomix.logger.error("error while pausing #{self.name} client")
          update_state(:error)
        end
      end

      def play
        if @handler.play
          update_state(:playing?)
        else
          Raspeomix.logger.error("error while unpausing #{self.name} client")
          update_state(:error)
        end
      end

      def stop
        if @handler.stop
          update_state(:idle?)
        else
          Raspeomix.logger.error("error while stopping #{self.name} client")
          update_state(:error)
        end
      end

      def set_level(args)
        level = args[0]
        if @handler.set_level(level)
          #update_level(level+"?") TODO
        else
          Raspeomix.logger.error("error while setting #{self.name} client level to #{level}")
          update_state(:error)
        end
      end

      def in_register(type)
        register("/#{type}/in")
        update_state(:idle)
      end

      def register(path)
        Raspeomix.logger.debug("subscribing to #{path}")
        subscribe(path) { |message| receive_message(message) }
      end

      def receive_message(message)
        Raspeomix.logger.debug("message received : #{message}")
        if message["type"] == "command"
          if method(message["action"]).arity != 0
            self.send(message["action"], message["args"])
          else
            self.send(message["action"])
          end
        elsif message["type"] == "sdl_state"
          update_sdl(message["state"])
        elsif message["type"] == "omx_state"
          update_omx(message)
        else
          Raspeomix.logger.error("message type #{message["type"]} not recognized, message is : #{message.inspect}")
        end
      end

      def update_omx(message)
        case message["state"]["type"]
        when "info"
          #play /pause
          if message["state"]["state"]==0 
            @properties[:state]="paused"
          else
            @properties[:state]="playing"
          end
          #position
          @properties[:position] = message["state"]["pos"]
          #volume =  / muted
          @properties[:volume] = to_percent(message["state"]["volume"].to_i)
        when "raw_update"
          @properties = {:client => @type, :state => message["state"]["update"], :volume => 0, :position => 0}
        end
        publish_properties
        if @properties[:state]=="stopped"
          @properties[:state]="idle"
          publish_properties
        end
      end

      def to_db(vol)
        case vol
        when "muted"
          return -6000
        when 0..10
          return -4605
        when 10..20
          return -3218
        when 20..30
          return -2407
        when 30..40
          return -1832
        when 40..50
          return -1386
        when 50..60
          return -1021
        when 60..70
          return -713
        when 70..80
          return -446
        when 80..90
          return -210
        when 90..100
          return 0
        when 100..110
          return 190
        when 110..120
          return 364
        end
      end

      def to_percent(vol)
        case vol
        when -6000
          return "muted"
        when -4605
          return 10
        when -3218
          return 20
        when -2407
          return 30
        when -1832
          return 40
        when -1386
          return 50
        when -1021
          return 60
        when -713
          return 70
        when -446
          return 80
        when -210
          return 90
        when 0
          return 100
        when 190
          return 110
        when 364
          return 120
        end
      end

      def update_sdl(state)
        update_state(state)
      end

      def update_state(state)
        update_property(:state, state)
      end

      def update_out_level(level)
        update_property(:out_level, level)
      end

      def update_property(property_type, property)
        @properties[property_type] = property
        publish_properties
        Raspeomix.logger.debug("#{property_type} changed to #{property}")
      end

      def publish_properties
        publish("/#{@properties[:client]}/out", { :type => :client_update, :properties => @properties})
      end

    end

    class Video < Multimedia
      def initialize
        super(:video, OMXWrapper.new(:video, 'localhost', 9292))
      end
    end

    class Sound < Multimedia
      def initialize
        super(:sound, OMXWrapper.new(:sound, 'localhost', 9292))
      end
    end

    class Image < Multimedia
      def initialize
        super(:image, SDLWrapper.new('localhost', 9292))
      end
    end

  end
end
