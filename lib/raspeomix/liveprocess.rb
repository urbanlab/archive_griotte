#!/usr/bin/env ruby
#implements EM::Connection functions in order to control
#an external process

require 'eventmachine'

module EventMachine

 # OMX_REGEXP = /.*[^\r]\n/
  OMX_REGEXP = /duration.*/

  class LiveProcess < EM::Connection

    attr_reader :queue

    def initialize (i_queue, o_queue)
      @input_queue = i_queue
      @output_queue = o_queue
      input_check_loop
      @output_queue.push("omx,ready")
      @stopped = false
    end

    def receive_data data
      data.scan(OMX_REGEXP).each { |str| #log __method__,str
        @output_queue.push(str)
      }
    end

    def unbind
      @output_queue.push("omx,stopped")
      @stopped = true
    end

    def input_check_loop
      @input_queue.pop { |char|
        send_data(char)
        input_check_loop unless @stopped
      }
    end
  end

end
