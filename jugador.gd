extends CharacterBody2D

const SPEED = 100.0

@onready var sprite = $Sprite2D 

var salud_jugador = 100
var jugador_muerto = false
var tiempo_caminando = 0.0
const ALTURA_SALTITO = 5.0 
const VELOCIDAD_ANIMACION = 18.0

# --- NUEVAS VARIABLES DE COMBATE ---
var objetivo_actual = null
const RANGO_ATAQUE = 80.0 # Qué tan cerca tenés que estar para pegarle

func _physics_process(delta):
	# --- MOVIMIENTO (WASD) ---
	var direccion = Vector2.ZERO
	if Input.is_key_pressed(KEY_D): direccion.x += 1
	if Input.is_key_pressed(KEY_A): direccion.x -= 1
	if Input.is_key_pressed(KEY_S): direccion.y += 1
	if Input.is_key_pressed(KEY_W): direccion.y -= 1
	
	direccion = direccion.normalized()
	
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

	# --- DETECTAR ATAQUE (Barra Espaciadora) ---
	if Input.is_action_just_pressed("ui_accept"): # "ui_accept" es el Espacio/Enter por defecto
		atacar_objetivo()

# --- FUNCIÓN PARA ATACAR ---
func atacar_objetivo():
	# Si no tenemos a nadie seleccionado, o si ya se murió, no hacemos nada
	if objetivo_actual == null or objetivo_actual.esta_muerto:
		print("No tenés ningún objetivo vivo seleccionado.")
		return
		
	# Calculamos la distancia entre el jugador y el enemigo
	var distancia = global_position.distance_to(objetivo_actual.global_position)
	
	# Verificamos si estamos lo suficientemente cerca
	if distancia <= RANGO_ATAQUE:
		print("¡Le pegaste al orco!")
		objetivo_actual.recibir_dano(25) # Le sacamos 25 de vida (necesitará 2 golpes)
	else:
		print("¡Demasiado lejos para atacar! Acercate más.")
		
func recibir_dano_jugador(cantidad):
	if jugador_muerto: return

	salud_jugador -= cantidad
	print("¡TU SALUD: ", salud_jugador, "!")

	# Efecto visual: parpadeo rojo rápido al recibir el golpe
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if not jugador_muerto:
		modulate = Color(1, 1, 1) # Vuelve al color original

	if salud_jugador <= 0:
		morir_jugador()

func morir_jugador():
	jugador_muerto = true # <-- CAMBIADO A TRUE (Clave para que la IA se detenga)
	print("--- HAS MUERTO --- Game Over")
	modulate = Color(0.1, 0.1, 0.1) 
	set_physics_process(false)
	jugador_muerto = true
	print("--- HAS MUERTO --- Game Over")
	modulate = Color(0.1, 0.1, 0.1) # El héroe se oscurece
	set_physics_process(false) # Se congela el movimiento del teclado
