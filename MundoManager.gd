extends Node2D

const TILE_SIZE = 16.0
const LIMITE_GROSOR = 32.0
const TILE_PASTO := Vector2i(3, 16)
const TILE_TIERRA := Vector2i(8, 10)
const TILE_GRAVA := Vector2i(8, 16)
const TILE_ARENA := Vector2i(8, 22)
const TILE_PIEDRAS := Vector2i(9, 1)
const TILE_AGUA_CENTRO := Vector2i(3, 1)
const TILE_AGUA_ARRIBA := Vector2i(3, 0)
const TILE_AGUA_ABAJO := Vector2i(3, 2)
const TILE_AGUA_IZQUIERDA := Vector2i(2, 1)
const TILE_AGUA_DERECHA := Vector2i(4, 1)
const TILE_AGUA_ESQ_SUP_IZQ := Vector2i(2, 0)
const TILE_AGUA_ESQ_SUP_DER := Vector2i(4, 0)
const TILE_AGUA_ESQ_INF_IZQ := Vector2i(2, 2)
const TILE_AGUA_ESQ_INF_DER := Vector2i(4, 2)

@export var tilemap_path: NodePath = NodePath("TileMap")
@export var limites_path: NodePath = NodePath("LimitesMapa")
@export var obstaculos_path: NodePath = NodePath("Obstaculos")
@export var spawn_manager_path: NodePath = NodePath("SpawnManager")
@export var jugador_path: NodePath = NodePath("Jugador")
@export var auto_scene: PackedScene
@export var casa_scene: PackedScene
@export var enemigo_scene: PackedScene
@export var escala_mapa := Vector2i(2, 2)
@export var margen_spawn := 64.0
@export var autos_aleatorios := 16
@export var casas_aleatorias := 10
@export var parches_bioma := 28
@export var parches_decoracion := 120
@export var lagos_aleatorios := 4
@export var max_atacantes := 8
@export var intervalo_spawn_atacante := 7.0
@export var margen_fuera_camara := 96.0

var rng := RandomNumberGenerator.new()
var rect_jugable := Rect2()
var celdas_mapa := Rect2i()
var celdas_bioma := {}
var celdas_decoracion := {}


func _ready():
	rng.randomize()
	var tilemap: TileMap = get_node(tilemap_path)
	_generar_mapa_continuo(tilemap)
	rect_jugable = _calcular_rect_jugable(tilemap, celdas_mapa)
	_ajustar_limites(rect_jugable)
	_configurar_camara(rect_jugable)
	_configurar_spawn_manager(rect_jugable)
	call_deferred("_decorar_mapa")
	call_deferred("_crear_timer_atacantes")


func _generar_mapa_continuo(tilemap: TileMap):
	var usado_original = tilemap.get_used_rect()
	var suelo_base = _obtener_suelo_base(tilemap)
	var decoraciones = _obtener_parches_decoracion(tilemap)

	if suelo_base.is_empty():
		return

	celdas_bioma.clear()
	celdas_mapa = Rect2i(
		usado_original.position,
		Vector2i(usado_original.size.x * escala_mapa.x, usado_original.size.y * escala_mapa.y)
	)

	for layer in range(tilemap.get_layers_count()):
		tilemap.clear_layer(layer)

	celdas_decoracion.clear()
	for x in range(celdas_mapa.position.x, celdas_mapa.end.x):
		for y in range(celdas_mapa.position.y, celdas_mapa.end.y):
			_aplicar_tile(tilemap, 0, Vector2i(x, y), suelo_base)

	_generar_bioma_procedural(tilemap)
	_generar_decoracion_tilemap(tilemap, decoraciones)


func _obtener_suelo_base(tilemap: TileMap) -> Dictionary:
	var conteos = {}
	var muestras = {}

	for celda in tilemap.get_used_cells(0):
		var tile = _leer_tile(tilemap, 0, celda)
		var clave = _clave_tile(tile)
		conteos[clave] = conteos.get(clave, 0) + 1
		muestras[clave] = tile

	var mejor_clave = ""
	var mejor_cantidad = -1
	for clave in conteos.keys():
		if conteos[clave] > mejor_cantidad:
			mejor_clave = clave
			mejor_cantidad = conteos[clave]

	if mejor_clave == "":
		return {}

	return muestras[mejor_clave]


func _obtener_parches_decoracion(tilemap: TileMap) -> Array:
	if tilemap.get_layers_count() < 2:
		return []

	return _obtener_parches_capa(tilemap, 1, {}, 1)


