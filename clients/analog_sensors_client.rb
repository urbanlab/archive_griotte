# coding: utf-8

require 'raspeomix'

p = Raspeomix::Client::AnalogSensorsClient::SensorProfile.new("Maxbotix EZ-1", :conversion_formula => "x 260.1 *", :units => "cm", :description => "Distance in cm")
#p = Raspeomix::Client::AnalogSensorsClient::SensorProfile.new("Maxbotix EZ-1", :conversion_formula => "x 0.003858 /", :units => "cm", :description => "Distance in cm")

s = Raspeomix::Client::AnalogSensorsClient::Sensor.new(:an0, p, 3, :'12bits')
a = Raspeomix::Client::AnalogSensorsClient.new(s)

EM.run {
  Raspeomix.logger.info "Polling sensors"
  a.start
}
