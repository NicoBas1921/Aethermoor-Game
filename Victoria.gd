extends Control

@export var escena_mapa := "res://mundo__valecrest.tscn"
@export var escena_menu := "res://MenuPrincipal.tscn"


func _ready():
	$VBoxContainer/ReiniciarNivel.pressed.connect(_on_reiniciar_nivel_pressed)
	$VBoxContainer/VolverMenu.pressed.connect(_on_volver_menu_pressed)


func _on_reiniciar_nivel_pressed():
	get_tree().change_scene_to_file(escena_mapa)


func _on_volver_menu_pressed():
	get_tree().change_scene_to_file(escena_menu)
