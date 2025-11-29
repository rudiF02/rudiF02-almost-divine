extends Camera2D

@export var fixed_x_position: float = 0.0

@export var target_map_width: float = 320.0

# Drag your BlockSpawner node here in the Inspector
@onready var spawner_node: Node2D = $BlockSpawner

func _ready():
	# Allow the camera to act independently of the parent's rotation/scale
	top_level = true
	
	# Set the initial X
	global_position.x = fixed_x_position
	
	var viewport_rect = get_viewport_rect().size
	var zoom_factor = viewport_rect.x / target_map_width
	
	# Apply the calculated zoom
	zoom = Vector2(zoom_factor, zoom_factor)
	
	if spawner_node:
		# Calculate the height of the visible world area
		var visible_world_height = viewport_rect.y / zoom_factor
		
		var top_edge_y = -(visible_world_height * 3) - 64.0
		
		spawner_node.position = Vector2(0, top_edge_y)
		
		print("Spawner positioned at local Y: ", top_edge_y)

func _process(_delta):
	if get_parent():
		global_position.y = get_parent().global_position.y
	
	global_position.x = fixed_x_position
