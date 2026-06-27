extends Node

const SAMPLE_RATE := 22050


func cristal():
	_tono(880.0, 0.08, 0.12)
	_tono(1320.0, 0.09, 0.10)


func consumible():
	_tono(660.0, 0.10, 0.10)


func golpe():
	_tono(180.0, 0.07, 0.14)


func dano():
	_tono(120.0, 0.10, 0.13)


func ataque_magico():
	_tono(520.0, 0.08, 0.10)


func _tono(frecuencia: float, duracion: float, volumen: float):
	var player = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = duracion + 0.05
	player.stream = generator
	player.volume_db = linear_to_db(volumen)
	add_child(player)
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var frames = int(SAMPLE_RATE * duracion)
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var fade = 1.0 - float(i) / max(1.0, float(frames))
		var sample = sin(TAU * frecuencia * t) * fade
		playback.push_frame(Vector2(sample, sample))

	await get_tree().create_timer(duracion + 0.05).timeout
	player.queue_free()
