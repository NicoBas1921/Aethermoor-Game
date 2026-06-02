extends CharacterBody2D

# === ESTADÍSTICAS DEL GUERRERO ===
var clase = "Guerrero"
var salud_maxima = 150
var dano_arma_actual = 15

# === VARIABLES DE MOVIMIENTO ===
var velocidad = 250.0

func _physics_process(delta):
	var direccion = Vector2.ZERO
	
	# Detectamos las teclas WASD para movernos en 2D (Ejes X e Y)
	if Input.is_physical_key_pressed(KEY_A):
		direccion.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		direccion.x += 1
	if Input.is_physical_key_pressed(KEY_W):
		direccion.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		direccion.y += 1
		
	# Normalizamos para que no corra más rápido en diagonal
	if direccion != Vector2.ZERO:
		direccion = direccion.normalized()
		
	# En CharacterBody2D, seteamos la 'velocity' y llamamos a move_and_slide()
	velocity = direccion * velocidad
	move_and_slide()
