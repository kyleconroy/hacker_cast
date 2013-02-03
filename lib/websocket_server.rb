#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'eventmachine'
require 'em-websocket'
require 'json'

module SignalDispatch
  @rooms = {}

  class Room
    attr_reader :root
    def initialize(root)
      @root = root
      @nodes = {root.client_id => root}
    end

    def append_child(node)
      @nodes[node.client_id] = node
      @root.append_child(node)
    end

    def find_node(client_id)
      @nodes[client_id] or raise "couldn't find the node: #{client_id}"
    end
  end

  class Node
    attr_accessor :children, :ws, :parent_ws
    attr_reader :client_id
    def initialize(ws, client_id)
      @ws = ws
      @client_id = client_id
      @children = Set.new
    end

    def append_child(node)
      if @children.any?
        @children.first.append_child(node)
      else
        @children << node
        self
      end
    end
  end

  def self.serve!
    EM.run do
      @rooms = {}
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
        ws.onopen do |handshake|
          md = handshake.path.match(%r{/tx/([^/]+)/(\d+)}) or raise "didn't get room_id: #{handshake.path}"
          room_id, client_id = md.captures

          child = Node.new(ws, client_id)
          if @room
            parent = @room.append_child(child)
            child.parent_ws = parent.ws
            parent.ws.send({type: 'client_waiting', client_id: child.client_id}.to_json)
          else
            # Become the broadcaster
            @room = Room.new(child)
          end
        end

        ws.onmessage do |json_msg|
          msg = JSON.parse(json_msg)

          puts "got websocket message:"
          puts msg.inspect
          case msg['type']
          when 'offer'
            from_node = @room.find_node(msg['from'])
            to_node = @room.find_node(msg['to'])
            to_node.ws.send(json_msg)
          when 'answer'
            to_node = @room.find_node(msg['to'])
            to_node.ws.send(json_msg)
          else
            raise "Unknown msg type #{msg.inspect}"
          end
        end

        ws.onclose do
          #closed
        end
      end
    end
  end
end

SignalDispatch.serve!
