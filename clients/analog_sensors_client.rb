# coding: utf-8

require 'raspeomix'

include Raspeomix::Client

p = AnalogSensorsClient::SensorProfile.new("Maxbotix EZ-1", 
                                           :conversion_formula => "x 260.1 *", 
                                           :units => "cm", 
                                           :description => "Distance in cm")

s = AnalogSensorsClient::Sensor.new(:an0, p, 3, :'12bits')
a = AnalogSensorsClient.new(s)

EM.run {
  Raspeomix.logger.info("analog_sensors_client") { "Analog sensors client started" }
  a.start
}
