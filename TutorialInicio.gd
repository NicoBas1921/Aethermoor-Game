extends CanvasLayer

@onready var contenedor: VBoxContainer = $Control/VBoxContainer


func _ready():
	await get_tree().create_timer(5.0).timeout

	var tween = create_tween()
	tween.tween_property(contenedor, "modulate:a", 0.0, 0.8)
	tween.finished.connect(queue_free)
