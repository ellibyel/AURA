extends Node2D

const GRID_SIZE := 48
const GRID_WIDTH := 16
const GRID_HEIGHT := 9
const ORIGIN := Vector2(40, 192)
const MIRROR_HALF_LENGTH := 19.0
const RAY_MAX_BOUNCES := 64
const RAY_EPSILON := 0.05
@export var level_number := 1
var mirrors: Array[Dictionary] = []
var selected_mirror := -1
var light_source_pos := Vector2.ZERO
var target_stars: Array[Dictionary] = []
var stars_hit := 0
var level_data: Dictionary = {}
var ray_segments: Array[Dictionary] = []
var level_won := false
var blocked := false
var history: Array[Dictionary] = []
var hints_used := 0
var hint_index := 0
var tool := "mirror"
var ui: CanvasLayer
var scenery: Node2D
var particles: Array[Dictionary] = []
var elapsed := 0.0
var message := ""

func _ready() -> void:
	if level_number > Aura.unlocked:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
		return
	level_data = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level_%d.json" % maxi(1,level_number)))
	setup_level()
	scenery = load("res://scripts/scenery.gd").new()
	scenery.show_character = false
	add_child(scenery)
	move_child(scenery,0)
	scenery.show_behind_parent = true
	ui = load("res://scripts/game_ui.gd").new()
	add_child(ui)
	_update_board()

func setup_level() -> void:
	light_source_pos = grid_center(int(level_data.source[0]),int(level_data.source[1]))
	target_stars.clear()
	for pos in level_data.stars:
		target_stars.append({"pos":grid_center(int(pos[0]),int(pos[1])),"hit":false})
	mirrors.clear()
	history.clear()
	selected_mirror = -1
	level_won = false
	hints_used = 0
	hint_index = 0
	message = ""

func grid_center(x: int, y: int) -> Vector2:
	return Vector2((x + 0.5) * GRID_SIZE, (y + 0.5) * GRID_SIZE)

