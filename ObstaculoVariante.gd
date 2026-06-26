extends StaticBody2D

@export var variante := -1

var rng := RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	var contenedor = get_node_or_null("Variantes")
	if contenedor == null:
		return

	var opciones = contenedor.get_children()
	if opciones.is_empty():
		return

	var indice = variante
	if indice < 0 or indice >= opciones.size():
		indice = rng.randi_range(0, opciones.size() - 1)

	for i in range(opciones.size()):
		opciones[i].visible = i == indice
