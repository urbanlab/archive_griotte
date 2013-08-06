#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::ImageClient.new("192.168.1.48")
}