func _obtener_parches_capa(tilemap: TileMap, layer: int, tile_excluido: Dictionary, minimo_celdas: int) -> Array:
	var pendientes = {}
	for celda in tilemap.get_used_cells(layer):
		var tile = _leer_tile(tilemap, layer, celda)
		if not _tile_valido(tile):
			continue
		if not tile_excluido.is_empty() and _mismo_tile(tile, tile_excluido):
			continue
		pendientes[celda] = true

	var parches = []
	while not pendientes.is_empty():
		var inicio: Vector2i = pendientes.keys()[0]
		var celdas = _extraer_componente(layer, tilemap, pendientes, inicio, tile_excluido)
		if celdas.size() >= minimo_celdas:
			parches.append(_crear_patch(tilemap, layer, celdas))

	return parches


func _extraer_componente(layer: int, tilemap: TileMap, pendientes: Dictionary, inicio: Vector2i, tile_excluido: Dictionary) -> Array:
	var cola = [inicio]
	var resultado = []
	pendientes.erase(inicio)

	while not cola.is_empty():
		var actual: Vector2i = cola.pop_front()
		resultado.append(actual)

		for vecino in [
			actual + Vector2i.RIGHT,
			actual + Vector2i.LEFT,
			actual + Vector2i.DOWN,
			actual + Vector2i.UP,
		]:
			if not pendientes.has(vecino):
				continue

			var tile = _leer_tile(tilemap, layer, vecino)
			if not _tile_valido(tile):
				pendientes.erase(vecino)
				continue
			if not tile_excluido.is_empty() and _mismo_tile(tile, tile_excluido):
				pendientes.erase(vecino)
				continue

			pendientes.erase(vecino)
			cola.append(vecino)

	return resultado


func _crear_patch(tilemap: TileMap, layer: int, celdas: Array) -> Dictionary:
	var min_celda: Vector2i = celdas[0]
	var max_celda: Vector2i = celdas[0]
	for celda in celdas:
		min_celda.x = min(min_celda.x, celda.x)
		min_celda.y = min(min_celda.y, celda.y)
		max_celda.x = max(max_celda.x, celda.x)
		max_celda.y = max(max_celda.y, celda.y)

	var tiles = []
	for celda in celdas:
		tiles.append({
			"offset": celda - min_celda,
			"tile": _leer_tile(tilemap, layer, celda),
		})

	return {
		"tamano": max_celda - min_celda + Vector2i.ONE,
		"tiles": tiles,
	}


func _generar_bioma_procedural(tilemap: TileMap):
	var tierra = _crear_tile(TILE_TIERRA)
	var grava = _crear_tile(TILE_GRAVA)
	var arena = _crear_tile(TILE_ARENA)
	var piedras = _crear_tile(TILE_PIEDRAS)

	for i in range(max(1, int(parches_bioma * 0.5))):
		_pintar_mancha_suelo(tilemap, tierra, rng.randi_range(3, 7), rng.randi_range(2, 5))

	for i in range(max(1, int(parches_bioma * 0.25))):
		_pintar_mancha_suelo(tilemap, grava, rng.randi_range(2, 5), rng.randi_range(2, 4))

	for i in range(max(1, int(parches_bioma * 0.2))):
		_pintar_mancha_suelo(tilemap, arena, rng.randi_range(2, 5), rng.randi_range(2, 4))

	for i in range(max(1, int(parches_bioma * 0.2))):
		_pintar_mancha_suelo(tilemap, piedras, rng.randi_range(2, 4), rng.randi_range(2, 3))

	for i in range(lagos_aleatorios):
		_generar_lago(tilemap)


func _pintar_mancha_suelo(tilemap: TileMap, tile: Dictionary, radio_x: int, radio_y: int):
	var centro = _buscar_celda_libre_para_bioma(Vector2i(radio_x * 2 + 1, radio_y * 2 + 1), 5)
	if centro == null:
		return

	for x in range(-radio_x, radio_x + 1):
		for y in range(-radio_y, radio_y + 1):
			var distancia = pow(float(x) / float(radio_x), 2.0) + pow(float(y) / float(radio_y), 2.0)
			if distancia + rng.randf_range(-0.35, 0.25) > 1.0:
				continue

			var celda: Vector2i = centro + Vector2i(x, y)
			if not _celda_en_mapa_con_margen(celda, 3):
				continue
			if celdas_bioma.has(celda):
				continue

			_aplicar_tile(tilemap, 0, celda, tile)
			celdas_bioma[celda] = true


