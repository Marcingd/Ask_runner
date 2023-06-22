extends CharacterBody2D


var light_intensity = 0.0
var glow_transparency = 0.0

# Zmienne do śledzenia odległości
const PIXELS_PER_METER = 277.0
var starting_position = Vector2.ZERO
var distance_traveled = 0.0

var jumps_done: int = 0
const MAX_JUMPS: int = 2

# Referencje do obiektów w scenie
@onready var double_jump_particles = $participle/double_jump_particles
@onready var glow = $Light
@onready var light = $PointLight2D
@onready var distance_label = $CanvasLayer/Label
@onready var floor_ray = $floor_ray
@onready var jump_button = $CanvasLayer/jump_button
@onready var reset_button = $CanvasLayer/reset_button

# Zmienne ruchu
@export var speed: float = 1000
@export var max_speed: float = 5000
var current_speed: float = 0.0
@export var damping: float = 0.88
@export var gravity: float = 80
@export var min_jump_speed: float = -100
@export var jump_speed: float = -3000
@export_range(0.0, 1.0) var friction: float = 0.1
@export_range(0.0, 20.0) var acceleration: float = 20
@export var slide_deceleration: float = 0.015

# Komponenty
@onready var anim_tree = $AnimationTree
@onready var edge_grab_ray = $EdgeGrabRay
@onready var fall_check_ray = $FallCheckRay

# Progi upadku
@export var low_fall_speed_threshold: float = 800
@export var high_fall_speed_threshold: float = 1600

# Zmienne
var jumped: bool = false
var is_grabbing = false
var climb_speed = 2000
var motion := Vector2.ZERO
var is_sliding = false
var just_landed: bool = false

@onready var joystick = $CanvasLayer/virtual_joystick

# Funkcja wywoływana podczas inicjalizacji postaci
func _ready() -> void:
	set_floor_max_angle(deg_to_rad(120)) # Ustawia maksymalny kąt podłogi na 50 stopni
	position = Vector2.ZERO
	anim_tree.active = true
	starting_position = position

# Funkcja wywoływana podczas każdej klatki fizyki gry
func _physics_process(delta: float) -> void:
	update_light_and_glow()  # Aktualizuje światło i efekt świecenia
	if joystick.deflection_percentage != null:
		update_speed(joystick.deflection_percentage)  # Aktualizuje prędkość postaci na podstawie deflekcji joysticka
	handle_motion()  # Obsługuje ruch postaci
	handle_vertical_movement(delta)  # Obsługuje pionowy ruch postaci
	handle_falling_animation()  # Obsługuje animację upadku
	handle_jumping()  # Obsługuje skoki postaci
	move_character()  # Porusza postacią
	update_distance_traveled()  # Aktualizuje przePrzepraszam za wcześniejsze przerwanie. Kontynuuję:
	reset_scene()

# Funkcja obsługująca wejścia użytkownika
func _input(event):
	if event.is_action_pressed("jump") or (jump_button and jump_button.is_pressed()):
		on_jump_button_pressed()  # Wywołuje funkcję skoku

	if event.is_action_pressed("reset") or (reset_button and reset_button.is_pressed()):
		get_tree().reload_current_scene()  # Przeładowuje aktualną scenę



# Funkcja wywoływana po naciśnięciu przycisku skoku
#func on_jump_button_pressed():
#	if is_on_floor() or jumps_done < MAX_JUMPS:
#		motion.y = jump_speed  # Ustawia prędkość skoku
#		jumped = true  # Ustawia flagę skoku na prawdę
#		if is_on_floor():
#			jumps_done = 1  # Zwiększa licznik skoków
#		else:
#			jumps_done += 1  # Zwiększa licznik skoków
#			if not double_jump_particles.emitting:
#				double_jump_particles.restart()  # Restartuje emisję cząsteczek, jeśli nie jest aktywna
#			else:
#				double_jump_particles.emitting = true  # Aktywuje cząsteczki tylko przy skoku w powietrzu
#		anim_tree["parameters/state/transition_request"] = "jump"  # Zmienia stan animacji na "jump"
#		$Timers/grounded_timer.stop()  # Zatrzymuje odliczanie czasu od ostatniego kontaktu z ziemią
#		print(jumps_done)

# Funkcja wywoływana po naciśnięciu przycisku skoku

