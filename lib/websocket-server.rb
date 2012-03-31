require 'em-websocket'

EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8123) do |ws|
  ws.onopen { ws.send "Hello Client" }
  ws.onmessage { |msg| ws.send "Pong: #{msg}" }
  ws.onclose { puts "Websocket closed" }
end
