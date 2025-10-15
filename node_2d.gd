extends Node2D

# Set r.bpm and r.audio_stream_player in inspector
@onready var r: RhythmNotifier = $RhythmNotifier
@onready var guide: Label = $GuidanceLabel
@onready var judge: Label = $JudgeLabel

@export var notes : Array[String] = ["C", "E", "G", "B"]
@onready var synth: Sampler = $Sampler

var pTween: Tween
var oTween: Tween
var tweenBeat: float
var challenge: int = 0
var stop := false

func _ready() -> void:
	var beatMs := r.beat_length
	r.beats(1).connect(func(count): 
		guide.text = "Go" if (count >= 4) else "Wait!"
		judge.text = "*"
		
		if (count == 7):
			challenge += 1
			print("Challenge %d" % challenge)
			if (challenge == 2):
				stop = true
				oTween.stop()
				pTween.stop()
				$Player/Sprite2D.scale = Vector2.ONE
				$Other/Sprite2D.scale = Vector2.ONE
				await get_tree().create_timer(beatMs / 2).timeout
				r.audio_stream_player.stop()
		elif stop:
			judge.text = ""
			guide.text = "The End"
	)
	r.beats(1, true, 4).connect(func(count): _judge())
	
	pTween = get_tree().create_tween().set_loops()
	pTween.tween_property($Player/Sprite2D, "scale", Vector2(0.8 , 0.8), beatMs * 0.75)
	pTween.tween_property($Player/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
	oTween = get_tree().create_tween().set_loops()
	oTween.tween_property($Other/Sprite2D, "scale", Vector2(0.9 , 0.9), beatMs * 0.75)
	oTween.tween_property($Other/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
	
	r.audio_stream_player.play()


func _judge():
	if (randf() > 0.75):
		synth.play_note("B", 4)
		judge.text = "WRONG"
	else:
		synth.play_note("B", 4)
		judge.text = "GREAT"
