extends Control
var content: Control
var scenery: Node2D
var character: Node2D

func _ready() -> void:
	scenery = load("res://scenes/background.tscn").instantiate()
	add_child(scenery)
	character = load("res://scenes/lightkeeper.tscn").instantiate()
	character.position = Vector2(1015, 380)
	character.scale = Vector2.ONE * 1.45
	add_child(character)
	content = Control.new()
	add_child(content)
	show_home()

func clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func show_home() -> void:
	clear()
	character.visible = true
	character.happy = int(Aura.best[1]) > 0
	Aura.label(content,"A QUIET JOURNEY OF LIGHT",Rect2(90,84,700,40),24,Aura.MUTED)
	Aura.label(content,"AURA",Rect2(83,116,700,105),92)
	Aura.paragraph(content,"Some memories are small as starlight.\nHelp them find their way home.",Rect2(90,240,650,100),27)
	Aura.button(content,"Continue journey" if int(Aura.best[0]) > 0 else "Begin journey",Rect2(90,368,380,80),func(): start_level(2 if int(Aura.best[0])>0 and int(Aura.best[1])==0 else 1),28)
	Aura.button(content,"Choose a chapter",Rect2(90,460,380,76),show_chapters)
	Aura.button(content,"Creative studio",Rect2(90,548,380,76),func(): start_level(0))
	Aura.button(content,"Settings",Rect2(90,636,183,76),func(): Aura.open_settings(self))
	Aura.button(content,"Credits",Rect2(287,636,183,76),show_credits)
	var tag := Aura.panel(content,Rect2(855,612,320,52))
	Aura.label(tag,"Your lightkeeper",Rect2(0,6,320,40),24,Aura.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Aura.label(content,"TWO CHAPTERS  ·  NO TIMER  ·  PLAY AT YOUR OWN PACE",Rect2(90,722,970,34),22,Aura.MUTED)
	if not Aura.save_error.is_empty(): Aura.label(content,Aura.save_error,Rect2(560,84,560,34),22)

func show_chapters() -> void:
	clear()
	character.visible = true
	Aura.label(content,"Choose a chapter",Rect2(80,60,730,70),44)
	Aura.paragraph(content,"Complete First Star to open the second chapter. Your best rewards are saved automatically.",Rect2(80,140,700,80),24)
	for i in range(2):
		var box := Aura.panel(content,Rect2(80,240+i*172,720,152))
		Aura.label(box,"01  ·  First Star" if i==0 else "02  ·  A Thread of Memory",Rect2(14,14,600,40),30)
		Aura.label(box,"Best reward: %d / 3 stars" % int(Aura.best[i]),Rect2(14,70,420,36),24,Aura.MUTED)
		var btn := Aura.button(box,"Play" if i<Aura.unlocked else "Locked",Rect2(500,56,200,80),func(): start_level(i+1),28)
		btn.disabled = i >= Aura.unlocked
	Aura.button(content,"Back",Rect2(80,600,200,80),show_home)
	Aura.button(content,"Reset saved progress",Rect2(296,600,320,80),confirm_reset,24)

func confirm_reset() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,0.4)
	shade.position = Vector2(-640,0)
	shade.size = Vector2(2560,800)
	add_child(shade)
	var box := Aura.panel(shade,Rect2(1000,230,560,300))
	Aura.paragraph(box,"Reset both chapter rewards and lock Chapter 2? Your settings and creative layout will stay.",Rect2(16,22,528,120),26)
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
	Aura.paragraph(box,"Elmira Bukhanova — mechanics & level design\nKhalida Yerpan — interface & game flow\nDiana Zhumagali — visual & sound direction\n\nSounds: Kenney (kenney.nl), \"Interface Sounds\" and \"Music Jingles\", CC0 1.0.\nMusic: made in Apple GarageBand with the \"Set Free Melodic Synth\" loop and the Grand Piano instrument, used under the GarageBand licence.\nArt: character, scenery and board pieces are editor-animated frames in assets/art.\nEngine: Godot 4.7 (MIT). Default Godot font.\nAI assistance (ChatGPT, Claude) is listed file by file in the README.\n\nInspired by the calm mood of Frieren: Beyond Journey's End; puzzle references: Monument Valley and Portal. No artwork or music from these works is used.",Rect2(20,80,1090,500),25)
	Aura.button(box,"Back",Rect2(20,600,220,80),show_home)

func start_level(number: int) -> void:
	if number > Aura.unlocked: return
	get_tree().change_scene_to_file("res://levels/creative.tscn" if number==0 else "res://levels/level_%d.tscn" % number)
