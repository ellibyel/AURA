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
	Aura.current_level = number
	var level=load(Aura.GAME_SCENE).instantiate()
	add_child(level)
	return level
func play_solution(level: Node) -> void:
	for item in level.level_data.solution:
		level.board_tap(level.grid_center(int(item[0]),int(item[1])))
		level.rotate_selected(float(item[2]))
# Phone readability rules from the Assignment 2 feedback.
func check_readable(root: Node, name: String) -> void:
	var ok := true
	for node in root.find_children("*", "Button", true, false):
		var b: Button = node
		if b.size.y < 64 or b.get_theme_font_size("font_size") < 24 or b.get_global_rect().end.y > 756:
			ok = false
			print("  small or low button: ", b.text, " ", b.get_global_rect(), " font ", b.get_theme_font_size("font_size"))
	for node in root.find_children("*", "Label", true, false):
		var l: Label = node
		if l.get_theme_font_size("font_size") < 22 or l.get_theme_color("font_color") == Aura.PURPLE:
			ok = false
			print("  small or purple text: ", l.text.left(40))
	check(ok, name + ": buttons >= 64 px, text >= 22 px, no purple text, controls above home indicator")

func _ready() -> void:
	await get_tree().process_frame
	for path in ["user://aura_progress.cfg","user://creative.json","user://perf_log.csv"]:
		backups[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	Aura.reset_progress()
	var one=spawn_level(1)
	check(one.target_stars.size()==1,"chapter 1 loads")
	await get_tree().process_frame
	check_readable(one.ui, "chapter 1 HUD")
	var text_buttons := 0
	for node in one.ui.find_children("*","Button",true,false):
		if not node.text.is_empty(): text_buttons += 1
	check(text_buttons==0,"in-game controls are icons, not long text buttons (Assignment 3 feedback)")
	check(one.BOARD.x*one.BOARD.y/(Aura.DESIGN.x*Aura.DESIGN.y)>0.6,"board fills more than 60% of the screen")
	for key in ["place","rotate","win"]:
		check(Aura.voices[key].stream != null and Aura.SOUNDS[key].begins_with("res://assets/audio/kenney/"), "sound '%s' is a credited Kenney CC0 file" % key)
	check(Aura.has_music() and Aura.music.playing, "background music loads and plays")
	one.show_hint()
	check(one.hint_cells.size()==1 and Vector2i(one.hint_cells[0][0],one.hint_cells[0][1])==Vector2i(8,7), "first hint highlights the first solution cell")
	one.board_tap(one.grid_center(8,3))
	one.rotate_selected(45)
	one.undo_mirror()
	check(one.mirrors.size()==1 and one.mirrors[0].rotation==0,"undo rotation restores angle")
	one.board_tap(one.grid_center(3,3))
	check(one.mirrors.size()==1 and one.message.begins_with("No mirrors left"),"mirror limit stops extra placements")
	one.delete_selected()
	one.undo_mirror()
	check(one.mirrors.size()==1 and one.selected_mirror==0,"undo deletion restores mirror and selection")
	one.reset_level()
	one.undo_mirror()
	check(one.mirrors.size()==1,"undo reset restores layout")
	one.reset_level()
	one.walls.assign([Vector2i(8,4)])
	one._update_board()
	check(is_equal_approx(one.ray_segments[0].to.y, 4.0*one.GRID_SIZE),"a wall stops the beam at its edge")
	one.walls.clear()
	one.board_tap(one.grid_center(8,7))
	one.rotate_selected(45)
	check(one.level_won and one.stars_hit==1,"chapter 1 solved through gameplay commands")
	check(one.mirror_pieces.size()==1 and one.mirror_pieces[0].rotation_degrees==45.0 and one.star_pieces[0].lit, "board pieces follow the puzzle state")
	check(Aura.best[0]==2, "a hint costs one reward star")
	check(Aura.unlocked==2,"chapter 2 unlocks")
	check(one.ui.success == null, "completion panel waits so the lit star stays visible")
	await get_tree().create_timer(one.SUCCESS_DELAY + 0.2).timeout
	check_readable(one.ui.success, "completion panel")
	var layout=one.mirrors.duplicate(true)
	one.rotate_selected(45)
	one.delete_selected()
	one.undo_mirror()
	one.reset_level()
	one.board_tap(one.grid_center(2,2))
	check(one.mirrors==layout and one.level_won,"all board mutations blocked after victory")
	one.queue_free()
	await get_tree().process_frame
	# Every chapter is solvable with its stored solution (the minimum found by
	# tools/level_solver.py) and that solution earns three stars.
	for n in range(2, Aura.LEVEL_COUNT + 1):
		var level=spawn_level(n)
		var before_win:bool=level.level_won
		play_solution(level)
		check(not before_win and level.level_won and level.rating()==3 and Aura.best[n-1]==3, "chapter %d: solved with %d mirrors, 3 stars" % [n, level.level_data.solution.size()])
		level.queue_free()
		await get_tree().process_frame
	check(Aura.unlocked==Aura.LEVEL_COUNT and Aura.total_stars()==Aura.LEVEL_COUNT*3-1,"all chapters unlock in order and stars add up")
	var two=spawn_level(2)
	var extra:Array=[[0,8]]
	two.board_tap(two.grid_center(extra[0][0],extra[0][1]))
	play_solution(two)
	check(two.level_won and two.rating()==2,"one extra mirror costs one reward star")
	two.queue_free()
	await get_tree().process_frame
	var three=spawn_level(3)
	three.show_hint()
	three.show_hint()
	check(three.hints_used==1 and three.ui.modal!=null,"after the free hint, the hint button offers the demo ad")
	three.ui._play_ad()
	var close: Button = null
	for node in three.ui.modal.find_children("*","Button",true,false): close = node
	check(close.disabled,"demo ad reward is locked during the countdown")
	await get_tree().create_timer(three.ui.AD_SECONDS + 0.4).timeout
	check(not close.disabled,"demo ad reward unlocks after the countdown")
	close.pressed.emit()
	check(three.hints_used==2 and three.hint_cells.size()==three.level_data.solution.size() and three.ui.modal==null,"watching the ad grants a hint that shows every mirror cell")
	three.ui.open_pause()
	await get_tree().process_frame
	check(three.blocked and three.ui.modal != null, "pause opens and blocks the board")
	check_readable(three.ui.modal, "pause menu")
	var settings = Aura.open_settings(three.ui)
	await get_tree().process_frame
	check_readable(settings, "settings")
	settings.queue_free()
	three.ui.resume()
	check(not three.blocked and three.ui.modal == null, "resume unblocks the board")
	three.ui._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(three.ui.modal != null, "leaving the app opens the pause menu")
	three.ui.resume()
	Aura.perf.start_test(1.0)
	await get_tree().create_timer(1.4).timeout
	var result:Dictionary=Aura.perf.summary()
	check(Aura.perf.result_box!=null and result.avg_fps>0 and result.frames>0 and FileAccess.file_exists("user://perf_log.csv"),"performance test records FPS, frame time and memory")
	Aura.perf.result_box.queue_free()
	Aura.perf.result_box=null
	three.queue_free()
	await get_tree().process_frame
	Aura.save_progress()
	Aura.best.fill(0)
	Aura.unlocked=1
	Aura.load_progress()
	check(Aura.best[0]==2 and Aura.best[7]==3 and Aura.unlocked==Aura.LEVEL_COUNT,"saved rewards reload")
	var old := ConfigFile.new()
	old.set_value("progress","stars_0",3)
	old.save("user://aura_progress.cfg")
	Aura.best.fill(0)
	Aura.load_progress()
	check(Aura.best[0]==3 and Aura.unlocked==2,"Assignment 3 saves are migrated")
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
	check(studio.mirrors.size()==before,"pause blocks board input")
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
	check(credits_text.position.y + credits_text.get_minimum_size().y <= 590, "credits text fits above Back button")
	menu.show_home()
	check(menu.content.get_child_count()>5,"all menu screens construct")
	await get_tree().process_frame
	check_readable(menu, "main menu")
	menu.show_chapters()
	await get_tree().process_frame
	check_readable(menu, "chapter select")
	menu.queue_free()
	await get_tree().process_frame
	for path in backups:
		if backups[path] == null: DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path,FileAccess.WRITE)
			file.store_buffer(backups[path])
	print("AURA VERIFICATION COMPLETE: %d checks" % checks)
	if Aura.music: Aura.music.stop()
	for voice in Aura.voices.values(): voice.stop()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
