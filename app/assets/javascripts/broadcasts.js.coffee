# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/





navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia


class Transmitter

  transmit_controller_selector = '#transmit_container video'

  constructor: ->

  on_failure: (fail_msg) ->
    console.log fail_msg

  on_success: (localMediaStream) ->
    window.stream = localMediaStream
    viewer = document.querySelector(transmit_controller_selector)
    viewer.src = window.URL.createObjectURL(localMediaStream)

  transmit: ->
    navigator.getUserMedia({audio: true, video: true}, this.on_success, this.on_failure)

class Receiver
  receive_controller_selector = '#receive_container video'

  constructor: ->

  receive: (remote_stream) ->
    remote_viewer = document.querySelector(receive_controller_selector)
    remote_viewer.src = window.webkitURL.createObjectURL(remote_stream)


window.tx = new Transmitter
window.rx = new Receiver

