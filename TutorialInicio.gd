extends CanvasLayer

@onready var contenedor: VBoxContainer = $Control/VBoxContainer
@onready var mensaje_contextual: Label = $Control/MensajeContextual

var ayudas_mostradas := {}


func _ready():
	await get_tree().create_timer(5.0).timeout

	var tween = create_tween()
	tween.tween_property(contenedor, "modulate:a", 0.0, 0.8)
	tween.finished.connect(func(): contenedor.visible = false)


func mostrar_mensaje_consumible(tipo: String):
	if ayudas_mostradas.has(tipo):
		return

	ayudas_mostradas[tipo] = true
	if tipo == "vida":
		_mostrar_mensaje("La manzana te cura vida.")
	elif tipo == "escudo":
		_mostrar_mensaje("El escudo absorbe dano antes de tu vida.")


func _mostrar_mensaje(texto: String):
	mensaje_contextual.text = texto
	mensaje_contextual.modulate.a = 1.0
	mensaje_contextual.visible = true

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(mensaje_contextual, "modulate:a", 0.0, 0.6)
	tween.finished.connect(func(): mensaje_contextual.visible = false)
