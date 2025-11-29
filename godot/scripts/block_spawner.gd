extends Node2D

# --- CONFIGURATION ---
# Drag your Block_L.tscn, Block_T.tscn, etc. here in the Inspector
@export var block_scenes: Array[PackedScene] = [
	preload("res://scenes/block_I.tscn"),
	preload("res://scenes/block_J.tscn"),
	preload("res://scenes/block_T.tscn"),
	#preload("res://scenes/block_O.tscn"), #YOU DON'T DESERVE TO BE HERE
	preload("res://scenes/block_S.tscn"),
	preload("res://scenes/block_Z.tscn"),
	preload("res://scenes/block_L.tscn"),
]



# Load your 16x16 textures
# Adjust paths to match your actual folders
var tex_hell = preload("res://Asset/Starter Tiles Platformer/FireTiles/Fire_14_32x32.png")
var tex_purgatory = preload("res://Asset/background 2/purgatory_block.png")
var tex_heaven = preload("res://Asset/Clouds_white/cloud_shape4_1.png")

# --- INITIALIZATION ---
func _ready():
	# Wait 1 second before starting so the player gets ready
	await get_tree().create_timer(1.0).timeout
	spawn_new_block()

# --- SPAWN LOGIC ---
func spawn_new_block():
	if block_scenes.is_empty():
		print("Error: No scenes assigned to Spawner!")
		return
	
	# 1. Instantiate a random block
	var new_block = block_scenes.pick_random().instantiate()
	
	# 2. Add it to the main world (Root)
	# We DO NOT add it as a child of the spawner, otherwise 
	# the falling block would move up when the camera moves up.
	get_tree().root.add_child(new_block)
	
	# 3. Position it at the spawner's location
	new_block.global_position = global_position
	
	# 4. DETERMINE THEME BASED ON HEIGHT
	# In Godot 2D, "Up" is negative Y.
	# Adjust these values based on your map height.
	var current_y = global_position.y
	var selected_texture = tex_hell # Default (Bottom)
	
	if current_y < -2000:
		selected_texture = tex_heaven
	elif current_y < -1000:
		selected_texture = tex_purgatory
	#
	# 5. APPLY THEME
	if new_block.has_method("apply_visual_theme"):
		new_block.apply_visual_theme(selected_texture)

# --- SIGNAL LISTENER ---
# This is called by the Falling Blocks via "call_group"
func on_block_locked():
	# Add a tiny delay so the next block doesn't appear 
	# the instant the previous one lands (feels better)
	call_deferred("_spawn_delayed")

func _spawn_delayed():
	await get_tree().create_timer(0.2).timeout
	spawn_new_block()
