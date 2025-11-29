extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var is_dead: bool = false
const BLOCK_STATE_FALLING = 0
const BLOCK_STATE_LOCKED = 1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		print(collider)
		if "current_state" in collider:
			
			if collider.current_state == BLOCK_STATE_FALLING:
				print("Touched a falling block - DIE")
				die()
			



	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func die():
	if is_dead: return
	is_dead = true
	print("Game Over")
