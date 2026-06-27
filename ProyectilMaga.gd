extends Area2D

@export var velocidad := 220.0

var objetivo = null
var dano := 20
var distancia_maxima := 80.0
var distancia_recorrida := 0.0


func configurar(posicion_inicial: Vector2, objetivo_inicial, dano_inicial: int, rango_maximo: float):
	global_position = posicion_inicial
	objetivo = objetivo_inicial
	dano = dano_inicial
	distancia_maxima = rango_maximo


func _physics_process(delta):
	if objetivo == null or not is_instance_valid(objetivo) or objetivo.esta_muerto:
		queue_free()
		return

	var direccion = (objetivo.global_position - global_position).normalized()
	var desplazamiento = direccion * velocidad * delta
	global_position += desplazamiento
	distancia_recorrida += desplazamiento.length()
	rotation = direccion.angle()

	if global_position.distance_to(objetivo.global_position) <= 8.0:
		objetivo.recibir_dano(dano)
		queue_free()
		return

	if distancia_recorrida >= distancia_maxima:
		queue_free()
