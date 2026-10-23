extends Node2D
var elapsed := 0.0
var happy := false
var character_position := Vector2(1070, 360)
var character_scale := 1.0
var show_character := true

func _process(delta: float) -> void:
	if not Aura.reduced_motion:
		elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 800), Color("ebe6ee"))
	draw_circle(Vector2(1080, 120), 72, Color("f8f0d8"))
	draw_circle(Vector2(1102, 103), 64, Color("ebe6ee"))
	for i in range(30):
		var pos := Vector2(fmod(i * 139.0 + 63, 1280), fmod(i * 71.0, 340) + 20)
		var alpha := 0.3 + 0.2 * sin(elapsed + i)
		draw_circle(pos, 1.5, Color(0.65, 0.53, 0.34, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(0,600),Vector2(180,320),Vector2(390,590),Vector2(680,290),Vector2(990,580),Vector2(1130,350),Vector2(1280,570),Vector2(1280,800),Vector2(0,800)]), Color("d9d5e3"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,700),Vector2(260,485),Vector2(530,680),Vector2(890,490),Vector2(1280,650),Vector2(1280,800),Vector2(0,800)]), Color("c7cbd0"))
	for i in range(16):
		var x := float(i * 89 - 25)
		var y := 700.0 + sin(i * 2.0) * 45.0
		draw_line(Vector2(x,y),Vector2(x,800),Color("a5b2ae"),4)
		draw_colored_polygon(PackedVector2Array([Vector2(x,y-90),Vector2(x-30,y+40),Vector2(x+30,y+40)]),Color("b1beb5"))
	for i in range(44):
		var x := float(i * 31)
		var y := 773.0 + sin(i * 2.3) * 18.0
		draw_line(Vector2(x,y+12),Vector2(x,y),Color("879e91"),1)
		draw_circle(Vector2(x,y),3.5,Color("f6e7c1") if i%2==0 else Color("b9a4c4"))
	if show_character:
		draw_set_transform(character_position + Vector2(0, sin(elapsed * 1.8) * 3), 0, Vector2.ONE * character_scale)
		_draw_mage()
		draw_set_transform(Vector2.ZERO)

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
