#!/usr/bin/ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Heartbeat.new
}
