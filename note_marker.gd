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
	$Label.text = ""
	$Label.label_settings = settings

func newAttempt():
	_reset()

func markJudged(score: int):
	score = score % 4
	if (score == 0):
		$Label.text = "Miss"
		settings.font_color = Color.RED
		$Polygon2D.color = Color.RED
	elif (score == 1):
		$Label.text = "WRONG"
		settings.font_color = Color.RED
		$Polygon2D.color = Color.RED
	elif (score == 2):
		$Label.text = "OK"
		settings.font_color = Color.BLUE
		$Polygon2D.color = Color.BLUE
	else:
		$Label.text = "GREAT"
		settings.font_color = Color.GREEN
		$Polygon2D.color = Color.GREEN
	tween = get_tree().create_tween()
	tween.set_loops(4)
	tween.tween_property(settings, "font_size", base_font_size + 10, beatSeconds / 4)
	tween.tween_property(settings, "font_size", base_font_size, beatSeconds / 2)
	
func _reset():
	$Polygon2D.color = Color.WHITE
	$Label.text = ""
	settings.font_color = Color.WHITE
	settings.font_size = base_font_size
	$Label.visible = true
	if (tween): tween.stop()
