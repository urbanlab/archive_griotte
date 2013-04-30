#!/usr/bin/ruby

require 'eventmachine'
require 'faye'

me = ARGV[0] or `hostname`.chomp

EM.run {
  client = Faye::Client.new("http://#{ARGV[1]}:9292/faye")

  client.subscribe('/foo') do |message|
    puts message.inspect
  end

  EM.add_periodic_timer(2) {
    puts "Sending heartbeat"
    client.publish('/heartbeats', { :text => "alive", :origin => me } )
  }
}
