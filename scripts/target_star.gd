extends "res://scripts/animated_scene.gd"
var lit := false

func set_lit(value: bool) -> void:
	if value == lit: return
	lit = value
	$Dim.visible = not lit
	$Lit.visible = lit
	if not lit:
		$Motion.stop()
		$Lit.scale = Vector2.ONE * 0.5
		return
	if Aura.reduced_motion:
		$Motion.play("pulse")
	else:
		$Burst.restart()
		$Burst.emitting = true
		$Motion.play("light_up")
		$Motion.queue("pulse")
	_apply_motion()
