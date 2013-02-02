#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
require 'em-websocket'

module WebsocketServer
  def self.serve!
    EM.run do
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen do
          case ws.request['path']
          when %r{/view}
            if(stream = App.streams[ws.request["query"]["stream_id"]])
              stream.channel.subscribe{ |msg| ws.send(msg) }
            else
              puts "socket not found"
            end

          when %r{/send}
            if(stream = App.streams[ws.request["query"]["stream_id"]])
              ws.onmessage do |msg|
                stream.channel.push(msg)
              end
              ws.send("you're a sender")
            else
              puts "send socket not found"
            end

          else
            log_info "unknown socket path"
          end

          log_info "WebSocket connection open #{ws.inspect}"
        end

        # ws.onclose { log_info "Connection closed" }
        # ws.onmessage { |msg|
        #   log_info "Recieved message: #{msg}"
        # }

      end
    end

  end
end

WebsocketServer.serve!
