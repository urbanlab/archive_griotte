#!/usr/bin/env ruby

require 'eventmachine'

def log *message
  p [Time.now, *message]
end

module EventMachine


  OMX_REGEXP = /.*[^\r]\n/

  class LiveProcess < EM::Connection

    attr_reader :queue

    def initialize (queue)
      @queue = queue
 #     log __method__, queue
    end

    def receive_data data
      data.scan(OMX_REGEXP).each { |str| #log __method__,str
                                   @queue.push(str)}
    end

    def unbind
#      log __method__
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
