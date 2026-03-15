extends Control

@onready var text_box = $TextEdit

func _ready():
	text_box	.text = "Player %d died" % Global.loser
	Global.loser = 0

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_try_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
