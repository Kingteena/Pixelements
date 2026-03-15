extends Node2D

@export var bullet_scene: PackedScene 
@export var multi_mesh_node: MultiMeshInstance2D

const  MAX_PARTICLES = 6000

var targets: Array[Node2D] = []

# The raw data arrays
var positions = PackedVector2Array()
var velocities = PackedVector2Array()
var lifespans = PackedFloat32Array()
var colors = PackedColorArray()
var elements = PackedInt32Array() # Let's say: 1 = Fire, 2 = Water, 3 = Lightning


# world border
var floor_y = 5
var ceil_y = -230
var left_wall = -233
var right_wall = 240

func _ready():
	# Decouple the mesh from the stickman's movement
		
	# Pre-allocate GPU memory for the max particles you expect to have
	multi_mesh_node.multimesh.instance_count = 7000
	multi_mesh_node.multimesh.visible_instance_count = 0


# 1. Standard attack (Shooting a burst)
func spawn_spray(start_pos: Vector2, direction: Vector2, count: int, speed: float, element_type: int):
	for i in range(count):
		positions.append(start_pos)
		
		# Shotgun spread
		var spread_dir = direction.rotated(randf_range(-0.5, 0.5)).normalized()
		velocities.append(spread_dir * speed)
		
		# Normal bullets live for 2 seconds
		lifespans.append(10.0)
		
		elements.append(element_type)
		
		# Give it a color, with a fallback so the arrays NEVER desync
		if element_type == 1:  # fire
			colors.append(Color(1,0,0))
		elif element_type == 2: # water
			colors.append(Color(0,0,1))
		else:
			colors.append(Color(0.5,0.5,0.5, 0.5)) # Default white

# 2. The Shrapnel Burst (Call this when a projectile hits a wall/player)
func spawn_explosion(impact_pos: Vector2, count: int, base_speed: float, element_type: int):
	for i in range(count):
		positions.append(impact_pos)
		
		# 360-degree blast
		var random_angle = randf_range(0, TAU)
		var burst_dir = Vector2(cos(random_angle), sin(random_angle))
		
		# Messy cloud speed
		var randomized_speed = base_speed * randf_range(0.2, 1.2)
		velocities.append(burst_dir * randomized_speed)
		
		# Puddles linger on the floor for 10 seconds
		lifespans.append(10.0)
		
		# FIX: Actually tag the explosion and give it a color so it doesn't crash
		elements.append(element_type)
		
		if element_type == 1:
			colors.append(Color(1,0,0))
		elif element_type == 2:
			colors.append(Color(0,0,1))
		elif element_type == 3:
			colors.append(Color(0.5,0.5,0.5, 0.5))
		else:
			colors.append(Color(0.8,0.5,0))

func shoot(starting_position: Vector2, direction: float, element_type: int, shooter: Node2D):
	var new_bullet = bullet_scene.instantiate()
	
	new_bullet.global_position = starting_position
	new_bullet.global_position.x += direction * 20
	new_bullet.global_position.y -= 15
	new_bullet.direction = Vector2(direction, 0)
	new_bullet.element_type = element_type # Set this based on whatever spell they have equipped
	new_bullet.manager = self
	new_bullet.shooter = shooter
	
	get_tree().current_scene.add_child(new_bullet)


