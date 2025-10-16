extends Node2D

@onready var r: RhythmNotifier = $RhythmNotifier
@onready var guide: Label = $GuideLabel
@onready var progress: Label = $ProgressLabel
@onready var judge: Label = $JudgeLabel
@onready var synth: SamplerInstrument2D = $Sampler2D
@onready var beatsPerAttempt := notes.size() + responses.size()

@export var notes : Array[String] = ["D", "E", "G", "B"]
@export var responses : Array[String] = [ "D", "D", "D", "D"]
@export var max_attempts : int = 2

var pTween: Tween
var oTween: Tween
var jTween: Tween
var tweenBeat: float
var attempt: int = 0
var playerTurn: bool = false
var stop := false
var lastBeatPlayed: String = ""
var lastNotePlayed: String = ""

func _ready() -> void:
	var beatMs := r.beat_length
	r.beats(1).connect(func(count): # General animation and tracking of attempts
		var beat = count % beatsPerAttempt
		if stop:
			#Extraneous beat, ensuring cleanup
			judge.text = ""
			guide.text = "The End"
			return
		if (beat == 0):
			attempt += 1
			if (attempt == max_attempts):
				# Mark stopped and stop tweening
				r.running = false
				stop = true
				oTween.stop()
				pTween.stop()
				jTween.stop()
				$Player/Sprite2D.scale = Vector2.ONE
				$Other/Sprite2D.scale = Vector2.ONE
				await get_tree().create_timer(beatMs / 2).timeout
				if (r.audio_stream_player): r.audio_stream_player.stop()
				judge.text = ""
				guide.text = "The End"
			else:
				# Start tweening
				pTween = get_tree().create_tween().set_loops(4)
				pTween.tween_property($Player/Sprite2D, "scale", Vector2(0.8 , 0.8), beatMs * 0.75)
				pTween.tween_property($Player/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
				oTween = get_tree().create_tween().set_loops(4)
				oTween.tween_property($Other/Sprite2D, "scale", Vector2(0.9 , 0.9), beatMs * 0.75)
				oTween.tween_property($Other/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
		print("beat %s in attempt %s [total beats %s]" % [beat, attempt, count])
	)
	r.beats(1).connect(func(count):
		var beat = count % beatsPerAttempt
		playerTurn = beat >= notes.size()
		progress.text = "ATTEMPT %d / %d" % [attempt+1, max_attempts]
		if (not playerTurn):
			$ListeningListener2D.make_current()
			judge.text = "..."
			guide.text = "Listen..." if (attempt == 0) else "Listen again..."
			synth.play_note(notes[beat], 4)
		else:
			$PlayingListener2D.make_current()
			guide.text = "GO !"
	)
	#r.audio_stream_player.play()
	r.running = true

func _process(delta: float) -> void:
	var note = null
	if (Input.is_action_just_pressed("Note1")):
		note = "D"
	elif (Input.is_action_just_pressed("Note2")):
		note = "B"
	elif (Input.is_action_just_pressed("Note3")):
		note = "G"
	elif (Input.is_action_just_pressed("Note4")):
		note = "E"
		
	if (not note):
		return
	var beat =  r.current_beat % beatsPerAttempt
	if (beat < notes.size()):
		return
	var curBeat = str(attempt, "-", beat)
	lastBeatPlayed = curBeat
	print("Played %s at beat %s" % [note, curBeat])
	lastNotePlayed = note
	synth.play_note(note, 3)
	_judge(beat)
	#TODO send the note to the judgeddaddadaadad

func _judge(beat: int):
	if not playerTurn: return
	var curBeat = str(attempt, "-", beat)
	print("Judging %s" % curBeat)
	if (lastBeatPlayed == curBeat and lastNotePlayed == responses[beat - notes.size()]):
		judge.text = "GREAT"
	else:
		judge.text = "WRONG"
	var beatMs := r.beat_length
	jTween = get_tree().create_tween()
	jTween.tween_property(judge.label_settings, "font_size", 18, beatMs / 2)
	jTween.tween_property(judge.label_settings, "font_size", 24, beatMs /2)
