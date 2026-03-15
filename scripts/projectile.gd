extends Area2D

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
var manager: Node2D
var shooter: Node2D


var direction = Vector2.RIGHT
var speed = 600.0
var element_type = 1 # 1=Fire, 2=Water, etc.

func _ready():
	
	if element_type == 1:
		animated_sprite.play("fire")
	elif element_type == 2:
		animated_sprite.play("water")
	elif element_type == 3:
		animated_sprite.play("air")
	elif element_type == 4:
		animated_sprite.play("earth")
		

func _physics_process(delta):
	# Move the actual projectile
	position += direction * speed * delta

# This triggers the millisecond it touches a wall (TileMap) or the enemy (CharacterBody2D)

func _on_body_entered(body):
	# Person who shot it is immune
	if body == shooter:
		return
	
	# 1. If it hits the enemy directly, slap them with damage
	if body.has_method("take_damage"):
		body.take_damage(10) # Heavy damage for a direct hit
		
		if element_type == 3:
			body.velocity.x += speed * direction[0]
		
	
	if manager:
		# 3. Trigger the massive 100-particle shrapnel puddle at the exact impact spot
		manager.spawn_explosion(global_position, 50, 400.0, element_type)
		
	# 4. Instantly delete this Area2D projectile so it disappears
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Quick check to see if the area we hit is actually another bullet
	if "element_type" in area:
		
		# Optional: Ignore it if you somehow shot your own bullet
		if area.shooter == shooter:
			return
			
		# It's an enemy bullet! Detonate instantly.
		if manager:
			manager.spawn_explosion(global_position, 50, 150.0, 3)
			
		# Nuke this bullet
		if element_type != 4:
			queue_free()
