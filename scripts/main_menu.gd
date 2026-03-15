extends Control

func _on_play_button_pressed():
	# Go to Character Select
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
