extends Area2D

@export var valor := 1

@onready var aura: Polygon2D = $Aura

var recogido := false


func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("cristal_objetivo")

	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 3.0, 0.6)
	tween.tween_property(self, "position:y", position.y + 3.0, 0.6)

	var aura_tween = create_tween().set_loops()
	aura_tween.tween_property(aura, "scale", Vector2(1.25, 1.25), 0.8)
	aura_tween.parallel().tween_property(aura, "modulate:a", 0.25, 0.8)
	aura_tween.tween_property(aura, "scale", Vector2.ONE, 0.8)
	aura_tween.parallel().tween_property(aura, "modulate:a", 0.55, 0.8)


func _on_body_entered(body):
	if recogido or body.name != "Jugador":
		return

	recogido = true
	var objetivo = get_tree().current_scene.get_node_or_null("ObjetivoManager")
	if objetivo != null and objetivo.has_method("registrar_cristal"):
		objetivo.registrar_cristal(valor)

	if has_node("/root/Sfx"):
		get_node("/root/Sfx").cristal()

	queue_free()
