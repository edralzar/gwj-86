class_name NoteMarker
extends Node2D

@export var isPlayerNote := true
@export var beatSeconds: float = 1.0
@export var base_font_size: int = 24

var tween: Tween
var settings: LabelSettings

func _ready() -> void:
	if not isPlayerNote:
		$Polygon2D.visible = false
	settings = LabelSettings.new()
	settings.font_color = Color.WHITE
	settings.font_size = base_font_size
	$JudgeLabel.text = ""
	$JudgeLabel.label_settings = settings
	$NoteLabel.text = ""

func newAttempt():
	_reset()


func markJudged(score: int, note: String = ""):
	score = score % 4
	$NoteLabel.text = note
	if (score == 0):
		$JudgeLabel.text = "Miss"
		$NoteLabel.text = ""
		settings.font_color = Color.RED
		$Polygon2D.color = Color.RED
	elif (score == 1):
		$JudgeLabel.text = "WRONG"
		settings.font_color = Color.RED
		$Polygon2D.color = Color.RED
	elif (score == 2):
		$JudgeLabel.text = "OK"
		settings.font_color = Color.BLUE
		$Polygon2D.color = Color.BLUE
	else:
		$JudgeLabel.text = "GREAT"
		settings.font_color = Color.GREEN
		$Polygon2D.color = Color.GREEN
	tween = get_tree().create_tween()
	tween.set_loops(4)
	tween.tween_property(settings, "font_size", base_font_size + 10, beatSeconds / 4)
	tween.tween_property(settings, "font_size", base_font_size, beatSeconds / 2)
	
func _reset():
	$Polygon2D.color = Color.WHITE
	$JudgeLabel.text = ""
	$NoteLabel.text = ""
	settings.font_color = Color.WHITE
	settings.font_size = base_font_size
	$JudgeLabel.visible = true
	if (tween): tween.stop()
