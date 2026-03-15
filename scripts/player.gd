extends CharacterBody2D


var SPEED = 180.0
var JUMP_VELOCITY = -300.0
const JUMP_RELEASE_MULTIPLIER = 0.5  # Lower = shorter hop on tap, try 0.3–0.6

const GROUND_ACCELERATION = 1200.0  # How fast you reach full speed on ground
const AIR_ACCELERATION = 400.0      # How much control you have in the air
const GROUND_FRICTION = 1200.0      # How fast you stop on ground
const AIR_FRICTION = 80.0           # Barely any drag in air = momentum preserved

const ATTACK_STUN = 30

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var player_id: int = 1 # Change to 2 in the Inspector for Player 2
@export var base_element: int = 1 # Let's say 1=Fire, 2=Water

# Save the normal sizes so we don't permanently mutate the player
@onready var default_sprite_scale = animated_sprite.scale
@onready var default_hitbox_scale = collision_shape.scale

var last_direction = 1
var attacking_frames = 0

var health = 100
 
signal health_changed(id: int, new_health: int)
signal player_death()

func _ready():
	
	# 1. Reset everything to normal first
	animated_sprite.scale = default_sprite_scale
	collision_shape.scale = default_hitbox_scale
	
	# 2. Apply the Element 4 size buff (Earth/Tank mode?)
	if base_element == 4:
		# Make them 50% bigger in all directions
		animated_sprite.scale = default_sprite_scale * 1.5
		collision_shape.scale = default_hitbox_scale * 1.5
		
		SPEED *= 0.75
		
		# BE CAREFUL: When you scale up, they grow DOWN into the floor.
		# This pops them up a few pixels so they don't get stuck in the concrete.
		position.y -= 20
		
	if base_element == 3:
		JUMP_VELOCITY *= 1.5
		

func take_damage(amount: int):
	health -= amount
	
	# Shout out the new health to anyone listening (the HUD)
	health_changed.emit(player_id, health)
	
	animated_sprite.modulate = Color(10, 10, 10) 
	await get_tree().create_timer(0.05).timeout
	animated_sprite.modulate = Color(1, 1, 1) 
	
	if health <= 0 && Global.loser == 0:
		die()
		
func die():
	Global.loser = player_id
	player_death.emit()

func _physics_process(delta: float) -> void:
	 #Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if attacking_frames > 0:
		attacking_frames -=1
		animated_sprite.play("attack" + str(base_element))
		
		velocity.x *= 0.95
		
		move_and_slide()
		return
		
	# Movement
	var move_left = "move_left%d" % player_id 
	var move_right = "move_right%d" % player_id
	var attack_btn = "attack%d" % player_id
	var jump_btn = "jump%d" % player_id

	# Handle jump.
	if Input.is_action_just_pressed(jump_btn) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Variable jump height: cut upward velocity on release
	if Input.is_action_just_released(jump_btn) and velocity.y < 0:
		velocity.y *= JUMP_RELEASE_MULTIPLIER
#
	# Get the input direction: -1, 0, 1
	var direction := Input.get_axis(move_left, move_right)

	if Input.is_action_just_pressed(attack_btn):
		attacking_frames = ATTACK_STUN # quarter of a second
		var attack_manager = get_tree().get_first_node_in_group("attack_manager")
		attack_manager.shoot(global_position, last_direction, base_element, self)
		#attack_manager.spawn_explosion(global_position, 50, 200, 2 )
	
	#flips sprite
	if direction>0:
		animated_sprite.flip_h = false
		last_direction = 1
	elif direction<0:
		last_direction = -1
		animated_sprite.flip_h = true
	
	#changes sprite
	if attacking_frames > 0:
		print("ATTACK")
		attacking_frames -=1
		animated_sprite.play("attack" + str(base_element))
	if is_on_floor():
		if direction==0:
			animated_sprite.play("idle" + str(base_element))
		else:
			animated_sprite.play("run" + str(base_element))
	else:
		animated_sprite.play("jump" + str(base_element) )
	
	# Movement with separate air/ground feel
	if is_on_floor():
		if direction:
			velocity.x = move_toward(velocity.x, direction * SPEED, GROUND_ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, GROUND_FRICTION * delta)
	else:
		if direction:
			velocity.x = move_toward(velocity.x, direction * SPEED, AIR_ACCELERATION * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)

	move_and_slide()
