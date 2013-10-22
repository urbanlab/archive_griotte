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

      def load(file)
        if @handler.load(file)
          update_state(:ready?)
        else
          Raspeomix.logger.error("error while loading #{file} to #{self.name} client")
          update_state(:error)
        end
      end

      def start(time)
        if @handler.start(time)
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

      def set_level(level)
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
            self.send(message["action"], message["arg"])
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
          if message["state"]["muted"]==0
            @properties[:volume] = message["state"]["volume"]
          else
            @properties[:volume] = "muted"
          end
        when "raw_update"
          @properties = {:client => @type, :state => message["state"]["update"], :volume => 0, :position => 0}
        end
        publish_properties
        if @properties[:state]=="stopped"
          @properties[:state]="idle"
          publish_properties
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
