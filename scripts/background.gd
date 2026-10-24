extends "res://scripts/animated_scene.gd"
# Covers the whole screen, including the extra side area on wide phones.

func _ready() -> void:
	Aura.layout_changed.connect(_fit)
	_fit()
	super()

func _fit() -> void:
	var cover := (Aura.DESIGN.x + Aura.margin_x * 2.0) / Aura.DESIGN.x
	scale = Vector2.ONE * cover
	position = Vector2(-Aura.margin_x, (Aura.DESIGN.y - Aura.DESIGN.y * cover) / 2.0)
