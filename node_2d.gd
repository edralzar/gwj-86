extends Node2D

@onready var r: RhythmNotifier = $RhythmNotifier
@onready var guide: Label = $GuideLabel
@onready var progress: Label = $ProgressLabel
@onready var judge: Label = $JudgeLabel
@onready var synth: SamplerInstrument2D = $Sampler2D

@export var notes : Array[String] = ["C", "E", "G", "B"]
@export var responses : Array[String] = [ "D", "D", "D", "E"]
@export var max_attempts : int = 2

var pTween: Tween
var oTween: Tween
var tweenBeat: float
var attempt: int = 0
var playerTurn: bool = false
var stop := false

func _ready() -> void:
	var beatMs := r.beat_length
	r.beats(1).connect(func(count):
		playerTurn = count >= 4
		progress.text = "ATTEMPT %d / %d" % [attempt+1, max_attempts]
		if (not playerTurn):
			$ListeningListener2D.make_current()
			judge.text = ""
			guide.text = "Listen..." if (attempt == 0) else "Listen again..."
		else:
			$PlayingListener2D.make_current()
			guide.text = "GO !"
		
		if (!playerTurn && count < notes.size()):
			synth.play_note(notes[count], 4)
		
		if (count == 7):
			attempt += 1
			print("Attempt %d" % attempt)
			if (attempt == max_attempts):
				stop = true
				oTween.stop()
				pTween.stop()
				$Player/Sprite2D.scale = Vector2.ONE
				$Other/Sprite2D.scale = Vector2.ONE
				await get_tree().create_timer(beatMs / 2).timeout
				r.audio_stream_player.stop()
				judge.text = ""
				guide.text = "The End"
		elif stop:
			#Extraneous beat, ensuring cleanup
			judge.text = ""
			guide.text = "The End"
	)
	r.beats(1, true, 4).connect(_judge)
	
	pTween = get_tree().create_tween().set_loops()
	pTween.tween_property($Player/Sprite2D, "scale", Vector2(0.8 , 0.8), beatMs * 0.75)
	pTween.tween_property($Player/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
	oTween = get_tree().create_tween().set_loops()
	oTween.tween_property($Other/Sprite2D, "scale", Vector2(0.9 , 0.9), beatMs * 0.75)
	oTween.tween_property($Other/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
	
	r.audio_stream_player.play()


func _judge(count: int):
	count = count % 4 #sanitize
	#simulate user input for now
	var playerNote = "D" if (randf() > 0.75) else "E"
	synth.play_note(playerNote, 4)
	
	if (playerNote == responses[count]):
		judge.text = "GREAT"
	else:
		judge.text = "WRONG"
