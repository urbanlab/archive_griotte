# coding: utf-8
require 'raspeomix'

# p = Raspeomix::Client::AnalogSensorsClient::SensorProfile.new("OutputInVolts", :conversion_formula => "x 2 *", :units => "µV", :description => "Doubles sensor values")
p = Raspeomix::Client::AnalogSensorsClient::SensorProfile.new("Maxbotix EZ-1", :conversion_formula => "x 12.7 512 /", :units => "cm", :description => "Distance in cm")
#puts p.inspect
#puts p.name

s = Raspeomix::Client::AnalogSensorsClient::Sensor.new(:an0, p, 3, :'12bits')
#puts s.inspect
a = Raspeomix::Client::AnalogSensorsClient.new(s)
#puts a.inspect

EM.run {
  Raspeomix.logger.info "Polling sensors"
  a.start
}