func _physics_process(delta):
	# Chill out if the game hasn't fully started or no bullets exist
	if positions.size() == 0:
		return
		
	# Optimisation: clear oldest particles
	var excess = positions.size() - MAX_PARTICLES
	if excess > 0:
		# Slice off the oldest particles (index 0 to excess) in one clean memory copy
		positions = positions.slice(excess)
		velocities = velocities.slice(excess)
		lifespans = lifespans.slice(excess)
		colors = colors.slice(excess)
		elements = elements.slice(excess)
		
	var hit_radius_squared = 400 
	#var enemy_pos = enemy_target.global_position
	
	var i = positions.size() - 1
	
	# Backwards loop to prevent index shifting crashes
	while i >= 0:
		# 1. Update lifespan timer
		lifespans[i] -= delta
		if lifespans[i] <= 0:
			delete_particle(i)
			i -= 1
			continue
			
		# --- ELEMENTAL PHYSICS ---
		if elements[i] == 2 or elements[i] == 4: # Water falls
			velocities[i].y += 980.0 * delta 
		elif elements[i] == 3: # Steam rises (Assuming you set Steam as 3)
			velocities[i].y -= 300.0 * delta 
		# Fire (1) is ignored here, so it just stays normal
		
		if elements[i] == 3 and positions[i].y <= ceil_y:
			delete_particle(i)
			i -= 1
			continue
		
		
		var my_floor = floor_y - (i % 5)
		# Hit the floor
		if positions[i].y > my_floor:
			positions[i].y = my_floor 
			
			velocities[i].y *= -0.3 
			
		# Hit the left wall
		if positions[i].x < left_wall:
			positions[i].x = left_wall
			velocities[i].x *= -0.8 # Bounce and lose a little speed
			
		# Hit the right wall
		if positions[i].x > right_wall:
			positions[i].x = right_wall
			velocities[i].x *= -0.8
			
		# 2. Friction: brutally slow the particles down so they form a puddle
		# (Lower the 5.0 if you want them to slide further on the ground)
		velocities[i] = velocities[i].lerp(Vector2.ZERO, 4.0 * delta)
			
		# 3. Move the particle
		positions[i] += velocities[i] * delta
		
		# --- ELEMENTAL INTERACTIONS ---
		var destroyed = false
		
		# Fast check: Only moving projectiles trigger reactions, saves CPU
		if (elements[i] == 1 or elements[i] == 2) and velocities[i].length_squared() > 1000:
			for j in range(positions.size()):
				if i == j: 
					continue
					
				if (elements[i] == 1 and elements[j] != 2) or (elements[i] == 2 and elements[j] != 1):
					continue # Skip to the next particle instantly
				
				# If they crash into each other
				if positions[i].distance_squared_to(positions[j]) < 400:
					
					# Fire (1) + Water (2) = Steam (3)
						# Transform the puddle particle (j) into Steam
						elements[j] = 3
						colors[j] = Color(0.5, 0.5, 0.5, 0.5) # Grey with 0.5 Alpha
						lifespans[j] = 8.0
						
						# Give it a little pop upwards so it starts floating immediately
						velocities[j] = Vector2(0, -150) 
						
						# Mark the bullet (i) for death
						destroyed = true
						break
						
		# If the bullet was destroyed in a reaction, delete it and skip the rest of the loop
		if destroyed:
			delete_particle(i)
			i -= 1
			continue
		# ------------------------------
		
		# 4. Check for player collision  against everyone

		var hit_someone = false
		if lifespans[i] < 9.9 and elements[i] < 3:
			for target in targets:
				if target != null and target.base_element != elements[i]:  #and target.has_method("take_damage"):
					if positions[i].distance_squared_to(target.global_position) < hit_radius_squared:
						# (Optional: Add a check here if you don't want players hurt by their own elements)
						if target.has_method("take_damage"):
							target.take_damage(1) 
						hit_someone = true
						break # Stop checking other players if it already exploded
				
		if hit_someone:
			delete_particle(i)
			i -= 1
			continue
									
		# 5. Tell the GPU where to draw it
		var transformed = Transform2D( 0,  multi_mesh_node.to_local(positions[i]))
		multi_mesh_node.multimesh.set_instance_transform_2d(i, transformed)
		
		# Tell the GPU what color to paint it
		multi_mesh_node.multimesh.set_instance_color(i, colors[i])
		
		i -= 1 
		
	# 6. Update the visible count for the graphics card
	multi_mesh_node.multimesh.visible_instance_count = positions.size()

# Helper function to keep the loop clean and prevent memory desyncs
func delete_particle(index: int):
	positions.remove_at(index)
	velocities.remove_at(index)
	lifespans.remove_at(index)
	colors.remove_at(index)    
	elements.remove_at(index)
