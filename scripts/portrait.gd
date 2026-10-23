extends Node2D
var elapsed := 0.0
var happy := false
func _process(delta: float) -> void:
	if not Aura.reduced_motion: elapsed += delta
	queue_redraw()
func _draw() -> void:
	draw_set_transform(Vector2(0, sin(elapsed*1.8)*3))
	_draw_mage()
func _draw_mage() -> void:
	# Original vector elf mage; no external character images are used.
	draw_circle(Vector2(0,115),76,Color(0.44,0.37,0.5,0.08))
	var sway := sin(elapsed * 2.0) * 4.0
	draw_line(Vector2(-43,-25),Vector2(-65+sway,62),Color("dfdce5"),25)
	draw_line(Vector2(43,-25),Vector2(65-sway,62),Color("dfdce5"),25)
	draw_colored_polygon(PackedVector2Array([Vector2(-28,18),Vector2(28,18),Vector2(55,111),Vector2(-55,111)]),Color("f9f3e5"))
	draw_colored_polygon(PackedVector2Array([Vector2(-28,18),Vector2(0,42),Vector2(-20,101),Vector2(-55,111)]),Color("8e7d9c"))
	draw_colored_polygon(PackedVector2Array([Vector2(28,18),Vector2(0,42),Vector2(20,101),Vector2(55,111)]),Color("8e7d9c"))
	draw_line(Vector2(-18,110),Vector2(-20,132),Color("5b4e62"),13)
	draw_line(Vector2(18,110),Vector2(20,132),Color("5b4e62"),13)
	draw_line(Vector2(-29,35),Vector2(-50,69),Color("f4e7db"),14)
	draw_line(Vector2(29,35),Vector2(63,52 if happy else 69),Color("f4e7db"),14)
	draw_line(Vector2(76,130),Vector2(76,-57),Color("a78450"),5)
	draw_circle(Vector2(76,-65),16,Color("c5b5d8"))
	draw_circle(Vector2(76,-65),21,Color("ae8749"),false,2)
	draw_colored_polygon(PackedVector2Array([Vector2(-32,-27),Vector2(-66,-41),Vector2(-36,-7)]),Color("f3dfd3"))
	draw_colored_polygon(PackedVector2Array([Vector2(32,-27),Vector2(66,-41),Vector2(36,-7)]),Color("f3dfd3"))
	draw_circle(Vector2(0,-26),42,Color("e4e0e9"))
	draw_circle(Vector2(0,-20),33,Color("f6e5d8"))
	draw_colored_polygon(PackedVector2Array([Vector2(-35,-32),Vector2(-27,-62),Vector2(19,-64),Vector2(38,-33),Vector2(7,-40),Vector2(-5,-25),Vector2(-13,-42)]),Color("e4e0e9"))
	var blink := fmod(elapsed, 4.8) > 4.62
	if happy or blink:
		draw_arc(Vector2(-12,-17),6,PI,TAU,12,Color("4e655a"),2)
		draw_arc(Vector2(12,-17),6,PI,TAU,12,Color("4e655a"),2)
	else:
		draw_line(Vector2(-18,-18),Vector2(-7,-16),Color("68786c"),3)
		draw_line(Vector2(7,-16),Vector2(18,-18),Color("68786c"),3)
	if happy:
		draw_arc(Vector2(0,-7),7,0,PI,12,Color("ad7880"),2)
	else:
		draw_line(Vector2(-4,0),Vector2(4,0),Color("ad7880"),2)
	draw_circle(Vector2(0,34),6,Color("c5a35c"))
