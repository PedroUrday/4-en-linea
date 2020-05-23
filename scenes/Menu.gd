extends Control

func get_lang():
	var locale = OS.get_locale()
	var ch_idx = locale.find("_")
	var lang
	if ch_idx >= 0:
		lang = locale.left(ch_idx)
	else:
		lang = locale
	if lang == "es":
		return "es"
	else:
		return "en"

const DEFAULT_PORT = 9000

func on_host_pressed():
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(DEFAULT_PORT, 1) # Maximum of 1 client peer, because it's a 2-player game.
	if err != OK:
		match get_lang():
			"es":
				$error.text = "No se puede crear la partida porque el puerto de red número " + str(DEFAULT_PORT) + " está en uso."
			"en":
				$error.text = "You can't host a game because the network port number " + str(DEFAULT_PORT) + " is in use"
		$error.show()
		return
	get_tree().set_network_peer(peer)
	match get_lang():
		"es":
			$status.text = "Esperando a otro jugador..."
		"en":
			$status.text = "Waiting for another player..."
	$status.show()

func on_join_pressed():
	var peer = NetworkedMultiplayerENet.new()
	if ($ip.text.is_valid_ip_address()):
		peer.create_client($ip.text, DEFAULT_PORT)
		get_tree().set_network_peer(peer)
		match get_lang():
			"es":
				$status.text = "Conectando..."
			"en":
				$status.text = "Connecting..."
		$status.show()
	else:
		show_connection_error()

func _ready():
	match get_lang():
		"es":
			$host.text = "Crear partida"
			$join.text = "Unirse a partida"
		"en":
			$host.text = "Host game"
			$join.text = "Join game"

	get_tree().connect("network_peer_connected", self, "on_player_connected")
	get_tree().connect("connected_to_server", self, "on_connected_to_server")
	get_tree().connect("connection_failed", self, "on_connection_failed")

func start_game():
	get_tree().change_scene("res://scenes/Game.tscn")

func on_player_connected(peer_id):
	if get_tree().is_network_server():
		start_game()

func on_connected_to_server():
	start_game()

func show_connection_error():
	match get_lang():
		"es":
			$error.text = "Error de conexión."
		"en":
			$error.text = "Connection error."

func on_connection_failed():
	show_connection_error()
