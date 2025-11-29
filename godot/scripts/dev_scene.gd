extends Node2D

# ==============================================================================
# --- CONFIGURAZIONE ---
# ==============================================================================
# ASSUNZIONE: Queste costanti devono essere le STESSE di grid_falling_block.gd
const TILE_SIZE = 16 
const GRID_WIDTH = 10 
const GRID_HEIGHT = 20

var grid = []            # Griglia logica per il controllo righe/punteggio (0 = vuoto)

# ASSUNZIONE: ID colore/tipo. Ogni pezzo istanziato dovrà avere questo ID.
# Dato che non possiamo modificarlo, dovremo impostarlo dopo lo spawn.
# Se il tuo collega non ha una var 'color_id' nello script, l'eliminazione 
# delle righe funzionerà, ma non saprai che tipo di blocco hai eliminato.
# Per ora, usiamo una mappa di ID per lo spawn.
const PIECE_IDS = {
	"I": 1, "J": 2, "L": 3, "O": 4, 
	"S": 5, "T": 6, "Z": 7
}

# --- Variabili dello Spawner ---
# Precarica tutte le scene dei Tetramini (ASSUMI che i file esistano)
const TETROMINO_SCENES = [
	preload("res://scenes/block_I.tscn"), # Associa l'ID 1
	preload("res://scenes/block_J.tscn"), # Associa l'ID 2
	preload("res://scenes/block_L.tscn"), # Associa l'ID 2
	preload("res://scenes/block_O.tscn"), # Associa l'ID 2
	preload("res://scenes/block_S.tscn"), # Associa l'ID 2
	preload("res://scenes/block_T.tscn"), # Associa l'ID 2
	preload("res://scenes/block_Z.tscn"), # Associa l'ID 2
]

# ==============================================================================
# --- FUNZIONI VITA DEL NODO ---
# ==============================================================================

func _ready():
	# Aggiunge questo nodo al gruppo 'Spawner' in modo che il pezzo bloccato
	# possa chiamare on_block_locked()
	add_to_group("Spawner") 
	
	initialize_grid()
	randomize() 
	
	spawn_new_tetromino()

# ==============================================================================
# --- INIZIALIZZAZIONE & SPAWNING ---
# ==============================================================================

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
	
	# 2. Istanzia e aggiungi
	var new_tetromino_node = tetromino_scene.instantiate()
	add_child(new_tetromino_node)
	
	# 3. Imposta l'ID colore (se la variabile esiste nel suo script)
	# Se il tuo collega ha var color_id, questo funziona.
	# new_tetromino_node.color_id = rng_index + 1 
	
	# 4. Posizionamento in Pixel (Al centro in alto)
	# Calcola la posizione al centro della griglia e alinea alla cella.
	var spawn_x = float(GRID_WIDTH) / 2.0 * TILE_SIZE 
	var spawn_y = 0.0
	
	# Allinea perfettamente all'origine della griglia
	new_tetromino_node.position = Vector2(spawn_x, spawn_y)
	
	# Il pezzo del tuo collega inizia la caduta automatica subito dopo lo spawn.
	
# ==============================================================================
# --- GESTIONE DEL BLOCCO (LOCK HANDLER) ---
# ==============================================================================

# Questa funzione viene chiamata dal Tetramino quando esegue lock_block()
func on_block_locked():
	# 1. Trova il pezzo che si è bloccato (è l'unico ad avere Layer 4/Value 8)
	var locked_tetromino = find_locked_tetromino()

	if locked_tetromino:
		# 2. Trasferisce i dati dal pezzo fisico alla griglia logica
		update_grid_after_lock(locked_tetromino)
		
		# 3. Controlla e Pulisci le Righe
		var cleared_lines = check_for_lines() 
		
		# 4. Gestione del Game Over (se il pezzo bloccato è troppo in alto)
		# ... (Logica Game Over) ...
		
	# 5. Spawna il pezzo successivo
	spawn_new_tetromino()
	
func find_locked_tetromino():
	# Cerca il nodo CharacterBody2D che ha il collision_layer 8 (come impostato dal collega)
	for child in get_children():
		if child is CharacterBody2D and child.collision_layer == 8:
			return child
	return null

func update_grid_after_lock(locked_tetromino):
	# Dobbiamo derivare la forma e la posizione dalla geometria del nodo del collega.
	
	# 1. Ottieni la posizione in griglia del pezzo bloccato
	# Usiamo 'position' del nodo, che è già allineata dal lock_block() del collega.
	var origin_x = round(locked_tetromino.position.x / TILE_SIZE)
	var origin_y = round(locked_tetromino.position.y / TILE_SIZE)
	
	# 2. Ottieni i dati della forma (coordinate relative)
	var color_id = 1 # ID di default, da migliorare con una var nel suo script
	if locked_tetromino.has_method("get_color_id"):
		color_id = locked_tetromino.get_color_id() # ASSUNZIONE: se implementa una get
	
	# Creiamo una forma relativa iterando sui figli del pezzo (i 4 blocchi Sprite/ColorRect)
	var shape = []
	for child in locked_tetromino.get_children():
		if child is Sprite2D or child is ColorRect: # ASSUNZIONE: usa Sprite2D o ColorRect
			# Conversione posizione relativa del figlio in coordinate griglia
			var cell_x = round(child.position.x / TILE_SIZE) 
			var cell_y = round(child.position.y / TILE_SIZE)
			shape.append(Vector2(cell_x, cell_y))

	# 3. Fissa nella tua griglia logica
	for cell in shape:
		var x = int(origin_x + cell.x)
		var y = int(origin_y + cell.y)
		
		if y >= 0 and x >= 0 and x < GRID_WIDTH and y < GRID_HEIGHT:
			grid[y][x] = color_id 

# ==============================================================================
# --- LOGICA DELLE RIGHE (Cruciale per il gioco) ---
# ==============================================================================

func check_for_lines():
	var lines_cleared = 0
	var rows_to_remove = []

	# 1. Identifica le righe complete
	for y in range(GRID_HEIGHT):
		var is_full = true
		for x in range(GRID_WIDTH):
			if grid[y][x] == 0:
				is_full = false
				break
		
		if is_full:
			rows_to_remove.append(y)
			lines_cleared += 1

	# 2. Se ci sono righe da eliminare
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
			
		# 5. AGGIORNA TUTTI I BLOCCHI FISSI (Visualizzazione)
		reposition_all_locked_blocks()
		
	return lines_cleared

# 7. La funzione di riposizionamento Visivo (Necessaria dopo la pulizia righe)
func reposition_all_locked_blocks():
	# Questa funzione si occupa di far "cadere" tutti i pezzi bloccati
	# in base alla nuova griglia logica.

	# ⚠️ Questo è un punto complesso, dato che non controlli i pezzi bloccati.
	# Dobbiamo distruggere i vecchi pezzi bloccati e ricrearli/riposizionarli
	# in base ai dati della griglia.
	
	# Per semplificare la demo, rimuoviamo solo quelli bloccati.
	for child in get_children():
		if child is CharacterBody2D and child.collision_layer == 8:
			child.queue_free()
			
	# 
	# VERO IMPLEMENTAZIONE: Iterare sulla griglia 'grid' e istanziare
	# nuovi TileMap o blocchi statici (Layer 4) per ricostruire il campo
	# in base ai nuovi indici y nella griglia.
	print("⚠️ Rimosso l'aggiornamento visivo dei blocchi fissi per la dimostrazione. Implementare qui la ricostruzione della griglia visiva.")
