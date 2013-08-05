#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::VideoClient.new("192.168.1.48")
}
