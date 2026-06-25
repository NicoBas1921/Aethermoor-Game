extends CharacterBody2D

signal vida_cambiada(nueva_vida)

const SPEED = 100.0
const ALTURA_SALTITO = 5.0
const VELOCIDAD_ANIMACION = 18.0
const RANGO_ATAQUE = 80.0
const VIDA_MAXIMA = 100
const ESCENA_GAME_OVER = "res://GameOver.tscn"

@onready var sprite: Sprite2D = $Sprite2D

var salud_jugador = VIDA_MAXIMA
var jugador_muerto = false
var tiempo_caminando = 0.0
var objetivo_actual = null


func _ready():
	aplicar_frame_personaje()
	vida_cambiada.emit(salud_jugador)


func _physics_process(delta):
	var direccion = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direccion != Vector2.ZERO:
		velocity = direccion * SPEED
		tiempo_caminando += delta * VELOCIDAD_ANIMACION
		if sprite:
			sprite.position.y = -abs(sin(tiempo_caminando)) * ALTURA_SALTITO
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		tiempo_caminando = 0.0
		if sprite:
			sprite.position.y = move_toward(sprite.position.y, 0.0, 40.0 * delta)

	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		atacar_objetivo()


func aplicar_frame_personaje():
	if not sprite:
		return

	sprite.hframes = 54
	sprite.vframes = 12

	if not has_node("/root/Global"):
		return

	var global_data = get_node("/root/Global")
	sprite.frame_coords = Vector2i(global_data.frame_seleccionado)


func atacar_objetivo():
	if objetivo_actual == null or objetivo_actual.esta_muerto:
		print("No tenes ningun objetivo vivo seleccionado.")
		return

	var distancia = global_position.distance_to(objetivo_actual.global_position)

	if distancia <= RANGO_ATAQUE:
		print("Le pegaste al orco.")
		objetivo_actual.recibir_dano(25)
	else:
		print("Demasiado lejos para atacar. Acercate mas.")


func recibir_dano_jugador(cantidad):
	if jugador_muerto:
		return

	salud_jugador = max(salud_jugador - cantidad, 0)
	vida_cambiada.emit(salud_jugador)
	print("TU SALUD: ", salud_jugador)

	# Destello rojo de daño
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)

	# Lógica de muerte
	if salud_jugador <= 0:
		jugador_muerto = true
		get_tree().change_scene_to_file(ESCENA_GAME_OVER)
	if jugador_muerto:
		return

	salud_jugador = max(salud_jugador - cantidad, 0)
	vida_cambiada.emit(salud_jugador)
	print("TU SALUD: ", salud_jugador)

	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if not jugador_muerto:
		modulate = Color(1, 1, 1)

	if salud_jugador <= 0:
		morir_jugador()


func morir_jugador():
	if jugador_muerto:
		return

	jugador_muerto = true
	velocity = Vector2.ZERO
	modulate = Color(0.1, 0.1, 0.1)
	set_physics_process(false)
	print("--- HAS MUERTO --- Game Over")
	get_tree().change_scene_to_file(ESCENA_GAME_OVER)
