extends Node
var checks := 0
var backups: Dictionary = {}
func check(value: bool, description: String) -> void:
	if not value:
		push_error("FAIL: "+description)
		get_tree().quit(1)
		assert(value,description)
	checks += 1
	print("PASS: "+description)
func spawn_level(number: int) -> Node:
	var level=load("res://levels/creative.tscn" if number==0 else "res://levels/level_%d.tscn" % number).instantiate()
	add_child(level)
	return level
func _ready() -> void:
	await get_tree().process_frame
	for path in ["user://aura_progress.cfg","user://creative.json"]:
		backups[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	Aura.reset_progress()
	var one=spawn_level(1)
	check(one.target_stars.size()==1,"chapter 1 loads")
	one.board_tap(one.grid_center(8,3))
	one.rotate_selected(45)
	one.undo_mirror()
	check(one.mirrors.size()==1 and one.mirrors[0].rotation==0,"undo rotation restores angle")
	one.delete_selected()
	one.undo_mirror()
	check(one.mirrors.size()==1 and one.selected_mirror==0,"undo deletion restores mirror and selection")
	one.reset_level()
	one.undo_mirror()
	check(one.mirrors.size()==1,"undo reset restores layout")
	one.reset_level()
	one.board_tap(one.grid_center(8,7))
	one.rotate_selected(45)
	check(one.level_won and one.stars_hit==1,"chapter 1 solved through gameplay commands")
	check(Aura.unlocked==2 and Aura.best[0]==3,"chapter 2 unlock and 3-star award")
	var layout=one.mirrors.duplicate(true)
	one.rotate_selected(45)
	one.delete_selected()
	one.undo_mirror()
	one.reset_level()
	one.board_tap(one.grid_center(2,2))
	check(one.mirrors==layout and one.level_won,"all board mutations blocked after victory")
	one.queue_free()
	await get_tree().process_frame
	Aura.best=[0,0]
	Aura.unlocked=1
	Aura.load_progress()
	check(Aura.best[0]==3 and Aura.unlocked==2,"saved rewards reload")
	var two=spawn_level(2)
	for item in [[8,3,135],[4,3,135],[4,7,45]]:
		two.board_tap(two.grid_center(item[0],item[1]))
		two.rotate_selected(item[2])
	check(two.level_won and two.stars_hit==2,"chapter 2 lights both stars with 3 mirrors")
	check(Aura.best[1]==3,"chapter 2 award saved")
	two.queue_free()
	await get_tree().process_frame
	var studio=spawn_level(0)
	studio.tool="star"
	studio.board_tap(studio.grid_center(2,2))
	check(studio.target_stars.size()==2,"creative target placement")
	studio.tool="source"
	studio.board_tap(studio.grid_center(3,1))
	check(studio.light_source_pos==studio.grid_center(3,1),"creative source movement")
	studio.save_layout()
	studio.tool="star"
	studio.board_tap(studio.grid_center(2,2))
	studio.load_layout()
	check(studio.target_stars.size()==2,"creative save/load")
	studio.ui.open_pause()
	var before=studio.mirrors.size()
	studio.tool="mirror"
	studio.board_tap(studio.grid_center(5,5))
	check(studio.mirrors.size()==before,"settings blocks board input")
	studio.queue_free()
	await get_tree().process_frame
	var menu=load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	menu.show_chapters()
	menu.show_credits()
	await get_tree().process_frame
	await get_tree().process_frame
	var credits_panel = menu.content.get_child(0)
	var credits_text = credits_panel.get_child(1)
	check(credits_text.position.x + credits_text.size.x <= credits_panel.size.x - 30, "credits text stays within panel width")
	check(credits_text.position.y + credits_text.get_minimum_size().y <= 535, "credits text fits above Back button")
	menu.show_home()
	check(menu.content.get_child_count()>5,"all menu screens construct")
	menu.queue_free()
	await get_tree().process_frame
	for path in backups:
		if backups[path] == null: DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path,FileAccess.WRITE)
			file.store_buffer(backups[path])
	print("AURA VERIFICATION COMPLETE: %d checks" % checks)
	Aura.music.stop()
	for voice in Aura.voices.values(): voice.stop()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
