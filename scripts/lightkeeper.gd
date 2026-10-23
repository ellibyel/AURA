extends "res://scripts/animated_scene.gd"
# The lightkeeper is drawn frame by frame (assets/art/lightkeeper/*) and
# animated in lightkeeper.tscn: "idle" / "happy" frames plus a "float" track.
var happy := false:
	set(value):
		if value == happy: return
		happy = value
		if is_node_ready(): $Body.play("happy" if happy else "idle")

func _ready() -> void:
	$Body.play("happy" if happy else "idle")
	super()
