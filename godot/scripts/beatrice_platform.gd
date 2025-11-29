extends StaticBody2D

# Configure the message
@export var dialogue: String = "Oh, Dante... I think we work better as friends."

func _ready():
	# Ensure the animation plays
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")
	
	# Connect the Area2D signal via code (or do it in the editor)
	# Assuming your Area2D node is named "Area2D"
	if has_node("Area2D"):
		$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the body is Dante (by Group or Name)
	if body.is_in_group("Player") or body.name == "Dante":
		_trigger_friendzone(body)

func _trigger_friendzone(player):
	print("--- ENDING TRIGGERED ---")
	print("Beatrice: ", dialogue)
	
	# THE TWIST: Break the stairs / Make Dante Fall
	# We do this by disabling Dante's collision with the Blocks Layer.
	
	# Dante's Mask was: 1 (World) + 4 (Blocks) + 3 (Falling)
	# We set it to ONLY 1 (World/Walls), so he phases through the stairs he built.
	player.collision_mask = 1 
	
	# Visual feedback
	if player.has_node("Sprite2D"):
		player.get_node("Sprite2D").modulate = Color(0.5, 0.5, 1.0) # Turn him blue (Sad)
	
	# Optional: Apply a small push if he is standing still
	player.velocity.y = 100
