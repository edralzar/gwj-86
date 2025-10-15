extends Node2D

# Set r.bpm and r.audio_stream_player in inspector
@onready var r: RhythmNotifier = $RhythmNotifier
@onready var l: Label = $Label

# The beats method signature is:
#
#   func beats(beat_count: float, repeating := true, start_beat := 0.0) -> Signal
#
# We'll use this below to create repeating signals that emit every `beat_count`
# beats, starting on `start_beat`, and non-repeating signals that emit when we reach
# `start_beat`.

func _ready() -> void:
	_play_some_music()
	r.audio_stream_player.play()

# Play music and emit lots of signals
func _play_some_music():
	# Print on beat 0, 4, 8, 12...
	r.beats(1).connect(func(count): l.text = "Hello from beat %d!" % (count * 4 / 4))
#
	## Print on beat 2, 5, 8, 11...
	#r.beats(3, true, 2).connect(func(count): print("Hello from beat %d!" % 2+(count * 3)))
#
	## Print anytime beat 8.5 is reached.  The first param is ignored when the second is `false`..
	#r.beats(0, false, 8.5).connect(func(_i): print("Hello from beat eight and a half!"))
#
	#r.audio_stream_player.play()  # Start signaling
	#r.audio_stream_player.seek(1.5)  # pausing/stopping/seeking all supported
#
	## Stop playback on beat 20
	#r.beats(0, false, 20).connect(func(_i): r.audio_stream_player.stop())
