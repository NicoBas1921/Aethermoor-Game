extends CanvasLayer

@onready var barra_vida: ProgressBar = $Control/BarraVida


func _ready():
	var jugador = get_tree().current_scene.get_node_or_null("Jugador")
	if jugador:
		conectar_jugador(jugador)


func conectar_jugador(jugador):
	barra_vida.max_value = jugador.VIDA_MAXIMA
	barra_vida.value = jugador.salud_jugador
	if not jugador.vida_cambiada.is_connected(_on_vida_cambiada):
		jugador.vida_cambiada.connect(_on_vida_cambiada)


func _on_vida_cambiada(nueva_vida):
	barra_vida.value = nueva_vida
