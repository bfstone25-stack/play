extends Control

@onready var prompt: Label = $Prompt
@onready var note: Label = $Note
@onready var objective: Label = $Objective
@onready var vignette: ColorRect = $Vignette

var note_t := 0.0

func _ready() -> void:
	note.visible = false
	prompt.text = ""
	if OS.has_feature("web"):
		set_objective("点击画面锁定鼠标。WASD 移动，E 交互，F 手电。")

func set_prompt(t: String) -> void:
	prompt.text = t

func set_objective(t: String) -> void:
	objective.text = t

func show_note(t: String) -> void:
	note.text = t
	note.visible = true
	note_t = 8.0

func _process(delta: float) -> void:
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0:
			note.visible = false
	# Keep overlay thin so the 3D scene stays readable.
	vignette.color.a = 0.04
