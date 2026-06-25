extends Control

@export var escena_seleccion_personaje := "res://SeleccionPersonaje.tscn"


func _ready():
	$VBoxContainer/Jugar.pressed.connect(_on_jugar_pressed)
	$VBoxContainer/Salir.pressed.connect(_on_salir_pressed)


func _on_jugar_pressed():
	get_tree().change_scene_to_file(escena_seleccion_personaje)


func _on_salir_pressed():
	get_tree().quit()
