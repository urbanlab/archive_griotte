require 'raspeomix'

module Raspeomix
  module FayeClient
    def start(host='localhost', port='9292')
      @faye = Faye::Client.new("http://#{host}:#{port}/faye")
      publish('/system', { :sender => self.class, :msg => "starting" })
      @faye
    end

    def publish(channel, value)
      # The key must start with /
      channel[0] == '/' or raise ArgumentError

      faye.publish("/#{nick}#{channel}", value)
    end


    def subscribe(channel)
      channel[0] == '/' or raise ArgumentError

      faye.subscribe("/#{nick}#{channel}") do |message|
        yield message if block_given?
      end
    end

    def nick
      @nick ||= `hostname`.chomp
    end

    def faye
      @faye ||= start
    end
  end
end
