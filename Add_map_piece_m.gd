extends CanvasLayer

# Stałe ze ścieżkami do scen z fragmentami mapy
const FRAGMENT_FOLDER = "res://Map_Segment/Player_layer/"

# Stała określająca odległość, po której fragmenty są usuwane za graczem
const REMOVE_DISTANCE = 1000

# Stała określająca ilość wstępnie załadowanych fragmentów
const PRELOADED_FRAGMENTS = 2

# Tablica przechowująca wczytane sceny fragmentów
var loaded_fragments = []

# Tablica przechowująca instancje utworzonych fragmentów
var created_fragments = []

# Tablica przechowująca pulę nieużywanych fragmentów
var fragment_pool = []

# Zmienna przechowująca węzeł gracza
var player = null

var last_fragment_index = -1

func _enter_tree():
	player = $Luminos

func _ready(): 
	# Wczytaj sceny fragmentów
	load_fragment_scenes()

	# Generuj początkowe fragmenty
	generate_initial_fragments()

func load_fragment_scenes():
	var dir = DirAccess.open(FRAGMENT_FOLDER)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				var scene_path = FRAGMENT_FOLDER + file_name
				loaded_fragments.append(load(scene_path))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	dir.list_dir_end()

func _process(_delta):
	# Sprawdź, czy fragmenty są za pozycją gracza i je usuń oraz dodaj nowe fragmenty przed graczem
	check_and_remove_fragments()

func generate_initial_fragments():
	# Generuje początkowe fragmenty na scenie
	for i in range(PRELOADED_FRAGMENTS):
		generate_fragment()
		
		
func generate_fragment():    
	# Wybiera losowy fragment z wczytanych scen, unikając powtórzenia ostatniego fragmentu
	var fragment_index = randi() % loaded_fragments.size()
	while fragment_index == last_fragment_index:
		fragment_index = randi() % loaded_fragments.size()
	last_fragment_index = fragment_index
	
	var fragment_scene = loaded_fragments[fragment_index]

	# Tworzy instancję fragmentu lub pobiera z puli
	var fragment_instance = null
	if fragment_pool.size() > 0:
		fragment_instance = fragment_pool.pop_front()
	else:
		fragment_instance = fragment_scene.instantiate()

#	# Ustawia pozycję fragmentu
#	if created_fragments.size() > 0:
#		# Ustawia pozycję nowego fragmentu na podstawie znacznika końca poprzedniego
#		var previous_end_marker = created_fragments[-1].get_node("EndMarker")
#		var start_marker = fragment_instance.get_node("StartMarker")
#		var position_difference = previous_end_marker.global_position - start_marker.position
#		# Nie zerujemy wartości y, aby start_marker był na wysokości end_marker poprzedniego fragmentu
#
##		fragment_instance.global_position = position_difference
#		fragment_instance.global_position = position_difference
#		fragment_instance.global_position.y = 0
#
#
#	else:
#		fragment_instance.position = Vector2(0, 0)


	# Ustawia pozycję fragmentu
	if created_fragments.size() > 0:
# Ustawia pozycję nowego fragmentu na podstawie znacznika końca poprzedniego
		var previous_end_marker = created_fragments[-1].get_node("EndMarker")
		var start_marker = fragment_instance.get_node("StartMarker")
		var position_difference = previous_end_marker.global_position - start_marker.position
		# Zerujemy wartość y, aby nowy fragment był na wysokości y = 0
		position_difference.y = 0
		fragment_instance.global_position = position_difference
	else:
		fragment_instance.position = Vector2(0, 0)



	# Dodaje fragment do węzła
	get_parent().call_deferred("add_child", fragment_instance)

	# Dodaje fragment do listy utworzonych fragmentów
	created_fragments.append(fragment_instance)


func check_and_remove_fragments():
	var i = 0
	while i < created_fragments.size():
		var fragment = created_fragments[i]
		var end_marker = fragment.get_node("EndMarker")
		if end_marker.global_position.x + REMOVE_DISTANCE < player.position.x:
			created_fragments.erase(fragment)
			get_parent().remove_child(fragment)
			fragment_pool.append(fragment)
		else:
			i += 1

	# Sprawdź, czy ostatni fragment jest wystarczająco blisko gracza, aby dodać kolejny
	var last_fragment_end_marker = created_fragments[-1].get_node("EndMarker")
	if last_fragment_end_marker.global_position.x - (REMOVE_DISTANCE * 2) < player.position.x:  # Zmieniona wartość REMOVE_DISTANCE
		generate_fragment()


