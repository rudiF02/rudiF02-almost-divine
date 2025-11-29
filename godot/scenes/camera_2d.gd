extends Camera2D

# Adjust this to the horizontal center of your map.
@export var fixed_x_position: float = 0.0

# The exact width of your map in pixels.
@export var target_map_width: float = 320.0

# Extra buffer below the screen bottom before the player dies (The "Offset")
@export var killzone_buffer: float = 100.0

# This tracks the highest point (Lowest Y) the player has reached.
var min_reached_y: float = 99999.0

# Drag your BlockSpawner node here in the Inspector
@onready var spawner_node: Node2D = $BlockSpawner

# We get the player (Parent) to check their position for death logic
@onready var player: CharacterBody2D = $".."

func _ready():
	position_smoothing_enabled = false
	top_level = true
	
	global_position.x = fixed_x_position
	
	# Initialize min_reached_y with the starting position
	if get_parent():
		min_reached_y = get_parent().global_position.y
		global_position.y = min_reached_y

	# --- ZOOM & SPAWNER CALCULATION ---
	var viewport_rect = get_viewport_rect().size
	var zoom_factor = viewport_rect.x / target_map_width
	
	zoom = Vector2(zoom_factor, zoom_factor)
	
	if spawner_node:
		var visible_world_height = viewport_rect.y / zoom_factor
		# Push spawner up 80% of screen height + buffer
		var top_edge_y = -(visible_world_height * 2.0) - 200.0
		spawner_node.position = Vector2(0, top_edge_y)

func _process(_delta):
	# 1. CAMERA FOLLOW (Standard Follow)
	if get_parent():
		var player_current_y = get_parent().global_position.y
		
		# The camera follows the player up AND down now
		global_position.y = player_current_y
		
		# 2. TRACK MAX HEIGHT (For the Killzone)
		# In Godot, UP is Negative. So we want the MINIMUM Y value.
		if player_current_y < min_reached_y:
			min_reached_y = player_current_y
	
	# 3. Lock Horizontally
	global_position.x = fixed_x_position
	
	# 4. DEATH CHECK (Based on Max Height)
	_check_killzone()

func _check_killzone():
	var kill_line_y = min_reached_y + killzone_buffer
	
	# Check if player is below the kill line
	if player and player.global_position.y > kill_line_y:
		if player.has_method("die"):
			print("Player hit the rising killzone!")
			player.die()
