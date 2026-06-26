extends CharacterBody2D

var salud = 50
var esta_muerto = false
var seleccionado = false

@onready var colision = $CollisionShape2D 
@onready var barra_vida = $ProgressBar 

# --- LA SOLUCIÓN AL BLOQUEO FÍSICO ---
const VELOCIDAD_ENEMIGO = 65.0
const RANGO_DETECCION = 140.0
const DISTANCIA_FRENADO = 18.0 # ¡SUBIDO! Ahora frena mucho antes de chocar físicamente.
const RANGO_ATAQUE = 24.0      # ¡SUBIDO! Rango enorme para que muerda sí o sí.
var tiempo_ultimo_ataque = 0.0

func _ready():
	add_to_group("atacante")
	if barra_vida:
		barra_vida.max_value = salud
		barra_vida.value = salud

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not esta_muerto:
			seleccionar_enemigo()

func seleccionar_enemigo():
	seleccionado = true
	modulate = Color(1, 0.5, 0.5)
	print("Enemigo seleccionado")
	
	var jugador = _obtener_jugador()
	if jugador:
		jugador.objetivo_actual = self

func recibir_dano(cantidad):
	if esta_muerto: return
	
	salud -= cantidad 
	if barra_vida:
		barra_vida.value = salud
	print("Salud actual del enemigo: ", salud)
	
	if salud <= 0:
		morir()

func morir():
	esta_muerto = true
	seleccionado = false
	modulate = Color(0.3, 0.3, 0.3)
	if barra_vida:
		barra_vida.visible = false
	colision.set_deferred("disabled", true)
	print("Enemigo derrotado y ahora es transitable")

# --- PROCESO FÍSICO ---
func _physics_process(delta):
	if esta_muerto: return
	
	var jugador = _obtener_jugador()
	if jugador:
		if jugador.jugador_muerto:
			velocity = Vector2.ZERO
			return
			
		var distancia = global_position.distance_to(jugador.global_position)
		
		# 1. MOVERSE O FRENAR
		if distancia <= RANGO_DETECCION and distancia > DISTANCIA_FRENADO:
			var direccion = (jugador.global_position - global_position).normalized()
			velocity = direccion * VELOCIDAD_ENEMIGO
		else:
			# Como DISTANCIA_FRENADO ahora es 75, frena ANTES de tocar tu caja de colisión.
			velocity = Vector2.ZERO
			
		move_and_slide()
			
		# 2. ATACAR
		tiempo_ultimo_ataque += delta
		if distancia <= RANGO_ATAQUE and tiempo_ultimo_ataque >= 1.0:
			atacar_jugador(jugador)
			tiempo_ultimo_ataque = 0.0

func atacar_jugador(jugador_nodo):
	print("¡El orco te mordió!")
	if jugador_nodo.has_method("recibir_dano_jugador"):
		jugador_nodo.recibir_dano_jugador(10)


func _obtener_jugador():
	var escena_actual = get_tree().current_scene
	if escena_actual != null:
		var jugador = escena_actual.get_node_or_null("Jugador")
		if jugador != null:
			return jugador

	var padre = get_parent()
	if padre != null:
		return padre.get_node_or_null("Jugador")

	return null
