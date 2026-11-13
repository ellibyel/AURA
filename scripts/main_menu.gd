extends Control
var content: Control
var scenery: Node2D
var character: Node2D

func _ready() -> void:
	scenery = load("res://scenes/background.tscn").instantiate()
	add_child(scenery)
	character = load("res://scenes/lightkeeper.tscn").instantiate()
	character.position = Vector2(1015, 358)
	character.scale = Vector2.ONE * 1.45
	add_child(character)
	content = Control.new()
	add_child(content)
	if Aura.menu_page == "chapters": show_chapters()
	else: show_home()
	Aura.menu_page = ""

func clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func show_home() -> void:
	clear()
	character.visible = true
	character.happy = Aura.total_stars() > 0
	Aura.label(content,"A QUIET JOURNEY OF LIGHT",Rect2(90,84,700,40),24,Aura.MUTED)
	# Title font: Cinzel (SIL Open Font License, assets/fonts/Cinzel_OFL.txt).
	var title_font := FontVariation.new()
	title_font.base_font = load("res://assets/fonts/Cinzel.ttf")
	title_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	title_font.spacing_glyph = 14
	var title := Aura.label(content,"AURA",Rect2(78,108,700,118),100)
	title.add_theme_font_override("font", title_font)
	Aura.paragraph(content,"Some memories are small as starlight.\nHelp them find their way home.",Rect2(90,240,650,100),27)
	Aura.button(content,"Continue journey" if int(Aura.best[0]) > 0 else "Begin journey",Rect2(90,368,380,80),func(): start_level(Aura.unlocked),28)
	Aura.button(content,"Choose a chapter",Rect2(90,460,380,76),show_chapters)
	Aura.button(content,"Creative studio",Rect2(90,548,380,76),func(): start_level(0))
	Aura.button(content,"Settings",Rect2(90,636,183,76),func(): Aura.open_settings(self))
	Aura.button(content,"Credits",Rect2(287,636,183,76),show_credits)
	# Tap the lightkeeper to change her mood.
	var touch := Control.new()
	touch.position = Vector2(870, 210)
	touch.size = Vector2(300, 440)
	touch.mouse_filter = Control.MOUSE_FILTER_STOP
	touch.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			character.next_emotion())
	content.add_child(touch)
	var tip := Aura.label(content,"tap her",Rect2(870,652,300,34),22,Aura.MUTED)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Aura.label(content,"%d CHAPTERS  ·  ★ %d / %d  ·  NO TIMER" % [Aura.LEVEL_COUNT, Aura.total_stars(), Aura.LEVEL_COUNT * 3],Rect2(90,722,970,34),22,Aura.MUTED)
	if not Aura.save_error.is_empty(): Aura.label(content,Aura.save_error,Rect2(560,84,560,34),22)

func show_chapters() -> void:
	clear()
	character.visible = false
	Aura.label(content,"Chapters",Rect2(80,40,600,64),44)
	Aura.label(content,"★ %d / %d" % [Aura.total_stars(), Aura.LEVEL_COUNT * 3],Rect2(900,52,300,50),32,Color("7d5f2a")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Aura.label(content,"Cards show your best result in each chapter.",Rect2(330,62,560,34),22,Aura.MUTED)
	for i in range(Aura.LEVEL_COUNT):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level_%d.json" % (i + 1)))
		var open := i < Aura.unlocked
		var card := Aura.button(content,"",Rect2(80 + (i % 4) * 285,130 + (i / 4) * 250,265,230),func(): start_level(i + 1))
		card.disabled = not open
		Aura.label(card,"%02d" % (i + 1),Rect2(20,14,120,50),40,Aura.INK if open else Aura.MUTED)
		Aura.paragraph(card,data.title if open else "Locked",Rect2(20,72,230,70),24)
		Aura.label(card,("★".repeat(int(Aura.best[i])) + "☆".repeat(3 - int(Aura.best[i]))) if open else "",Rect2(20,150,230,52),36,Color("7d5f2a"))
	Aura.button(content,"Back",Rect2(80,650,200,80),show_home)
	Aura.button(content,"Reset saved progress",Rect2(296,650,320,80),confirm_reset,24)

func confirm_reset() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,0.4)
	shade.position = Vector2(-640,0)
	shade.size = Vector2(2560,800)
	add_child(shade)
	var box := Aura.panel(shade,Rect2(1000,230,560,300))
	Aura.paragraph(box,"Reset all chapter rewards and lock chapters 2-%d? Your settings and creative layout will stay." % Aura.LEVEL_COUNT,Rect2(16,22,528,120),26)
	Aura.button(box,"Cancel",Rect2(16,186,254,84),shade.queue_free)
	Aura.button(box,"Reset progress",Rect2(290,186,254,84),func():
		Aura.reset_progress()
		shade.queue_free()
		show_chapters())

func show_credits() -> void:
	clear()
	character.visible = false
	var box := Aura.panel(content,Rect2(70,40,1140,700))
	Aura.label(box,"AURA / MT-2402",Rect2(20,16,1000,50),36)
	Aura.paragraph(box,"Elmira Bukhanova — mechanics & level design\nKhalida Yerpan — interface & game flow\nDiana Zhumagali — visual & sound direction\n\nSounds: Kenney (kenney.nl), \"Interface Sounds\" and \"Music Jingles\", CC0 1.0.\nMusic: made in Apple GarageBand with the \"Set Free Melodic Synth\" loop and the Grand Piano instrument, used under the GarageBand licence.\nArt: lightkeeper — our own A2 design built from shapes (tools/photoshop).\nEngine: Godot 4.7 (MIT). Fonts: Godot default; title in Cinzel (SIL OFL 1.1).\nAI assistance (ChatGPT, Claude) is listed file by file in the README.\n\nInspired by the calm mood of Frieren: Beyond Journey's End; puzzle references: Monument Valley and Portal. No artwork or music from these works is used.",Rect2(20,80,1090,500),25)
	Aura.button(box,"Back",Rect2(20,600,220,80),show_home)

func start_level(number: int) -> void:
	Aura.start_level(number)
