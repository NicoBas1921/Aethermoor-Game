extends CanvasLayer

@onready var barra_vida: ProgressBar = $Control/BarraVida
@onready var barra_escudo: ProgressBar = $Control/BarraEscudo


func _ready():
	var escena_actual = get_tree().current_scene
	var jugador = null
	if escena_actual != null:
		jugador = escena_actual.get_node_or_null("Jugador")
	if jugador == null:
		jugador = get_parent().get_node_or_null("Jugador")
	if jugador:
		conectar_jugador(jugador)


func conectar_jugador(jugador):
	barra_vida.max_value = jugador.VIDA_MAXIMA
	barra_vida.value = jugador.salud_jugador
	barra_escudo.max_value = jugador.ESCUDO_MAXIMO
	barra_escudo.value = jugador.escudo_jugador
	if not jugador.vida_cambiada.is_connected(_on_vida_cambiada):
		jugador.vida_cambiada.connect(_on_vida_cambiada)
	if not jugador.escudo_cambiado.is_connected(_on_escudo_cambiado):
		jugador.escudo_cambiado.connect(_on_escudo_cambiado)


func _on_vida_cambiada(nueva_vida):
	barra_vida.value = nueva_vida


func _on_escudo_cambiado(nuevo_escudo):
	barra_escudo.value = nuevo_escudo
