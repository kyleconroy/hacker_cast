#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
require 'em-websocket'

module SignalDispatch
  @rx_sockets = Set.new


  def self.serve!
    EM.run do
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen do |handshake|
          case handshake.path
          when %r{/tx}
            ws.onmessage do |msg|
              puts "TX says: #{msg}"
              @rx_sockets.each { |client| client.send(msg) }
            end

          when %r{/rx}
            @rx_sockets << ws
          else
            puts "unknown socket path"
          end

          puts "WebSocket connection open #{ws.inspect}"
        end

        ws.onclose do
          puts "closed: #{ws.inspect}"
        end
      end
    end
  end
end

SignalDispatch.serve!
