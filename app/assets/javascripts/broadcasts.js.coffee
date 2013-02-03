# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# Clean up interfaces
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia
RTCPeerConnection = webkitRTCPeerConnection

class Room
  constructor: ->
    @room_id = $('meta[name=room_key]').attr('content')

#TODO this is puesdo

#Using google's ICE server.
PEER_CONNECTION_CONF = {"iceServers": [{"url": "stun:stun.l.google.com:19302"}]}


class Caller
  constructor: ->
    @client_id = Math.floor(Math.random() * 10000000000 ) + ''
    @peer_connection = new RTCPeerConnection(PEER_CONNECTION_CONF)
    @peer_connection.onicecandidate = @ice_callback
    @socket = new WebSocket("ws://localhost:8080/tx/#{window.Room.room_id}/#{@client_id}")
    @socket.onmessage = (msg) =>
      data = JSON.parse(msg.data)
      switch data.type
        when 'client_waiting'
          @to_client_id = data.client_id
          @send_video()
        when 'answer'
          console.log(data)
          console.log(@peer_connection.locaStreams)
          @peer_connection.setRemoteDescription(new RTCSessionDescription(data), ((success_callback)=> console.log(@peer_connection.localStreams[0])), ((err_msg)-> console.log("error setting remote sdp for caller: #{err_msg}")))


  attach_stream_to_view: (stream) ->
    video_out = document.querySelector('#preview')
    console.log(stream)
    video_out.src = window.URL.createObjectURL(stream)

  send_video: ->
    navigator.getUserMedia({audio: true, video: true}, ((stream) =>
      @media_stream = stream
      @peer_connection.addStream(stream)
      @attach_stream_to_view(stream)
      @peer_connection.createOffer(((sdp) =>
        console.log("Generated sdp: #{sdp.sdp}")
        @peer_connection.setLocalDescription(sdp)
        sdp.to = @to_client_id
        sdp.from = @client_id
        @socket.send(JSON.stringify(sdp))
      ), ((failure_msg) ->
        console.log("Failed to setLocalDescription: #{failure_msg}")
      ))), (failure_msg) ->
        console.log("Failed to getUserMedia: #{failure_msg}"))

class Callee
  constructor: ->
    @client_id = Math.floor(Math.random() * 10000000000 ) + ''
    @peer_connection = new webkitRTCPeerConnection(PEER_CONNECTION_CONF)
    @peer_connection.onaddstream = (stream)=>
      console.log('now')
      video_el = document.querySelector('#viewer')
      video_el.src = webkitURL.createObjectURL(stream.stream)
    @socket = new WebSocket("ws://localhost:8080/tx/#{window.Room.room_id}/#{@client_id}")
    @socket.onopen = ->
      console.log("Callee connected to signal socket")
    @socket.onmessage = (msg) =>
      parsed = JSON.parse(msg.data)
      @to_client_id = parsed.from
      console.log("recieved: #{parsed}")
      if parsed.type == 'offer'
        @recv_remote_sdp(parsed)
      else
        console.log("trashing msg: #{parsed}")

  recv_remote_sdp: (signal) =>
    @peer_connection.setRemoteDescription(new RTCSessionDescription(signal), ((event) =>
      @peer_connection.createAnswer((answer_sdp) =>
        answer_sdp.from = @client_id
        answer_sdp.to   = @to_client_id
        @peer_connection.setLocalDescription(answer_sdp)
        myjson = JSON.stringify(answer_sdp)
        console.log("answering with: #{myjson}")
        @socket.send(myjson))),
        ((failure) ->
          console.log("Setting Local SDP from remote failed: #{failure}")
        ))


class HackerCast
  init: ->
    window.Room = new Room
    #window.Caller = new Caller
    #window.Callee = new Callee
  init_caller: ->
    window.Caller = new Caller

  init_callee: ->
    window.Callee = new Callee


$ ->
  window.HC = new HackerCast
  window.HC.init()
