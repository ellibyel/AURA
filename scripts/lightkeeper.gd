extends "res://scripts/animated_scene.gd"
# The lightkeeper is drawn frame by frame (assets/art/lightkeeper/*) and
# animated in lightkeeper.tscn: "idle" / "happy" / "sad" / "surprised" frames,
# a "float" track and a "pop" squash played when the player taps her.
const EMOTIONS := ["happy", "sad", "surprised", "idle"]
var emotion := "idle"
var happy := false:
	set(value):
		happy = value
		if is_node_ready(): set_emotion("happy" if happy else "idle")

func _ready() -> void:
	set_emotion("happy" if happy else "idle")
	super()

func set_emotion(name: String) -> void:
	emotion = name
	$Body.play(name)

# Main menu: each tap shows the next emotion with a small bounce.
func next_emotion() -> void:
	set_emotion(EMOTIONS[(EMOTIONS.find(emotion) + 1) % EMOTIONS.size()])
	if not Aura.reduced_motion: $React.play("pop")
	Aura.sound("rotate")
	Aura.haptic(15)
