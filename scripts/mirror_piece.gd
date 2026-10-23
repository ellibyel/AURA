extends "res://scripts/animated_scene.gd"

func set_selected(value: bool) -> void:
	if $Ring.visible == value: return
	$Ring.visible = value
	if value: $RingMotion.play("selected")
	else: $RingMotion.stop()
	_apply_motion()

func play_once(animation: String) -> void:
	if Aura.reduced_motion: return
	$Motion.play(animation)
	_apply_motion()
