extends Control

@export var frame_heroe_1 := Vector2(0, 11)
@export var frame_heroe_2 := Vector2(1, 5)
@export var escena_mapa := "res://mundo__valecrest.tscn"


func _ready():
	$VBoxContainer/Heroe1.pressed.connect(_on_heroe_1_pressed)
	$VBoxContainer/Heroe2.pressed.connect(_on_heroe_2_pressed)


func _on_heroe_1_pressed():
	_elegir_personaje(frame_heroe_1)


func _on_heroe_2_pressed():
	_elegir_personaje(frame_heroe_2)


func _elegir_personaje(frame_personaje: Vector2):
	Global.frame_seleccionado = frame_personaje
	get_tree().change_scene_to_file(escena_mapa)
