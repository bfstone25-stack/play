extends RefCounted
class_name Cjk

const FACE := preload("res://fonts/DroidSansFallback.ttf")

static func apply_label(l: Label) -> void:
	l.add_theme_font_override("font", FACE)

static func apply_3d(l: Label3D) -> void:
	l.font = FACE
