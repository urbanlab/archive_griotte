#!/usr/bin/env ruby

require 'eventmachine'

def log *message
  p [Time.now, *message]
end

module EventMachine


  OMX_REGEXP = /.*[^\r]\n/

  class LiveProcess < EM::Connection

    attr_reader :queue

    def initialize (i_queue, o_queue)
      @input_queue = i_queue
      @output_queue = o_queue
      input_check_loop
    end

    def receive_data data
      data.scan(OMX_REGEXP).each { |str| #log __method__,str
                                   @output_queue.push(str)}
    end

    def unbind
    end

    def input_check_loop
      EM.add_periodic_timer(0.5) {
        @input_queue.pop { |char|
          send_data(char)
        }
      }
    end
  end

end

#testing
#EM.run {
#  q = EM::Queue.new
#  EM.popen ARGV[0], EM::LiveProcess, q
#  EM.add_periodic_timer(0.1) {
#    q.pop { |msg| puts msg }
#  }
#}
