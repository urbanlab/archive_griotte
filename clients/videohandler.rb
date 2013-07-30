#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Video.new(Raspeomix::VideoHandlerOMX.new)
}

#old

##!/usr/bin/env ruby
#
#require 'eventmachine'
#require 'faye'
#
##run client
#puts "starting video player client"
#player = VideoHandler.new
#EM.run {
#  client = Faye::Client.new("http://192.168.0.103:9292/faye")
#
#  client.subscribe('/foo') do |message|
#    puts message.inspect
#  end
#}