func _generar_lago(tilemap: TileMap):
	var radio_x = rng.randi_range(5, 9)
	var radio_y = rng.randi_range(4, 7)
	var centro = _buscar_celda_libre_para_bioma(Vector2i(radio_x * 2 + 1, radio_y * 2 + 1), 8)
	if centro == null:
		return

	var lago = {}
	for x in range(-radio_x, radio_x + 1):
		for y in range(-radio_y, radio_y + 1):
			var distancia = pow(float(x) / float(radio_x), 2.0) + pow(float(y) / float(radio_y), 2.0)
			if distancia + rng.randf_range(-0.28, 0.22) > 1.0:
				continue

			var celda: Vector2i = centro + Vector2i(x, y)
			if not _celda_en_mapa_con_margen(celda, 5):
				continue
			if celdas_bioma.has(celda):
				continue

			lago[celda] = true

	if lago.size() < 20:
		return

	lago = _suavizar_lago(lago)
	for celda in lago.keys():
		_aplicar_tile(tilemap, 0, celda, _tile_agua_para_celda(lago, celda))
		celdas_bioma[celda] = true


func _suavizar_lago(lago: Dictionary) -> Dictionary:
	var resultado = {}
	for celda in lago.keys():
		var vecinos = 0
		for vecino in [
			celda + Vector2i.RIGHT,
			celda + Vector2i.LEFT,
			celda + Vector2i.DOWN,
			celda + Vector2i.UP,
		]:
			if lago.has(vecino):
				vecinos += 1

		if vecinos >= 2:
			resultado[celda] = true

	return resultado


func _tile_agua_para_celda(lago: Dictionary, celda: Vector2i) -> Dictionary:
	var arriba = lago.has(celda + Vector2i.UP)
	var abajo = lago.has(celda + Vector2i.DOWN)
	var izquierda = lago.has(celda + Vector2i.LEFT)
	var derecha = lago.has(celda + Vector2i.RIGHT)

	if not arriba and not izquierda:
		return _crear_tile(TILE_AGUA_ESQ_SUP_IZQ)
	if not arriba and not derecha:
		return _crear_tile(TILE_AGUA_ESQ_SUP_DER)
	if not abajo and not izquierda:
		return _crear_tile(TILE_AGUA_ESQ_INF_IZQ)
	if not abajo and not derecha:
		return _crear_tile(TILE_AGUA_ESQ_INF_DER)
	if not arriba:
		return _crear_tile(TILE_AGUA_ARRIBA)
	if not abajo:
		return _crear_tile(TILE_AGUA_ABAJO)
	if not izquierda:
		return _crear_tile(TILE_AGUA_IZQUIERDA)
	if not derecha:
		return _crear_tile(TILE_AGUA_DERECHA)

	return _crear_tile(TILE_AGUA_CENTRO)


func _buscar_celda_libre_para_bioma(tamano: Vector2i, margen: int):
	var min_x = celdas_mapa.position.x + margen
	var min_y = celdas_mapa.position.y + margen
	var max_x = celdas_mapa.end.x - tamano.x - margen
	var max_y = celdas_mapa.end.y - tamano.y - margen
	if max_x < min_x or max_y < min_y:
		return null

	for intento in range(80):
		var celda = Vector2i(
			rng.randi_range(min_x, max_x),
			rng.randi_range(min_y, max_y)
		)
		var rect = Rect2i(celda, tamano)
		if _rect_libre_de_bioma(rect):
			return celda + Vector2i(floori(tamano.x * 0.5), floori(tamano.y * 0.5))

	return null


func _rect_libre_de_bioma(rect: Rect2i) -> bool:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			if celdas_bioma.has(Vector2i(x, y)):
				return false
	return true


func _generar_decoracion_tilemap(tilemap: TileMap, decoraciones: Array):
	if tilemap.get_layers_count() < 2 or decoraciones.is_empty():
		return

	for i in range(parches_decoracion):
		var patch = decoraciones[rng.randi_range(0, decoraciones.size() - 1)]
		var destino = _buscar_celda_para_patch(patch["tamano"], 3, false)
		if destino == null:
			continue

		_aplicar_patch(tilemap, 1, patch, destino, false)
		_registrar_patch_decoracion(patch, destino)


func _buscar_celda_para_patch(tamano: Vector2i, margen: int, permitir_bioma: bool):
	var min_x = celdas_mapa.position.x + margen
	var min_y = celdas_mapa.position.y + margen
	var max_x = celdas_mapa.end.x - tamano.x - margen
	var max_y = celdas_mapa.end.y - tamano.y - margen
	if max_x < min_x or max_y < min_y:
		return null

	for intento in range(40):
		var destino = Vector2i(
			rng.randi_range(min_x, max_x),
			rng.randi_range(min_y, max_y)
		)
		if _patch_libre_para_decoracion(destino, tamano, permitir_bioma):
			return destino

	return null


