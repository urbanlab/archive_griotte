#!/usr/bin/env ruby

require 'raspeomix'

EM.run {
  client = Raspeomix::Scheduler.new("192.168.1.48")
  client.run_image_test
  EM.add_timer(10){
    client.run_video_test
  }
}
