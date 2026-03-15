extends CanvasLayer

@onready var p1_health = $P1Health
@onready var p2_health = $P2Health



func update_health(id: int, new_health: int):
	if id == 1:
		p1_health.value = new_health
	elif id == 2:
		p2_health.value = new_health