func _patch_libre_para_decoracion(destino: Vector2i, tamano: Vector2i, permitir_bioma: bool) -> bool:
	for x in range(destino.x, destino.x + tamano.x):
		for y in range(destino.y, destino.y + tamano.y):
			var celda = Vector2i(x, y)
			if celdas_decoracion.has(celda):
				return false
			if not permitir_bioma and celdas_bioma.has(celda):
				return false
	return true


func _registrar_patch_decoracion(patch: Dictionary, destino: Vector2i):
	for entrada in patch["tiles"]:
		var celda: Vector2i = destino + entrada["offset"]
		if _celda_en_mapa(celda):
			celdas_decoracion[celda] = true


func _aplicar_patch(tilemap: TileMap, layer: int, patch: Dictionary, destino: Vector2i, registrar_bioma: bool):
	for entrada in patch["tiles"]:
		var celda: Vector2i = destino + entrada["offset"]
		if not _celda_en_mapa(celda):
			continue

		_aplicar_tile(tilemap, layer, celda, entrada["tile"])
		if registrar_bioma:
			celdas_bioma[celda] = true


func _leer_tile(tilemap: TileMap, layer: int, celda: Vector2i) -> Dictionary:
	return {
		"source": tilemap.get_cell_source_id(layer, celda),
		"atlas": tilemap.get_cell_atlas_coords(layer, celda),
		"alt": tilemap.get_cell_alternative_tile(layer, celda),
	}


func _crear_tile(atlas: Vector2i) -> Dictionary:
	return {
		"source": 0,
		"atlas": atlas,
		"alt": 0,
	}


func _aplicar_tile(tilemap: TileMap, layer: int, celda: Vector2i, tile: Dictionary):
	tilemap.set_cell(layer, celda, tile["source"], tile["atlas"], tile["alt"])


func _clave_tile(tile: Dictionary) -> String:
	var atlas: Vector2i = tile["atlas"]
	return "%s|%s|%s|%s" % [tile["source"], atlas.x, atlas.y, tile["alt"]]


func _tile_valido(tile: Dictionary) -> bool:
	return tile["source"] != -1


func _mismo_tile(a: Dictionary, b: Dictionary) -> bool:
	return a["source"] == b["source"] and a["atlas"] == b["atlas"] and a["alt"] == b["alt"]


func _celda_en_mapa(celda: Vector2i) -> bool:
	return (
		celda.x >= celdas_mapa.position.x
		and celda.y >= celdas_mapa.position.y
		and celda.x < celdas_mapa.end.x
		and celda.y < celdas_mapa.end.y
	)


func _celda_en_mapa_con_margen(celda: Vector2i, margen: int) -> bool:
	return (
		celda.x >= celdas_mapa.position.x + margen
		and celda.y >= celdas_mapa.position.y + margen
		and celda.x < celdas_mapa.end.x - margen
		and celda.y < celdas_mapa.end.y - margen
	)


func _calcular_rect_jugable(tilemap: TileMap, celdas: Rect2i) -> Rect2:
	var tile_size = Vector2(tilemap.tile_set.tile_size)
	var esquina_superior = tilemap.to_global(tilemap.map_to_local(celdas.position) - tile_size * 0.5)
	var esquina_inferior = tilemap.to_global(tilemap.map_to_local(celdas.end - Vector2i.ONE) + tile_size * 0.5)
	return Rect2(esquina_superior, esquina_inferior - esquina_superior)


func _ajustar_limites(rect: Rect2):
	var limites = get_node(limites_path)
	var horizontal = RectangleShape2D.new()
	horizontal.size = Vector2(rect.size.x + LIMITE_GROSOR * 2.0, LIMITE_GROSOR)
	var vertical = RectangleShape2D.new()
	vertical.size = Vector2(LIMITE_GROSOR, rect.size.y + LIMITE_GROSOR * 2.0)

	_configurar_limite(limites.get_node("Arriba"), Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y - LIMITE_GROSOR * 0.5), horizontal)
	_configurar_limite(limites.get_node("Abajo"), Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y + LIMITE_GROSOR * 0.5), horizontal)
	_configurar_limite(limites.get_node("Izquierda"), Vector2(rect.position.x - LIMITE_GROSOR * 0.5, rect.position.y + rect.size.y * 0.5), vertical)
	_configurar_limite(limites.get_node("Derecha"), Vector2(rect.end.x + LIMITE_GROSOR * 0.5, rect.position.y + rect.size.y * 0.5), vertical)


func _configurar_limite(limite: StaticBody2D, posicion: Vector2, forma: RectangleShape2D):
	limite.global_position = posicion
	limite.get_node("CollisionShape2D").shape = forma


