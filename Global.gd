extends Node

const PERSONAJES = {
	"caballero": {
		"frame": Vector2(0, 11),
		"dano": 40,
		"rango_casillas": 1.0,
		"tipo_ataque": "melee",
	},
	"maga": {
		"frame": Vector2(1, 5),
		"dano": 20,
		"rango_casillas": 5.0,
		"tipo_ataque": "distancia",
	},
}

var personaje_actual: String = "caballero"
var frame_seleccionado: Vector2 = Vector2(0, 11)
var dano: int = 40
var rango_ataque_casillas: float = 1.0
var tipo_ataque: String = "melee"
var escena_mapa: String = "res://mundo__valecrest.tscn"
var escena_menu_principal: String = "res://MenuPrincipal.tscn"


func seleccionar_personaje(tipo_personaje: String):
	if not PERSONAJES.has(tipo_personaje):
		return

	var datos = PERSONAJES[tipo_personaje]
	personaje_actual = tipo_personaje
	frame_seleccionado = Vector2(datos["frame"])
	dano = int(datos["dano"])
	rango_ataque_casillas = float(datos["rango_casillas"])
	tipo_ataque = str(datos["tipo_ataque"])
