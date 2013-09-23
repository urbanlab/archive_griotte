require "eventmachine"

EM.run {
  EM.add_periodic_timer(2) {
  puts  " reading #{gets.chomp}"
  }
}