func _configurar_camara(rect: Rect2):
	var jugador = get_node_or_null(jugador_path)
	if jugador == null:
		return

	var camara: Camera2D = jugador.get_node_or_null("Camera2D")
	if camara == null:
		return

	camara.limit_left = int(rect.position.x)
	camara.limit_top = int(rect.position.y)
	camara.limit_right = int(rect.end.x)
	camara.limit_bottom = int(rect.end.y)
	camara.position_smoothing_enabled = false
	camara.reset_smoothing()

	if jugador.has_method("configurar_limites_mapa"):
		jugador.configurar_limites_mapa(rect)


func _configurar_spawn_manager(rect: Rect2):
	var spawn_manager = get_node_or_null(spawn_manager_path)
	if spawn_manager == null:
		return

	spawn_manager.rect_spawn = rect.grow(-margen_spawn)


func _decorar_mapa():
	var contenedor = get_node(obstaculos_path)
	_spawn_obstaculos(contenedor, casa_scene, casas_aleatorias)
	_spawn_obstaculos(contenedor, auto_scene, autos_aleatorios)


func _spawn_obstaculos(contenedor: Node, escena: PackedScene, cantidad: int):
	if escena == null:
		return

	for i in range(cantidad):
		var posicion = _buscar_posicion_valida(rect_jugable.grow(-margen_spawn), 18.0, true)
		if posicion == null:
			continue

		var obstaculo = escena.instantiate()
		obstaculo.global_position = posicion
		contenedor.add_child(obstaculo)


func _crear_timer_atacantes():
	_spawn_atacante()
	var timer = Timer.new()
	timer.wait_time = intervalo_spawn_atacante
	timer.autostart = true
	timer.timeout.connect(_spawn_atacante)
	add_child(timer)


func _spawn_atacante():
	if enemigo_scene == null or _contar_atacantes_vivos() >= max_atacantes:
		return

	var posicion = _buscar_posicion_fuera_de_camara()
	if posicion == null:
		return

	var atacante = enemigo_scene.instantiate()
	atacante.global_position = posicion
	add_child(atacante)


func _contar_atacantes_vivos() -> int:
	var vivos = 0
	for atacante in get_tree().get_nodes_in_group("atacante"):
		if is_instance_valid(atacante) and not atacante.esta_muerto:
			vivos += 1
	return vivos


func _buscar_posicion_fuera_de_camara():
	var area = rect_jugable.grow(-margen_spawn)
	for intento in range(60):
		var posicion = _posicion_aleatoria(area)
		if _esta_en_camara_expandida(posicion):
			continue
		if _posicion_valida(posicion, 12.0, true):
			return posicion
	return null


func _esta_en_camara_expandida(posicion: Vector2) -> bool:
	var jugador = get_node_or_null(jugador_path)
	if jugador == null:
		return false

	var camara: Camera2D = jugador.get_node_or_null("Camera2D")
	if camara == null:
		return false

	var viewport_size = get_viewport_rect().size
	var zoom = camara.zoom
	var visible_size = Vector2(viewport_size.x / zoom.x, viewport_size.y / zoom.y)
	var visible_rect = Rect2(camara.global_position - visible_size * 0.5, visible_size).grow(margen_fuera_camara)
	return visible_rect.has_point(posicion)


func _buscar_posicion_valida(area: Rect2, radio: float, evitar_camara: bool):
	for intento in range(50):
		var posicion = _posicion_aleatoria(area)
		if evitar_camara and _esta_en_camara_expandida(posicion):
			continue
		if _posicion_valida(posicion, radio, true):
			return posicion
	return null


func _posicion_aleatoria(area: Rect2) -> Vector2:
	var posicion = Vector2(
		rng.randf_range(area.position.x, area.end.x),
		rng.randf_range(area.position.y, area.end.y)
	)
	return Vector2(
		floor(posicion.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE * 0.5,
		floor(posicion.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE * 0.5
	)


func _posicion_valida(posicion: Vector2, radio: float, evitar_colisiones: bool) -> bool:
	if not rect_jugable.has_point(posicion):
		return false
	if not evitar_colisiones:
		return true

	var forma = CircleShape2D.new()
	forma.radius = radio

	var parametros = PhysicsShapeQueryParameters2D.new()
	parametros.shape = forma
	parametros.transform = Transform2D(0.0, posicion)
	parametros.collision_mask = 1
	parametros.collide_with_areas = true
	parametros.collide_with_bodies = true

	return get_world_2d().direct_space_state.intersect_shape(parametros, 8).is_empty()
