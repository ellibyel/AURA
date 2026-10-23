extends Control
var content: Control
var scenery: Node2D

func _ready() -> void:
	scenery = load("res://scripts/scenery.gd").new()
	scenery.character_position = Vector2(1015, 380)
	scenery.character_scale = 1.45
	add_child(scenery)
	content = Control.new()
	add_child(content)
	show_home()

func clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func show_home() -> void:
	clear()
	scenery.happy = int(Aura.best[1]) > 0
	Aura.label(content,"A QUIET JOURNEY OF LIGHT",Rect2(90,91,700,40),18,Aura.PURPLE)
	Aura.label(content,"AURA",Rect2(83,126,700,105),92)
	Aura.paragraph(content,"Some memories are small as starlight.\nHelp them find their way home.",Rect2(90,259,650,90),25)
	Aura.button(content,"Continue journey" if int(Aura.best[0]) > 0 else "Begin journey",Rect2(90,395,380,62),func(): start_level(2 if int(Aura.best[0])>0 and int(Aura.best[1])==0 else 1))
	Aura.button(content,"Choose a chapter",Rect2(90,472,380,58),show_chapters)
	Aura.button(content,"Creative studio",Rect2(90,545,380,58),func(): start_level(0))
	Aura.button(content,"Settings",Rect2(90,618,180,54),func(): Aura.open_settings(self))
	Aura.button(content,"Credits",Rect2(284,618,186,54),show_credits)
	Aura.label(content,"TWO CHAPTERS  /  NO TIMER  /  PLAY AT YOUR OWN PACE",Rect2(90,710,970,35),16,Aura.PURPLE)
	Aura.label(content,"Your lightkeeper",Rect2(895,610,320,36),19,Aura.PURPLE).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not Aura.save_error.is_empty(): Aura.label(content,Aura.save_error,Rect2(90,754,900,28),16)

func show_chapters() -> void:
	clear()
	Aura.label(content,"Choose a chapter",Rect2(80,80,730,70),44)
	Aura.paragraph(content,"Complete First Star to open the second chapter. Your best rewards are saved automatically.",Rect2(80,167,690,72),22)
	for i in range(2):
		var box := Aura.panel(content,Rect2(80,280+i*164,700,142))
		Aura.label(box,"01  /  First Star" if i==0 else "02  /  A Thread of Memory",Rect2(25,14,610,35),25)
		Aura.label(box,"Best reward: %d / 3 stars" % int(Aura.best[i]),Rect2(25,60,395,32),19,Aura.PURPLE)
		var btn := Aura.button(box,"Play" if i<Aura.unlocked else "Locked",Rect2(495,65,178,54),func(): start_level(i+1))
		btn.disabled = i >= Aura.unlocked
	Aura.button(content,"Back",Rect2(80,648,195,56),show_home)
	Aura.button(content,"Reset saved progress",Rect2(294,648,290,56),confirm_reset)

func confirm_reset() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,0.4)
	shade.size = Vector2(1280,800)
	add_child(shade)
	var box := Aura.panel(shade,Rect2(390,260,500,255))
	Aura.paragraph(box,"Reset both chapter rewards and lock Chapter 2? Your settings and creative layout will stay.",Rect2(28,25,442,95),23)
	Aura.button(box,"Cancel",Rect2(28,160,210,60),shade.queue_free)
	Aura.button(box,"Reset progress",Rect2(255,160,215,60),func():
		Aura.reset_progress()
		shade.queue_free()
		show_chapters())

func show_credits() -> void:
	clear()
	var box := Aura.panel(content,Rect2(70,70,735,625))
	Aura.label(box,"AURA / MT-2402",Rect2(32,25,670,50),34)
	Aura.paragraph(box,"Elmira Bukhanova — mechanics & level design\nKhalida Yerpan — interface & game flow\nDiana Zhumagali — visual & sound direction\n\nA two-chapter student puzzle inspired by the quiet fantasy atmosphere of Frieren: Beyond Journey's End.\n\nOriginal procedural elf illustration, scenery and synthesized sounds. No anime artwork or soundtrack.\n\nReference games: Monument Valley and Portal.\nEngine: Godot (MIT). See README for asset and assistance notes.",Rect2(32,100,670,435),21)
	Aura.button(box,"Back",Rect2(32,540,200,55),show_home)

func start_level(number: int) -> void:
	if number > Aura.unlocked: return
	get_tree().change_scene_to_file("res://levels/creative.tscn" if number==0 else "res://levels/level_%d.tscn" % number)
