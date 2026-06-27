extends CanvasLayer

@onready var barra_vida: ProgressBar = $Control/BarraVida
@onready var barra_escudo: ProgressBar = $Control/BarraEscudo
@onready var objetivo_label: Label = $Control/PanelObjetivo/VBoxContainer/Objetivo
@onready var tiempo_label: Label = $Control/PanelObjetivo/VBoxContainer/Tiempo


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


func conectar_objetivo(objetivo_manager):
	_on_progreso_cambiado(objetivo_manager.cristales, objetivo_manager.cristales_necesarios)
	_on_tiempo_cambiado(ceili(objetivo_manager.tiempo_restante))
	if not objetivo_manager.progreso_cambiado.is_connected(_on_progreso_cambiado):
		objetivo_manager.progreso_cambiado.connect(_on_progreso_cambiado)
	if not objetivo_manager.tiempo_cambiado.is_connected(_on_tiempo_cambiado):
		objetivo_manager.tiempo_cambiado.connect(_on_tiempo_cambiado)


func _on_vida_cambiada(nueva_vida):
	barra_vida.value = nueva_vida


func _on_escudo_cambiado(nuevo_escudo):
	barra_escudo.value = nuevo_escudo


func _on_progreso_cambiado(actual, total):
	objetivo_label.text = "Cristales: %d / %d" % [actual, total]


func _on_tiempo_cambiado(segundos_restantes):
	var minutos = int(segundos_restantes / 60)
	var segundos = int(segundos_restantes % 60)
	tiempo_label.text = "Tiempo: %02d:%02d" % [minutos, segundos]
