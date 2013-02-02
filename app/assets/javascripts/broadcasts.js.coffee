# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/





navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia


class Transmitter

  transmit_controller_selector = '#transmit_container'

  constructor: ->

  on_failure: (fail_msg) ->
    console.log fail_msg

  on_success: (localMediaStream) ->
    window.stream = localMediaStream
    viewer = document.querySelector("video")
    viewer.src = window.URL.createObjectURL(localMediaStream)

  transmit: ->
    navigator.getUserMedia({audio: true, video: true}, this.on_success, this.on_failure)


window.transmitter = new Transmitter
