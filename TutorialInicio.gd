extends CanvasLayer

@onready var contenedor: VBoxContainer = $Control/VBoxContainer
@onready var mensaje_contextual: Label = $Control/MensajeContextual

var ayudas_mostradas := {}
var version_tutorial := 0
var tween_tutorial: Tween


func _ready():
	await get_tree().create_timer(5.0).timeout
	if version_tutorial != 0:
		return

	_ocultar_tutorial()


func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_mostrar_tutorial_temporal()


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


func _mostrar_tutorial_temporal():
	version_tutorial += 1
	var version_actual = version_tutorial
	if tween_tutorial != null:
		tween_tutorial.kill()
	contenedor.visible = true
	contenedor.modulate.a = 1.0

	await get_tree().create_timer(5.0).timeout
	if version_actual == version_tutorial:
		_ocultar_tutorial()


func _ocultar_tutorial():
	if tween_tutorial != null:
		tween_tutorial.kill()
	tween_tutorial = create_tween()
	tween_tutorial.tween_property(contenedor, "modulate:a", 0.0, 0.8)
	tween_tutorial.finished.connect(func(): contenedor.visible = false)