# Funkcja wywoływana po naciśnięciu przycisku skoku
func on_jump_button_pressed():
	if !$Timers/jump_press_timer.is_stopped():
		return
	if is_on_floor() or jumps_done < MAX_JUMPS:
		motion.y = jump_speed  # Ustawia prędkość skoku
		jumped = true  # Ustawia flagę skoku na prawdę
		jumps_done += 1  # Zwiększa licznik skoków
		if jumps_done >= 1 and not is_on_floor() and not double_jump_particles.emitting:
			double_jump_particles.restart()  # Restartuje emisję cząsteczek, jeśli nie jest aktywna
		anim_tree["parameters/state/transition_request"] = "jump"  # Zmienia stan animacji na "jump"
		$Timers/jump_press_timer.start()  # Rozpoczyna odliczanie czasu skoku
		$Timers/grounded_timer.stop()  # Zatrzymuje odliczanie czasu od ostatniego kontaktu z ziemią
		print(jumps_done)





# Funkcja obsługująca ruch postaci
func handle_motion() -> void:
	if !is_sliding:
		motion.x = current_speed  # Używa zmiennej 'current_speed' zamiast stałej prędkości
	anim_tree["parameters/TimeScale_run/scale"] = (motion.x / max_speed)*1.5  # Skaluje prędkość animacji biegu

	if is_on_floor():
		if abs(motion.x) < 0.1:
			anim_tree["parameters/state/transition_request"] = "idle"  # Zmienia stan animacji na "idle"
		else:
			anim_tree["parameters/state/transition_request"] = "run"  # Zmienia stan animacji na "run"

	if is_on_floor() and abs(motion.x) < 1:
		anim_tree["parameters/state/transition_request"] = "idle"  # Zmienia stan animacji na "idle"

# Funkcja obsługująca pionowy ruch postaci
func handle_vertical_movement(delta: float) -> void:
	if is_on_floor():
		handle_grounding()  # Obsługuje kontakt postaci z ziemią
	else:
		motion.y += gravity  # Dodaje grawitację do ruchu pionowego


# Funkcja obsługująca kontakt postaci z ziemią
func handle_grounding() -> void:
	if jumped:  # Jeśli postać właśnie skoczyła
		$Timers/grounded_timer.start()  # Rozpoczyna odliczanie czasu od ostatniego kontaktu z ziemią
		just_landed = true  # Ustawia flagę lądowania na prawdę
		double_jump_particles.emitting = false  # Zatrzymuje emisję cząsteczek po wylądowaniu na ziemi
		jumped = false  # Resetuje flagę skoku
	else:
		jumps_done = 0  # Resetuje licznik skoków tylko po skoku







# Funkcja obsługująca ślizganie się postaci
func handle_sliding() -> void:
	if Input.is_action_pressed("slide"):
		if !is_sliding:
			is_sliding = true  # Ustawia flagę ślizgania na prawdę
		anim_tree["parameters/state/transition_request"] = "slide"  # Zmienia stan animacji na "slide"
		motion.x = lerp(motion.x, 0.0, slide_deceleration)  # Zmniejsza prędkość postaci podczas ślizgania
	else:
		is_sliding = false  # Resetuje flagę ślizgania
		anim_tree["parameters/state/transition_request"] = "run"  # Zmienia stan animacji na "run"

# Funkcja obsługująca chwytanie i wspinanie się po krawędziach
func handle_edge_grabbing_and_climbing() -> void:
	if !is_on_floor() and !is_grabbing and edge_grab_ray.is_colliding():
		is_grabbing = true  # Ustawia flagę chwytania na prawdę
	if is_grabbing:
		motion.y = -climb_speed  # Ustawia prędkość wspinania
		anim_tree["parameters/state/transition_request"] = "climb"  # Zmienia stan animacji na "climb"
		if !edge_grab_ray.is_colliding():
			is_grabbing = false  # Resetuje flagę chwytania

# Funkcja obsługująca animację upadku
func handle_falling_animation() -> void:
	if !is_on_floor():
		check_fall_animation()  # Sprawdza, czy powinna być wyświetlana animacja upadku

