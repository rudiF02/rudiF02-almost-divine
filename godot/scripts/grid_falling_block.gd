extends CharacterBody2D

#to put in config file
const TILE_SIZE = 32
const TICK_SPEED = 0.5
const FAST_DROP_SPEED = 0.05

enum State { FALLING, LOCKED }
var current_state = State.FALLING
var time_since_last_tick = 0.0
var current_tick_speed = TICK_SPEED


func _physics_process(delta):
	if current_state == State.LOCKED: return

	if Input.is_action_pressed("b_fast_fall"):
		current_tick_speed = FAST_DROP_SPEED
	else:
		current_tick_speed = TICK_SPEED
		
	time_since_last_tick += delta
	
	# controlla la posizione
	# se <= 0 allora incrocia con il top
		# se state.locked allora perso
	
	if time_since_last_tick >= current_tick_speed:
		time_since_last_tick = 0
		move_grid(Vector2.DOWN)

func _unhandled_input(event):
	if current_state != State.FALLING: return
	
	if event.is_action_pressed("move_right_block"):
		move_grid(Vector2.RIGHT)
	elif event.is_action_pressed("move_left_block"):
		move_grid(Vector2.LEFT)
	elif event.is_action_pressed("rotate_block"):
		rotate_grid()

func move_grid(direction: Vector2):
	var motion_vector = direction * TILE_SIZE
	
	var collision = test_move(transform, motion_vector)
	
	if not collision:
		position += motion_vector
	else:
		#when hitting anything we lock the tile
		if direction == Vector2.DOWN:
			lock_block()

func rotate_grid():
	rotation_degrees += 90
	#if rotation puts th tile inside a wall, undo it
	if test_move(transform, Vector2.ZERO):
		rotation_degrees -= 90

func lock_block():
	current_state = State.LOCKED
	
	#adapt to grid
	position.x = round(position.x / TILE_SIZE) * TILE_SIZE
	position.y = round(position.y / TILE_SIZE) * TILE_SIZE
	
	# CHANGE LAYERS: Become "Floor" (Layer 4)
	# Note: Bit 3 is Value 4. Bit 4 is Value 8.
	collision_layer = 8 # Layer 4
	collision_mask = 0
	
	# Notify Spawner
	get_tree().call_group("Spawner", "on_block_locked")

func apply_visual_theme(new_texture: Texture2D):
	for child in get_children():
		if child is Sprite2D:
			child.texture = new_texture
