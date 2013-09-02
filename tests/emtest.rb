require 'eventmachine'

class OMXTest

  def receive_data data
    puts "received #{data}"
  end
end

EM.run {
  EM.popen("ls") { |data| puts data.each { |line| puts line}}
}
