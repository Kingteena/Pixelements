extends Node2D

# Grab the players as soon as the arena loads
@onready var p1 = $Player
@onready var p2 = $Player2
@onready var attack_manager = $AttackManager # Grab the one true manager
@onready var hud = $HUD 

func _ready():
	# 1. Wait a split second to ensure both player scenes are fully loaded into the world
	await get_tree().process_frame
	
	p1.base_element = Global.p1_element
	p2.base_element = Global.p2_element
	
	# Hand the manager an array of every player it needs to check for damage
	attack_manager.targets.clear()
	attack_manager.targets.append(p1)
	attack_manager.targets.append(p2)
	
	# Connect the player signals directly to the HUD's update function
	p1.health_changed.connect(hud.update_health)
	p2.health_changed.connect(hud.update_health)
	
	
	p1.player_death.connect(_on_player_death)
	p2.player_death.connect(_on_player_death)	
	
		
	print("Global Sandbox initialized. Let the chaos begin.")

func _on_player_death():
	get_tree().change_scene_to_file("res://scenes/control.tscn")	
	

func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
