require 'eventmachine'
require 'faye'
require 'json'

EM.run {
  client = Faye::Client.new('http://localhost:9292/faye')

  puts "Ready"

  client.subscribe('/b827eb4a2c0f/sound') do |message|
    puts message.inspect
  end

  EM.add_timer(5) {
    puts "Publishing"
    client.publish('/b827eb4a2c0f/sound', { :state => "on", :volume => 20 })
    puts "Publishing JSON"
    client.publish('/b827eb4a2c0f/sound', { :state => "on", :volume => 20 }.to_json)
  }
}