func _process(delta: float) -> void:
	if not Aura.reduced_motion: elapsed += delta
	for i in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		particles[i].pos += particles[i].velocity * delta
		particles[i].velocity.y += delta * 60.0
		if particles[i].life <= 0: particles.remove_at(i)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(ORIGIN)
	draw_rect(Rect2(-3,-3,774,438),Color("c7bcae"))
	draw_rect(Rect2(0,0,768,432),Color("f8f3ee"))
	for x in range(GRID_WIDTH+1):
		draw_line(Vector2(x*GRID_SIZE,0),Vector2(x*GRID_SIZE,432),Color("e7dfe4"),1)
	for y in range(GRID_HEIGHT+1):
		draw_line(Vector2(0,y*GRID_SIZE),Vector2(768,y*GRID_SIZE),Color("e7dfe4"),1)
	for segment in ray_segments:
		draw_line(segment.from,segment.to,Color("eac66c",0.25),10,true)
		draw_line(segment.from,segment.to,Color("bd9547"),3,true)
		draw_line(segment.from,segment.to,Color("fff1b4"),1,true)
	draw_circle(light_source_pos,12,Color("d8ad54"))
	draw_circle(light_source_pos,18,Color("ae8749"),false,2)
	for star in target_stars:
		var c := Color("c29a43") if star.hit else Color("8d7d9d")
		var pulse := 1.0 + (0.06 * sin(elapsed * 3.0) if star.hit else 0.0)
		if star.hit: draw_circle(star.pos,22,Color("f2d78f",0.3))
		draw_colored_polygon(star_points(star.pos,12*pulse,5*pulse),c)
		draw_circle(star.pos,17,c,false,1)
	for i in range(mirrors.size()):
		var m: Dictionary = mirrors[i]
		var center := grid_center(int(m.grid_x),int(m.grid_y))
		var tangent := Vector2.RIGHT.rotated(deg_to_rad(float(m.rotation)))
		var normal := tangent.orthogonal()
		draw_colored_polygon(PackedVector2Array([center-tangent*19,center+normal*6,center+tangent*19,center-normal*6]),Color("a8bfd1"))
		draw_line(center-tangent*19,center+tangent*19,Color("687d98"),3,true)
		if i==selected_mirror: draw_circle(center,22,Aura.GOLD,false,2)
	for particle in particles:
		draw_colored_polygon(star_points(particle.pos,particle.radius*1.5,particle.radius*0.65),Color(0.8,0.62,0.24,minf(1,particle.life)))
	draw_set_transform(Vector2.ZERO)
	for x in range(16):
		draw_string(ThemeDB.fallback_font,ORIGIN+Vector2(x*48+18,-9),str(x+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Aura.PURPLE)

func star_points(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(10):
		var a := -PI/2 + float(i)*PI/5
		points.append(center+Vector2(cos(a),sin(a))*(outer if i%2==0 else inner))
	return points

func _unhandled_input(event: InputEvent) -> void:
	if blocked or (level_won and level_number>0): return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		board_tap(event.position-ORIGIN)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT,KEY_A: rotate_selected(-45)
			KEY_RIGHT,KEY_D: rotate_selected(45)
			KEY_Z: undo_mirror()
			KEY_DELETE,KEY_BACKSPACE: delete_selected()
			KEY_R: reset_level()
			KEY_ESCAPE: ui.open_pause()

func board_tap(pos: Vector2) -> void:
	if blocked or (level_won and level_number>0): return
	if not Rect2(0,0,768,432).has_point(pos): return
	var cell := Vector2i(floori(pos.x/48),floori(pos.y/48))
	var point := grid_center(cell.x,cell.y)
	if level_number==0 and tool=="source":
		if find_mirror_at(cell.x,cell.y)>=0 or star_at(point)>=0:
			message="Choose an empty cell for the light source."
			ui.refresh()
			return
		snapshot()
		light_source_pos=point
	elif level_number==0 and tool=="star":
		if point==light_source_pos or find_mirror_at(cell.x,cell.y)>=0: return
		snapshot()
		var found:=star_at(point)
		if found>=0: target_stars.remove_at(found)
		elif target_stars.size()<12: target_stars.append({"pos":point,"hit":false})
		else: message="Up to 12 target stars per creative layout."
	else:
		if point==light_source_pos or star_at(point)>=0:
			message="Keep the source and target cells clear."
			ui.refresh()
			return
		var found:=find_mirror_at(cell.x,cell.y)
		if found>=0: selected_mirror=found
		else:
			snapshot()
			mirrors.append({"grid_x":cell.x,"grid_y":cell.y,"rotation":0.0})
			selected_mirror=mirrors.size()-1
			Aura.sound("place")
	_update_board()

func star_at(pos: Vector2) -> int:
	for i in range(target_stars.size()):
		if target_stars[i].pos==pos:return i
	return -1

func find_mirror_at(x: int,y: int) -> int:
	for i in range(mirrors.size()):
		if mirrors[i].grid_x==x and mirrors[i].grid_y==y:return i
	return -1

func snapshot() -> void:
	history.append({"mirrors":mirrors.duplicate(true),"selected":selected_mirror,"source":light_source_pos,"stars":target_stars.duplicate(true)})
	if history.size()>200: history.pop_front()
	message=""

func rotate_selected(amount: float) -> void:
	if blocked or (level_won and level_number>0) or selected_mirror<0:return
	snapshot()
	mirrors[selected_mirror].rotation=fposmod(float(mirrors[selected_mirror].rotation)+amount,180)
	Aura.sound("rotate")
	_update_board()

func delete_selected() -> void:
	if blocked or (level_won and level_number>0) or selected_mirror<0:return
	snapshot()
	mirrors.remove_at(selected_mirror)
	selected_mirror=-1
	_update_board()

func undo_mirror() -> void:
	if blocked or (level_won and level_number>0) or history.is_empty():return
	var state:Dictionary=history.pop_back()
	mirrors.assign(state.mirrors)
	selected_mirror=state.selected
	light_source_pos=state.source
	target_stars.assign(state.stars)
	message="Last action undone."
	_update_board()

func reset_level() -> void:
	if blocked or (level_won and level_number>0):return
	snapshot()
	mirrors.clear()
	selected_mirror=-1
	_update_board()

func show_hint() -> void:
	if blocked or level_won or level_number==0:return
	hints_used+=1
	message=level_data.hints[mini(hint_index,level_data.hints.size()-1)]
	hint_index+=1
	ui.refresh()

func rating() -> int:
	var result:=3 if mirrors.size()<=int(level_data.par) else (2 if mirrors.size()<=int(level_data.par)+2 else 1)
	return mini(result,2) if hints_used>0 else result

func _update_board() -> void:
	var previous_hits:Array=[]
	for star in target_stars: previous_hits.append(bool(star.hit))
	var previously_won:=level_won
	_recalculate_rays()
	for i in range(target_stars.size()):
		if target_stars[i].hit and not previous_hits[i]: burst(target_stars[i].pos)
	if level_won and not previously_won:
		Aura.sound("win")
		if level_number>0:
			Aura.complete(level_number,rating())
			if ui: ui.show_success()
	if ui: ui.refresh()
	queue_redraw()

func burst(pos: Vector2) -> void:
	if Aura.reduced_motion:return
	for i in range(26):
		var direction:=Vector2.RIGHT.rotated(TAU*float(i)/26)
		particles.append({"pos":pos,"velocity":direction*(35+float(i%5)*17),"life":1.1,"radius":2.0+float(i%3)})

func save_layout() -> void:
	var data:Dictionary={"source":[light_source_pos.x,light_source_pos.y],"stars":[],"mirrors":mirrors}
	for star in target_stars:data.stars.append([star.pos.x,star.pos.y])
	var file:=FileAccess.open("user://creative.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		message="Creative layout saved on this device."
	else:message="Could not save the creative layout."
	ui.refresh()

func load_layout() -> void:
	if not FileAccess.file_exists("user://creative.json"):
		message="No saved layout yet."
		ui.refresh()
		return
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://creative.json"))
	if not data is Dictionary or not data.has_all(["source","stars","mirrors"]):
		message="Saved layout could not be read."
		ui.refresh()
		return
	snapshot()
	mirrors.assign(data.mirrors)
	light_source_pos=Vector2(data.source[0],data.source[1])
	target_stars.clear()
	for pos in data.stars:target_stars.append({"pos":Vector2(pos[0],pos[1]),"hit":false})
	selected_mirror=-1
	message="Saved layout restored."
	_update_board()

func _recalculate_rays() -> void:
	for star in target_stars:
		star["hit"] = false
	stars_hit = 0
	ray_segments.clear()
	var ray_start := light_source_pos
	var ray_direction := Vector2.DOWN
	for _bounce in range(RAY_MAX_BOUNCES):
		var nearest_t := INF
		var nearest_mirror := -1
		var nearest_star := -1
		var end_point := _board_exit(ray_start, ray_direction)
		var exit_t := ray_start.distance_to(end_point)
		nearest_t = exit_t

		for i in range(mirrors.size()):
			var mirror: Dictionary = mirrors[i]
			var center := grid_center(int(mirror["grid_x"]), int(mirror["grid_y"]))
			var hit := _ray_segment_intersection(ray_start, ray_direction, center, Vector2.RIGHT.rotated(deg_to_rad(float(mirror["rotation"]))), MIRROR_HALF_LENGTH)
			if hit.x >= 0.0 and hit.y < nearest_t:
				nearest_t = hit.y
				end_point = ray_start + ray_direction * nearest_t
				nearest_mirror = i
				nearest_star = -1

		# Stars are checkpoints, not solid obstacles: the beam can activate several
		# stars along one segment before reaching the next mirror or board edge.
		for i in range(target_stars.size()):
			var star: Dictionary = target_stars[i]
			var to_star: Vector2 = star["pos"] - ray_start
			var t := to_star.dot(ray_direction)
			if t > RAY_EPSILON and t <= nearest_t and (to_star - ray_direction * t).length() <= 15.0:
				target_stars[i]["hit"] = true

		end_point = ray_start + ray_direction * nearest_t
		ray_segments.append({"from": ray_start, "to": end_point})
		if nearest_mirror < 0:
			break

		var mirror: Dictionary = mirrors[nearest_mirror]
		var tangent := Vector2.RIGHT.rotated(deg_to_rad(float(mirror["rotation"])))
		var normal := Vector2(-tangent.y, tangent.x)
		ray_direction = ray_direction.bounce(normal).normalized()
		ray_start = end_point + ray_direction * RAY_EPSILON

	stars_hit = 0
	for star in target_stars:
		if bool(star["hit"]):
			stars_hit += 1
	level_won = not target_stars.is_empty() and stars_hit == target_stars.size()

func _ray_segment_intersection(origin: Vector2, direction: Vector2, center: Vector2, tangent: Vector2, half_length: float) -> Vector2:
	var normal := Vector2(-tangent.y, tangent.x)
	var denominator := direction.dot(normal)
	if absf(denominator) < 0.0001:
		return Vector2(-1.0, -1.0)
	var t := (center - origin).dot(normal) / denominator
	if t <= RAY_EPSILON:
		return Vector2(-1.0, -1.0)
	var point := origin + direction * t
	if absf((point - center).dot(tangent)) > half_length:
		return Vector2(-1.0, -1.0)
	return Vector2(point.x, t)

func _board_exit(origin: Vector2, direction: Vector2) -> Vector2:
	var candidates: Array[float] = []
	if direction.x > 0.0001:
		candidates.append((GRID_WIDTH * GRID_SIZE - origin.x) / direction.x)
	elif direction.x < -0.0001:
		candidates.append((0.0 - origin.x) / direction.x)
	if direction.y > 0.0001:
		candidates.append((GRID_HEIGHT * GRID_SIZE - origin.y) / direction.y)
	elif direction.y < -0.0001:
		candidates.append((0.0 - origin.y) / direction.y)
	var t := INF
	for value in candidates:
		if value > RAY_EPSILON:
			t = minf(t, value)
	if is_inf(t):
		return origin + direction * 1000.0
	return origin + direction * t

