# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# Clean up interfaces
navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia
RTCPeerConnection = webkitRTCPeerConnection

class SignalChannel
  constructor: (@path) ->
    @socket = new WebSocket(@path)
    @socket.onopen = ->
      console.log("web socket opened")
    @socket.onmessage = (message) ->
      #console.log("Recieved: #{message.data}")
      #signal = JSON.parse(message.data)
      #HC.recv_signal(signal)

  send: (msg) ->
    @socket.send(msg)


#TODO this is puesdo

#Using google's ICE server.
PEER_CONNECTION_CONF = {"iceServers": [{"url": "stun:stun.l.google.com:19302"}]}

class Monitor
  constructor:
    @video_out = document.querySelector("video")

class Caller
  constructor: ->
    @peer_connection = new RTCPeerConnection(PEER_CONNECTION_CONF)
    @socket = new WebSocket("ws://localhost:8080/tx")


  attach_stream_to_view: (stream) ->
    video_out = document.querySelector('video')
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
        @socket.send(JSON.stringify(sdp))
      ), ((failure_msg) ->
        console.log("Failed to setLocalDescription: #{failure_msg}")
      ))), (failure_msg) ->
        console.log("Failed to getUserMedia: #{failure_msg}"))

window.Caller = new Caller



class Callee
  constructor: ->
    @peer_connection = new webkitRTCPeerConnection(PEER_CONNECTION_CONF)
    @socket = new WebSocket("ws://localhost:8080/rx")
    @socket.onopen = ->
      console.log("Callee connected to signal socket")
    @socket.onmessage = (msg) =>
      parsed = JSON.parse(msg.data)
      console.log("recieved: #{parsed}")
      if parsed.sdp
        @recv_remote_sdp(parsed)
      else
        console.log("trashing msg: #{parsed}")

  recv_remote_sdp: (signal) =>
    console.log("tetete")
    @peer_connection.setRemoteDescription(new RTCSessionDescription(signal), ((event) =>
      console.log 'event'
      console.log event
      @peer_connection.createAnswer((answer_sdp) =>
        console.log(answer_sdp)
        @peer_connection.setLocalDescription(answer_sdp)
        myjson = JSON.stringify(answer_sdp)
        console.log("answering with: #{myjson}")
        @socket.send(myjson))),
        ((failure) ->
          console.log("Setting Local SDP from remote failed: #{failure}")
        ))

window.Callee = new Callee

class HackerCast
  #init_rx: ->
    #@rx_chan = new SignalChannel("ws://localhost:8080/rx")

  #init_tx: ->
    #@tx_chan = new SignalChannel("ws://localhost:8080/tx")

  #got_desc: (desc) =>
    #console.log(desc)
    #@pc.setLocalDescription(desc)
    #@tx_chan.send_msg(JSON.stringify(desc))

  #got_remote_stream: (evt) ->
    #viewer = document.querySelector("video")
    #console.log("hehehe")
    #console.log(evt)
    #viewer.src = window.URL.createObjectURL(evt.stream)

  #got_ice_candidate: (evt) =>
    #@tx_chan.send_msg(JSON.stringify({ "candidate": evt.candidate }))

  #init_pc: ->
    #pc_config = {"iceServers": [{"url": "stun:stun.l.google.com:19302"}]}
    #@pc = new webkitRTCPeerConnection(pc_config)
    ##@pc.onicecandidate = @got_ice_candidate
    #@pc.onaddstream = @got_remote_stream


  #got_stream: (stream) =>
    #@local_stream = stream
    #viewer = document.querySelector("video")
    #viewer.src = window.URL.createObjectURL(stream)

    #@pc.addStream(stream)
    #@pc.createOffer(@got_desc)

  #failed_getting_stream: (err) ->
    #console.log("failed getting stream: #{err}")

  #send_vid: ->
    #navigator.getUserMedia({audio: true, video: true}, @got_stream, @failed_getting_stream)

  #set_local_and_send_message: (sesh) =>
    #@pc.setLocalDescription(sesh)
    #myjson = JSON.stringify(sesh)
    #console.log('john outbound sdp')
    #console.log(myjson)
    #@tx_chan.send_msg(myjson)

  #recv_succ: (evt) =>
    #@pc.createAnswer(@set_local_and_send_message)

  #recv_fail: (msg) ->
    #console.log("fail: #{msg}")

  #recv_signal: (signal) =>
    #console.log('recvd')
    #console.log(signal)
    #if signal.sdp
      #@pc.setRemoteDescription(new RTCSessionDescription(signal), @recv_succ, @recv_fail)
    #else
      ##@pc.addIceCandidate(new RTCIceCandidate(signal.candidate))


  init: ->
    window.Caller = new Caller
    window.Callee = new Callee

window.HC = new HackerCast
window.HC.init()
