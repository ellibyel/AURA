extends Node2D
# Root script for scenes whose animation is authored in the editor
# (AnimationPlayer tracks, AnimatedSprite2D frames, CPUParticles2D).
# The only code here pauses that animation when "Reduce animation" is on.

func _ready() -> void:
	Aura.motion_changed.connect(_apply_motion)
	_apply_motion()

func _apply_motion() -> void:
	Aura.apply_motion(self)
