#!/usr/bin/env ruby
#
require 'raspeomix'
require 'faye'
require 'eventmachine'
require 'json'
EM.run {
  @hostname=`hostname`.chomp
  @client=Faye::Client.new("http://localhost:9292/faye")

  message = { :type => :analog_value,
              :analog_value => {
                :converted_value => 210
              }
            }
  message2 = { :type => :analog_value,
              :analog_value => {
                :converted_value => 100
              }
            }

  EM.add_periodic_timer(1){
    @client.publish("/#{@hostname}/sensor/analog/an0", message.to_json)
  }
  EM.add_periodic_timer(10){
    @client.publish("/#{@hostname}/sensor/analog/an0", message2.to_json)
  }
}
