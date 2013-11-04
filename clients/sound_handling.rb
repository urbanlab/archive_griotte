#!/usr/bin/env ruby
#
require 'raspeomix'
require 'faye'
require 'eventmachine'
require 'json'
EM.run {
  @hostname=`hostname`.chomp
  @client=Faye::Client.new("http://localhost:9292/faye")

  @message = {"type"=>"set_level","level"=>0}

  def send_message
    @client.publish("/#{@hostname}/sound", @message)
    Raspeomix.logger.debug("sending message : #{@message}")
  end

  EM.add_periodic_timer(3) {
    @message["level"]=(rand(10)+1)*10
    send_message 
  }

#  EM.add_periodic_timer(0.5) {
#    gets.chomp { |i|
#      puts "sending level : #{i}"
#      @message["level"]=i
#      send_message
#    }
#  }
}
