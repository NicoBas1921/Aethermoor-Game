extends Node2D

signal progreso_cambiado(actual, total)
signal tiempo_cambiado(segundos_restantes)

const ESCENA_VICTORIA = "res://Victoria.tscn"
const ESCENA_GAME_OVER = "res://GameOver.tscn"
const TILE_SIZE = 16.0

@export var cristal_scene: PackedScene
@export var cristales_necesarios := 6
@export var tiempo_limite := 120.0
@export var rect_spawn := Rect2(64, 64, 1200, 640)
@export var intentos_por_cristal := 60
@export var generar_cristales_runtime := false

var cristales := 0
var tiempo_restante := 0.0
var partida_terminada := false
var rng := RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	tiempo_restante = tiempo_limite
	call_deferred("_iniciar_objetivo")


func _process(delta):
	if partida_terminada:
		return

	tiempo_restante = max(tiempo_restante - delta, 0.0)
	tiempo_cambiado.emit(ceili(tiempo_restante))
	if tiempo_restante <= 0.0:
		terminar_por_tiempo()


func configurar_area_spawn(rect: Rect2):
	rect_spawn = rect


func registrar_cristal(valor: int):
	if partida_terminada:
		return

	cristales = min(cristales + valor, cristales_necesarios)
	progreso_cambiado.emit(cristales, cristales_necesarios)

	if cristales >= cristales_necesarios:
		ganar_partida()


func _iniciar_objetivo():
	if generar_cristales_runtime and _contar_cristales_en_escena() < cristales_necesarios:
		_spawn_cristales()
	progreso_cambiado.emit(cristales, cristales_necesarios)
	tiempo_cambiado.emit(ceili(tiempo_restante))

	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud != null and hud.has_method("conectar_objetivo"):
		hud.conectar_objetivo(self)


func _spawn_cristales():
	if cristal_scene == null:
		return

	for i in range(cristales_necesarios):
		var posicion = _buscar_posicion_valida()
		if posicion == null:
			continue

		var cristal = cristal_scene.instantiate()
		cristal.global_position = posicion
		add_child(cristal)


func _contar_cristales_en_escena() -> int:
	var vivos = 0
	for cristal in get_tree().get_nodes_in_group("cristal_objetivo"):
		if is_instance_valid(cristal):
			vivos += 1
	return vivos


func _buscar_posicion_valida():
	for intento in range(intentos_por_cristal):
		var posicion = Vector2(
			rng.randf_range(rect_spawn.position.x, rect_spawn.end.x),
			rng.randf_range(rect_spawn.position.y, rect_spawn.end.y)
		)
		posicion = Vector2(
			floor(posicion.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE * 0.5,
			floor(posicion.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE * 0.5
		)

		if _posicion_valida(posicion):
			return posicion

	return null


func _posicion_valida(posicion: Vector2) -> bool:
	var forma = CircleShape2D.new()
	forma.radius = 12.0

	var parametros = PhysicsShapeQueryParameters2D.new()
	parametros.shape = forma
	parametros.transform = Transform2D(0.0, posicion)
	parametros.collision_mask = 1
	parametros.collide_with_areas = true
	parametros.collide_with_bodies = true

	return get_world_2d().direct_space_state.intersect_shape(parametros, 8).is_empty()


func ganar_partida():
	if partida_terminada:
		return

	partida_terminada = true
	get_tree().change_scene_to_file(ESCENA_VICTORIA)


func terminar_por_tiempo():
	if partida_terminada:
		return

	partida_terminada = true
	get_tree().change_scene_to_file(ESCENA_GAME_OVER)
