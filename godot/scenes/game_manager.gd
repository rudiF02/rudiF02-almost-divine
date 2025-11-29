extends Node2D


const TILE_SIZE = 16 
const GRID_WIDTH = 10 
const GRID_HEIGHT = 20

var grid = []            # Griglia logica per il controllo righe/punteggio (0 = vuoto)

const PIECE_IDS = {
	"I": 1, "J": 2, "L": 3, "O": 4, 
	"S": 5, "T": 6, "Z": 7
}

const TETROMINO_SCENES = [
	preload("res://scenes/block_I.tscn"), # Associa l'ID 1
	preload("res://scenes/block_J.tscn"), # Associa l'ID 2
	preload("res://scenes/block_L.tscn"), # Associa l'ID 2
	preload("res://scenes/block_O.tscn"), # Associa l'ID 2
	preload("res://scenes/block_S.tscn"), # Associa l'ID 2
	preload("res://scenes/block_T.tscn"), # Associa l'ID 2
	preload("res://scenes/block_Z.tscn"), # Associa l'ID 2
]

func _ready():

	add_to_group("Spawner") 
	
	initialize_grid()
	randomize() 
	
	spawn_new_tetromino()

#INIZIALIZZA E SPAWNA

func initialize_grid():
	# Inizializza la griglia a 0 (vuota)
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(0)
		grid.append(row)

func spawn_new_tetromino():
	# 1. Scegli casualmente una scena
	var rng_index = randi() % TETROMINO_SCENES.size()
	var tetromino_scene = TETROMINO_SCENES[rng_index]
	
	var new_tetromino_node = tetromino_scene.instantiate()
	add_child(new_tetromino_node)
	
	var spawn_x = float(GRID_WIDTH) / 2.0 * TILE_SIZE 
	var spawn_y = 0.0
	
	# Allinea perfettamente all'origine della griglia
	new_tetromino_node.position = Vector2(spawn_x, spawn_y)
	
	# Il pezzo del tuo collega inizia la caduta automatica subito dopo lo spawn.
	
#GESTIONE BLOCCO

# Questa funzione viene chiamata dal Tetramino quando esegue lock_block()
func on_block_locked():
	# 1. Trova il pezzo che si è bloccato (è l'unico ad avere Layer 4/Value 8)
	var locked_tetromino = find_locked_tetromino()

	if locked_tetromino:
		# 2. Trasferisce i dati dal pezzo fisico alla griglia logica
		update_grid_after_lock(locked_tetromino)
		
		# 3. Controlla e Pulisci le Righe
		var cleared_lines = check_for_lines() 

	spawn_new_tetromino()
	
func find_locked_tetromino():
	# Cerca il nodo CharacterBody2D che ha il collision_layer 8 (come impostato dal collega)
	for child in get_children():
		if child is CharacterBody2D and child.collision_layer == 8:
			return child
	return null

func update_grid_after_lock(locked_tetromino):
	# Dobbiamo derivare la forma e la posizione dalla geometria del nodo del collega.
	
	var origin_x = round(locked_tetromino.position.x / TILE_SIZE)
	var origin_y = round(locked_tetromino.position.y / TILE_SIZE)
	
	var color_id = 1 # ID di default, da migliorare con una var nel suo script
	if locked_tetromino.has_method("get_color_id"):
		color_id = locked_tetromino.get_color_id()
	
	var shape = []
	for child in locked_tetromino.get_children():
		if child is Sprite2D or child is ColorRect:
			# Conversione posizione relativa del figlio in coordinate griglia
			var cell_x = round(child.position.x / TILE_SIZE) 
			var cell_y = round(child.position.y / TILE_SIZE)
			shape.append(Vector2(cell_x, cell_y))

	for cell in shape:
		var x = int(origin_x + cell.x)
		var y = int(origin_y + cell.y)
		
		if y >= 0 and x >= 0 and x < GRID_WIDTH and y < GRID_HEIGHT:
			grid[y][x] = color_id 

#LOGICA LINEE

func check_for_lines():
	var lines_cleared = 0
	var rows_to_remove = []

	for y in range(GRID_HEIGHT):
		var is_full = true
		for x in range(GRID_WIDTH):
			if grid[y][x] == 0:
				is_full = false
				break
		
		if is_full:
			rows_to_remove.append(y)
			lines_cleared += 1

	if lines_cleared > 0:
		rows_to_remove.reverse() # Inizia dall'ultima riga
		
		# 3. Rimuovi le righe dall'array logico (grid)
		for y_index in rows_to_remove:
			grid.remove_at(y_index)
			
		# 4. Aggiungi nuove righe vuote in cima
		for i in range(lines_cleared):
			var new_row = []
			for x in range(GRID_WIDTH):
				new_row.append(0)
			grid.insert(0, new_row)
			
		reposition_all_locked_blocks()
		
	return lines_cleared

func reposition_all_locked_blocks():

	
	# Per semplificare la demo, rimuoviamo solo quelli bloccati.
	for child in get_children():
		if child is CharacterBody2D and child.collision_layer == 8:
			child.queue_free()
	
