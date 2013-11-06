#!/usr/bin/env ruby
#
require 'raspeomix'
require 'faye'
require 'eventmachine'
require 'json'
EM.run {
  @hostname=`hostname`.chomp
  @client=Faye::Client.new("http://localhost:#{ENV['RASP_PORT']}/faye")


  def send_random_vol
    message = {"type"=>"set_level","level"=>rand((10)+1)*10}
    @client.publish("/#{@hostname}/sound", message)
    Raspeomix.logger.debug("sending message : #{message}")
  end

  def send_mute
    message = {"type"=>"mute"}
    @client.publish("/#{@hostname}/sound", message)
    Raspeomix.logger.debug("sending message : #{message}")
  end

  EM.add_periodic_timer(3) {
    send_random_vol 
  }

  EM.add_periodic_timer(10) {
    send_mute
  }

}
