extends Control

func _ready() -> void:
	# Replace this path with whatever your top-left P1 button is actually named
	$HBoxContainer/P1Select/P1Fire.grab_focus()
	
	Global.p1_element = 1
	Global.p2_element = 1

# Player 1 Element Buttons
func _on_p1_fire_pressed():
	Global.p1_element = 1

func _on_p1_water_pressed():
	Global.p1_element = 2
	
func _on_p1_air_pressed():
	Global.p1_element = 3

func _on_p1_earth_pressed():
	Global.p1_element = 4

# Player 2 Element Buttons
func _on_p2_fire_pressed():
	Global.p2_element = 1

func _on_p2_water_pressed():
	Global.p2_element = 2
	
func _on_p2_air_pressed():
	Global.p2_element = 3

func _on_p2_earth_pressed():
	Global.p2_element = 4

# The big Fight button
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
