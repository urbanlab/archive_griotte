#!/usr/bin/env ruby
#
#multimedia client for Raspéomix
#can be used to read images, sound and video

module Raspeomix

  module Client

    class Multimedia

      include FayeClient

      def initialize(type, handler)
        @properties = {:type => type, :state => :initializing, :out_level => 0 }
        start_client('localhost', 9292)
        in_register(type)
        register("/#{type}/handler")
        @handler = handler
      end

      def update_wrapped_state(state)
        $log.debug("wrapper sent state : #{state}")
        update_state(state)
      end

      def load(file)
        if @handler.load(file)
          update_state(:ready?)
        else
          $log.error("error while loading #{file} to #{self.name} client")
          update_state(:error)
        end
      end

      def start(time)
        if @handler.start(time)
          update_state(:playing?)
        else
          $log.error("error while starting #{self.name} client")
          update_state(:error)
        end
      end

      def pause
        if @handler.pause
          update_state(:paused?)
        else
          $log.error("error while pausing #{self.name} client")
          update_state(:error)
        end
      end

      def play
        if @handler.play
          update_state(:playing?)
        else
          $log.error("error while unpausing #{self.name} client")
          update_state(:error)
        end
      end

      def stop
        if @handler.stop
          update_state(:idle?)
        else
          $log.error("error while stopping #{self.name} client")
          update_state(:error)
        end
      end

      def set_level(level)
        if @handler.set_level(level)
          update_level(level+"?")
        else
          $log.error("error while setting #{self.name} client level to #{level}")
          update_state(:error)
        end
      end

      def in_register(type)
        register("/#{type}/in")
        update_state(:idle)
      end

      def register(path)
        $log.debug("subscribing to #{path}")
        subscribe(path) { |message| receive_message(message) }
      end

      def receive_message(message)
        $log.debug("message received : #{message}")
        parsed_msg = JSON.parse(message, :symbolize_names => true)
        if parsed_msg[:type] == "command"
          if method(parsed_msg[:action]).arity != 0
            self.send(parsed_msg[:action], parsed_msg[:arg])
          else
            self.send(parsed_msg[:action])
          end
        elsif parsed_msg[:type] == "sdl_state"
          update_handled_state(parsed_msg[:state])
        elsif parsed_msg[:type] == "omx_state"
          update_handled_state(parsed_msg[:state])
        else
          $log.error("message type #{parsed_msg[:type]} not recognized, message is : #{parsed_msg}")
        end
      end

      def update_handled_state(state)
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
        publish_property(property_type, property)
        $log.debug("#{property_type} changed to #{property}")
      end

      def publish_property(property_type, property)
        publish("/#{@properties[:type]}/out", { :type => :property_update, property_type => property }.to_json)
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
