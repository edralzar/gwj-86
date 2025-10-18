extends Node2D

@onready var r: RhythmNotifier = $RhythmNotifier
@onready var instructions: RichTextLabel = $Panel/Instructions
@onready var progress: Label = $Panel/ProgressLabel
@onready var synth: SamplerInstrument2D = $Sampler2D
@onready var beatsPerAttempt := notes.size() + responses.size()

@export var notes: Array[String] = ["D", "E", "G", "B"]
@export var responses: Array[String] = ["D", "G", "D", "G"]
@export var max_attempts: int = 12
@export var gracePeriod: float = 0.3

var playerMarkers: Array[NoteMarker]

var pTween: Tween
var oTween: Tween
var tweenBeat: float
var attempt: int
var playerTurn: bool
var playerBeat: int
var otherBeat: int
var stop
var beatsPlayed: Dictionary
var score
var beatMs: float
var win: int

func _ready() -> void:
	playerMarkers = [
		$Panel/Line2D/NoteMarker1,
		$Panel/Line2D/NoteMarker2,
		$Panel/Line2D/NoteMarker3,
		$Panel/Line2D/NoteMarker4
	]
	progress.text = ""
	instructions.text = instructions.text.replace("{ATTEMPTS}", str(max_attempts))
	instructions.text = instructions.text.replace("{CHALLENGE}", str(notes.size()))
	instructions.text = instructions.text.replace("{RESPONSES}", str(responses.size()))

func _start():
	beatMs = r.beat_length
	score = 0
	win = -1
	attempt = -1
	playerTurn = false
	playerBeat = -1
	otherBeat = -1
	beatsPlayed = {}
	stop = false
	r.beats(1).connect(_beat)
	$AudioStreamPlayer.play()
	r.running = true
	$Panel/Line2D.visible = true
	$Panel/StartButton.visible = false
	$Panel/Instructions.visible = false

func _stop():
	stop = true
	r.running = false
	if oTween: oTween.stop()
	if pTween: pTween.stop()
	$Player/Sprite2D.scale = Vector2.ONE
	$Other/Sprite2D.scale = Vector2.ONE
	$AudioStreamPlayer.stop()
	await get_tree().create_timer(beatMs / 2).timeout
	
	for n in playerMarkers:
		n.newAttempt()
	$Panel/StartButton.text = "Try Again"
	$Panel/StartButton.visible = true
	$Panel/Line2D.visible = false
	if (win > 0):
		progress.text = "Congrats! You found the correct response %s in %s attempts" %[responses, win]
	else:
		progress.text = "=GAME OVER="

func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("ui_cancel")):
		_stop()
	var beat = r.current_beat % beatsPerAttempt
	# Don't play note if not player's turn (or close to player's turn)
	if (stop or beat < notes.size()-1):
		return
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
	
	var curBeat = str(attempt, "-", beat)
	#print("Played %s at beat %s" % [note, curBeat])
	beatsPlayed[curBeat] = note
	synth.play_note(note, 3)

func _judge(beat: int):
	var curBeat = str(attempt, "-", beat)
	#print("Judging %s => player beat %s" % [curBeat, playerBeat])
	var marker = playerMarkers[playerBeat]
	marker.indicateBeat()
	var played = beatsPlayed.get(curBeat)
	if not played:
		await get_tree().create_timer(gracePeriod).timeout
		played = beatsPlayed.get(curBeat)
	if not played:
		marker.markJudged(0)
	elif played == responses[beat - notes.size()]:
		marker.markJudged(3, played)
		score += 1
		if (score == notes.size()): 
			stop = true
			win = attempt+1
	else:
		marker.markJudged(1, played)

func _beat(count: int):
		# Tracking every beat -> attempt -> playerBeat vs otherBeat
		var beat = count % beatsPerAttempt
		playerTurn = beat >= notes.size()
		playerBeat = beat - notes.size() if playerTurn else -1
		otherBeat = beat if not playerTurn else -1
		if (beat == 0):
			print("beat 0 attempt %s" % attempt)
			attempt += 1
			score = 0
		if stop:
			#Extraneous beat, ensuring cleanup
			_stop()
			return
		
		# Debug / Progress
		if (attempt < max_attempts): progress.text = "ATTEMPT %d / %d" % [attempt + 1, max_attempts]
		#print("beat %s in attempt %s [total beats %s]" % [beat, attempt, count])
		
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
			synth.play_note(notes[beat], 4)
			if (playerMarkers[otherBeat]):
				playerMarkers[otherBeat].newAttempt()
		else:
			$PlayingListener2D.make_current()
			_judge(beat)