# Funkcja sprawdzająca, czy powinna być wyświetlana animacja upadku
func check_fall_animation() -> void:
	if fall_check_ray.is_colliding():
		if motion.y > low_fall_speed_threshold and motion.y <= high_fall_speed_threshold:
			anim_tree.set("parameters/Fall/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)  # Wywołuje animację upadku
		elif motion.y > high_fall_speed_threshold:
			anim_tree.set("parameters/FallHigh/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)  # Wywołuje animację wysokiego upadku

# Funkcja obsługująca skoki postaci
func handle_jumping() -> void:
	if !$Timers/jump_press_timer.is_stopped() and !$Timers/grounded_timer.is_stopped():
		motion.y = jump_speed  # Ustawia prędkość skoku
		jumped = true  # Ustawia flagę skoku na prawdę
		anim_tree["parameters/state/transition_request"] = "jump"  # Zmienia stan animacji na "jump"
		$Timers/jump_press_timer.stop()  # Zatrzymuje odliczanie czasu od naciśnięcia przycisku skoku
		$Timers/grounded_timer.stop()  # Zatrzymuje odliczanie czasu od ostatniego kontaktu z ziemią

# Funkcja poruszająca postacią
func move_character() -> void:
	set_velocity(motion)  # Ustawia prędkość postaci
	set_up_direction(Vector2.UP)  # Ustawia kierunek "góry" postaci
	move_and_slide()  # Porusza postacią z uwzględnieniem kolizji
	motion = velocity  # Aktualizuje

	motion = velocity  # Aktualizuje ruch postaci na podstawie jej prędkości

# Funkcja aktualizująca przebytą odległość
func update_distance_traveled() -> void:
	distance_traveled = (position.x - starting_position.x) / PIXELS_PER_METER  # Oblicza przebytą odległość
	distance_label.text = " %.2f m" % distance_traveled  # Aktualizuje tekst etykiety odległości

# Funkcja aplikująca grawitację na nachylonych powierzchniach
func apply_slope_gravity(delta: float) -> void:
	var floor_normal = get_floor_normal()  # Pobiera normalną powierzchni pod postacią
	if floor_normal != Vector2.UP:  # Jeśli powierzchnia jest nachylona
		var slope_angle = acos(floor_normal.y)  # Oblicza kąt nachylenia powierzchni
		var slope_gravity_multiplier = max(0.0, 1.0 - slope_angle / PI)  # Oblicza mnożnik grawitacji
		var slope_gravity = gravity * abs(floor_normal.y) * slope_gravity_multiplier  # Oblicza dodatkową siłę grawitacji
		motion.y += slope_gravity * delta  # Dodaje dodatkową siłę grawitacji do ruchu pionowego

# Funkcja aktualizująca rotację postaci
func update_rotation() -> void:
	if is_on_floor():
		var floor_normal = get_floor_normal()  # Pobiera normalną powierzchni pod postacią
		var target_rotation_angle = atan2(-floor_normal.y, -floor_normal.x) - PI / 2  # Oblicza kąt rotacji na podstawie normalnej powierzchni
		var rotation_angle = lerp($Luminos_Skeleton.rotation, target_rotation_angle, 0.1)  # Interpoluje kąt rotacji
		$Luminos_Skeleton.rotation = rotation_angle  # Ustawia rotację szkieletu postaci
		$polygons.rotation = rotation_angle  # Ustawia rotację poligonów
	else:
		rotation = lerp(rotation, 0.0, 0.1)  # Interpoluje rotację postaci do 0

# Funkcja aktualizująca prędkość postaci
func update_speed(speed_percentage: float) -> void:
	if speed_percentage != null:
		current_speed = max_speed * speed_percentage / 100  # Oblicza aktualną prędkość na podstawie procentu deflekcji joysticka

# Funkcja aktualizująca światło i efekt świecenia
func update_light_and_glow() -> void:
	var speed_ratio = current_speed / max_speed  # Oblicza stosunek prędkości

	# Sprawdza, czy wartości muszą być zaktualizowane
	if abs(light_intensity - speed_ratio * 5) > 0.01:
		light_intensity = speed_ratio * 5  # Oblicza intensywność światła
		light.energy = light_intensity  # Ustawia jasność światła

	if abs(glow_transparency - speed_ratio / 3) > 0.01:
		glow_transparency = speed_ratio / 3  # Oblicza przezroczystość świecenia
		var glow_color = glow.modulate
		glow_color.a = glow_transparency
		glow.modulate = glow_color  # Ustawia przezroczystość świecenia

	# Ustawia skalę tekstury światła w PointLight2D
	light.texture_scale = speed_ratio * 5 # Zakładając, że chcesz skalować teksturę

	# Ustawia skalę efektu świecenia
	glow.scale = Vector2(speed_ratio * 2, speed_ratio * 2)


func reset_scene():
	if position.y > 1500:
		get_tree().reload_current_scene()
