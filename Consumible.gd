extends Area2D

@export_enum("vida", "escudo") var tipo := "vida"
@export var cantidad := 50


func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("consumible")
	add_to_group("consumible_" + tipo)


func _on_body_entered(body):
	if body.name != "Jugador":
		return

	if tipo == "vida" and body.has_method("curar") and body.salud_jugador < body.VIDA_MAXIMA:
		body.curar(cantidad)
		queue_free()
	elif tipo == "escudo" and body.has_method("recargar_escudo") and body.escudo_jugador < body.ESCUDO_MAXIMO:
		body.recargar_escudo(cantidad)
		queue_free()
