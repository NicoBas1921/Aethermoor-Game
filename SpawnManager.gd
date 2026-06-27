extends Node2D

const TILE_SIZE = 16.0

@export var manzana_scene: PackedScene
@export var escudo_scene: PackedScene
@export var max_manzanas := 3
@export var max_escudos := 2
@export var intervalo_spawn := 10.0
@export var rect_spawn := Rect2(64, 64, 1200, 640)
@export var intentos_por_item := 30

var rng := RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	call_deferred("_reponer_consumibles")

	var timer = Timer.new()
	timer.wait_time = intervalo_spawn
	timer.autostart = true
	timer.timeout.connect(_reponer_consumibles)
	add_child(timer)


func _reponer_consumibles():
	_spawn_hasta_limite(manzana_scene, "consumible_vida", max_manzanas)
	_spawn_hasta_limite(escudo_scene, "consumible_escudo", max_escudos)


func _spawn_hasta_limite(escena: PackedScene, grupo: String, maximo: int):
	if escena == null:
		return

	var activos = get_tree().get_nodes_in_group(grupo).size()
	while activos < maximo:
		var posicion = _buscar_posicion_valida()
		if posicion == null:
			return

		var consumible = escena.instantiate()
		consumible.global_position = posicion
		add_child(consumible)
		activos += 1


func _buscar_posicion_valida():
	for intento in range(intentos_por_item):
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
	forma.radius = 10.0

	var parametros = PhysicsShapeQueryParameters2D.new()
	parametros.shape = forma
	parametros.transform = Transform2D(0.0, posicion)
	parametros.collision_mask = 1
	parametros.collide_with_areas = true
	parametros.collide_with_bodies = true

	var colisiones = get_world_2d().direct_space_state.intersect_shape(parametros, 8)
	return colisiones.is_empty()
