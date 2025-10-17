extends Node2D

@onready var r: RhythmNotifier = $RhythmNotifier
@onready var progress: Label = $ProgressLabel
@onready var judge: Label = $JudgeLabel
@onready var synth: SamplerInstrument2D = $Sampler2D
@onready var beatsPerAttempt := notes.size() + responses.size()

@export var notes: Array[String] = ["D", "E", "G", "B"]
@export var responses: Array[String] = ["D", "D", "D", "D"]
@export var max_attempts: int = 2

var playerMarkers: Array[NoteMarker]

var pTween: Tween
var oTween: Tween
var tweenBeat: float
var attempt: int = 0
var playerTurn: bool = false
var playerBeat: int = -1
var otherBeat: int = -1
var stop := false
var beatsPlayed: Dictionary = {}
var score := 0

func _ready() -> void:
	var beatMs := r.beat_length
	playerMarkers = [
		$ProgressLabel/NoteMarker1,
		$ProgressLabel/NoteMarker2,
		$ProgressLabel/NoteMarker3,
		$ProgressLabel/NoteMarker4
	]
	
	r.beats(1).connect(func(count):
		# Tracking every beat -> attempt -> playerBeat vs otherBeat
		var beat = count % beatsPerAttempt
		playerTurn = beat >= notes.size()
		playerBeat = beat - notes.size() if playerTurn else -1
		otherBeat = beat if not playerTurn else -1
		if (beat == 0 && score < notes.size()):
			attempt += 1
			score = 0
			for n in playerMarkers:
				n.newAttempt()
		if stop:
			#Extraneous beat, ensuring cleanup
			_stop()
			return
		
		# Debug / Progress
		progress.text = "ATTEMPT %d / %d" % [attempt + 1, max_attempts]
		print("beat %s in attempt %s [total beats %s]" % [beat, attempt, count])
		
		# General animation
		# Start tweening
		if (playerBeat == 0):
			pTween = get_tree().create_tween().set_loops(responses.size() - 1)
			pTween.tween_property($Player/Sprite2D, "scale", Vector2(0.8, 0.8), beatMs * 0.75)
			pTween.tween_property($Player/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
		elif (otherBeat == 0):
			oTween = get_tree().create_tween().set_loops(notes.size() - 1)
			oTween.tween_property($Other/Sprite2D, "scale", Vector2(0.9, 0.9), beatMs * 0.75)
			oTween.tween_property($Other/Sprite2D, "scale", Vector2(1.0, 1.0), beatMs * 0.25)
		if (beat == 0 and (attempt == max_attempts or score == notes.size())):
			_stop()
			return
		
		# Positional Audio and Judging
		if (not playerTurn):
			$ListeningListener2D.make_current()
			playerMarkers.all(func(m: NoteMarker): m.newAttempt())
			synth.play_note(notes[beat], 4)
		else:
			$PlayingListener2D.make_current()
			_judge(beat)
	)
	$AudioStreamPlayer.play()
	r.running = true

func _stop():
	stop = true
	var beatMs = r.beat_length
	r.running = false
	oTween.stop()
	pTween.stop()
	$Player/Sprite2D.scale = Vector2.ONE
	$Other/Sprite2D.scale = Vector2.ONE
	$AudioStreamPlayer.stop()
	await get_tree().create_timer(beatMs / 2).timeout
	judge.text = ""
	progress.text = "Congrats!" if score == notes.size() else "=GAME OVER="
	for n in playerMarkers:
		n.newAttempt()

func _process(_delta: float) -> void:
	if stop: return
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
	var beat = r.current_beat % beatsPerAttempt
	var curBeat = str(attempt, "-", beat)
	print("Played %s at beat %s" % [note, curBeat])
	beatsPlayed[curBeat] = note
	synth.play_note(note, 3)

func _judge(beat: int):
	var curBeat = str(attempt, "-", beat)
	var debugMsg = "Judging %s => player beat %s" % [curBeat, playerBeat]
	print(debugMsg)
	await get_tree().create_timer(0.2).timeout
	var played = beatsPlayed.get(curBeat)
	var marker = playerMarkers[playerBeat]
	if not played:
		judge.text = "MISS %s" % debugMsg
		marker.markJudged(0)
	elif played == responses[beat - notes.size()]:
		judge.text = "GREAT %s" % debugMsg
		marker.markJudged(3, played)
		score += 1
		if (score == notes.size()): stop = true
	else:
		judge.text = "WRONG %s" % debugMsg
		marker.markJudged(1, played)
