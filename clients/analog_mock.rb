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
     @client.publish("/#{@hostname}/sensors/analog/an0", message.to_json)
   }
   EM.add_periodic_timer(10){
     @client.publish("/#{@hostname}/sensors/analog/an0", message2.to_json)
   }
   EM.add_timer(10){
     @client.publish("/#{@hostname}/sound", {:state=>:on, :level=>0}.to_json)
   }
   EM.add_timer(15){
     @client.publish("/#{@hostname}/sound", {:state=>:on, :level=>50}.to_json)
   }
   EM.add_timer(20){
     @client.publish("/#{@hostname}/webclient/out", {:command=>"pause"}.to_json)
   }
   EM.add_timer(25){
     @client.publish("/#{@hostname}/webclient/out", {:command=>"play"}.to_json)
   }
}
