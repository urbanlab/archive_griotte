#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Scheduler.new("192.168.1.48")
  client.play_scenario
}
