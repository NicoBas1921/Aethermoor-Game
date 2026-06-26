extends CharacterBody2D

signal vida_cambiada(nueva_vida)
signal escudo_cambiado(nuevo_escudo)

const SPEED = 100.0
const TILE_SIZE = 16.0
const ALTURA_SALTITO = 5.0
const VELOCIDAD_ANIMACION = 18.0
const VIDA_MAXIMA = 100
const ESCUDO_MAXIMO = 100
const ESCENA_GAME_OVER = "res://GameOver.tscn"
const ESCENA_PROYECTIL_MAGA = preload("res://ProyectilMaga.tscn")

@onready var sprite: Sprite2D = $Sprite2D

var salud_jugador = VIDA_MAXIMA
var escudo_jugador = 0
var jugador_muerto = false
var tiempo_caminando = 0.0
var objetivo_actual = null
var personaje_actual = "caballero"
var dano_ataque = 40
var rango_ataque_casillas = 1.0
var tipo_ataque = "melee"
var limites_mapa := Rect2()
var tiene_limites_mapa := false


func _ready():
	cargar_datos_personaje()
	aplicar_frame_personaje()
	vida_cambiada.emit(salud_jugador)
	escudo_cambiado.emit(escudo_jugador)


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
	_mantener_dentro_del_mapa()

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


func cargar_datos_personaje():
	if not has_node("/root/Global"):
		return

	var global_data = get_node("/root/Global")
	personaje_actual = global_data.personaje_actual
	dano_ataque = global_data.dano
	rango_ataque_casillas = global_data.rango_ataque_casillas
	tipo_ataque = global_data.tipo_ataque


func atacar_objetivo():
	if objetivo_actual == null or objetivo_actual.esta_muerto:
		print("No tenes ningun objetivo vivo seleccionado.")
		return

	var distancia = global_position.distance_to(objetivo_actual.global_position)
	var rango_ataque = rango_ataque_casillas * TILE_SIZE

	if tipo_ataque == "distancia":
		if distancia <= rango_ataque:
			lanzar_proyectil_maga()
		else:
			print("Demasiado lejos para lanzar magia. Acercate mas.")
		return

	if distancia <= max(rango_ataque, TILE_SIZE * 1.5):
		print("Golpeaste al enemigo con el caballero.")
		animar_golpe_caballero()
		objetivo_actual.recibir_dano(dano_ataque)
	else:
		print("Tenes que estar pegado para atacar con el caballero.")


func lanzar_proyectil_maga():
	print("Lanzaste una bola de fuego celeste.")
	var proyectil = ESCENA_PROYECTIL_MAGA.instantiate()
	get_tree().current_scene.add_child(proyectil)
	proyectil.configurar(global_position, objetivo_actual, dano_ataque, rango_ataque_casillas * TILE_SIZE)


func animar_golpe_caballero():
	if not sprite:
		return

	var tween = create_tween()
	tween.tween_property(sprite, "rotation_degrees", 18.0, 0.06)
	tween.tween_property(sprite, "rotation_degrees", -12.0, 0.06)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.06)


func recibir_dano_jugador(cantidad):
	if jugador_muerto:
		return

	var dano_restante = cantidad
	if escudo_jugador > 0:
		var dano_a_escudo = min(escudo_jugador, dano_restante)
		escudo_jugador -= dano_a_escudo
		dano_restante -= dano_a_escudo
		escudo_cambiado.emit(escudo_jugador)

	if dano_restante > 0:
		salud_jugador = max(salud_jugador - dano_restante, 0)

	vida_cambiada.emit(salud_jugador)
	print("TU SALUD: ", salud_jugador, " | ESCUDO: ", escudo_jugador)

	# Destello rojo de daño
	modulate = Color(1, 0.3, 0.3)

	# Lógica de muerte
	if salud_jugador <= 0:
		morir_jugador()
		return

	await get_tree().create_timer(0.15).timeout
	if not jugador_muerto:
		modulate = Color(1, 1, 1)


func configurar_limites_mapa(rect: Rect2):
	limites_mapa = rect
	tiene_limites_mapa = true
	_mantener_dentro_del_mapa()


func _mantener_dentro_del_mapa():
	if not tiene_limites_mapa or limites_mapa.size == Vector2.ZERO:
		return

	var extents = Vector2(8.0, 8.0)
	var offset = Vector2.ZERO
	var forma_colision = get_node_or_null("CollisionShape2D")
	if forma_colision != null and forma_colision.shape != null:
		offset = forma_colision.position
		if forma_colision.shape is RectangleShape2D:
			extents = forma_colision.shape.size * 0.5
		elif forma_colision.shape is CircleShape2D:
			extents = Vector2.ONE * forma_colision.shape.radius

	var minimo = limites_mapa.position + extents - offset
	var maximo = limites_mapa.end - extents - offset
	global_position = Vector2(
		clampf(global_position.x, minimo.x, maximo.x),
		clampf(global_position.y, minimo.y, maximo.y)
	)


func curar(cantidad):
	if jugador_muerto or salud_jugador >= VIDA_MAXIMA:
		return

	salud_jugador = min(salud_jugador + cantidad, VIDA_MAXIMA)
	vida_cambiada.emit(salud_jugador)
	print("Manzana consumida. Salud: ", salud_jugador)


func recargar_escudo(cantidad):
	if jugador_muerto or escudo_jugador >= ESCUDO_MAXIMO:
		return

	escudo_jugador = min(escudo_jugador + cantidad, ESCUDO_MAXIMO)
	escudo_cambiado.emit(escudo_jugador)
	print("Escudo consumido. Escudo: ", escudo_jugador)


func morir_jugador():
	if jugador_muerto:
		return

	jugador_muerto = true
	velocity = Vector2.ZERO
	modulate = Color(0.1, 0.1, 0.1)
	set_physics_process(false)
	print("--- HAS MUERTO --- Game Over")
	get_tree().change_scene_to_file(ESCENA_GAME_OVER)
