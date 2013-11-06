require 'eventmachine'
require 'faye'

class Putsclient

  def initialize
    c = Faye::Client.new("http://192.168.1.48:#{ENV['RASP_PORT']}/faye")
    c.subscribe("/video/command") do |m| 
      puts "message : #{m}" 
    end
  end

end

EM.run {
  testclient = Putsclient.new
}
