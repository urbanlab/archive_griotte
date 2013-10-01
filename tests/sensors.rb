# coding: utf-8
require 'raspeomix'

p = Raspeomix::Client::AnalogSensorsClient::SensorProfile.new("OutputInVolts", :conversion_formula => "x 2 *", :units => "µV", :description => "Doubles sensor values")
#puts p.inspect
#puts p.name

s = Raspeomix::Client::AnalogSensorsClient::Sensor.new(:an0, p, 50, :'12bits')
#puts s.inspect
a = Raspeomix::Client::AnalogSensorsClient.new(s)
#puts a.inspect

EM.run {
  Raspeomix.logger.info "Polling sensors"
  a.start
}
