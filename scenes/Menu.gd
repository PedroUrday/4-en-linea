extends Control

const DEFAULT_PORT = 9000

func _on_host_pressed():
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(DEFAULT_PORT, 1) # Maximum of 1 peer, since it's a 2-player game.
	if err != OK:
		$error.text = "No se puede crear la partida.\n El puerto de red número " + str(DEFAULT_PORT) + " está en uso."
		$error.show()
		return
	get_tree().set_network_peer(peer)
	$status.text = "Esperando a otro jugador..."
	$status.show()

func _on_join_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client($ip.text, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	$status.text = "Conectando..."
	$status.show()

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")

func _on_player_connected(peer_id):
	if get_tree().is_network_server():
		get_tree().change_scene("res://scenes/Game.tscn")

func _on_connected_to_server():
	get_tree().change_scene("res://scenes/Game.tscn")

func _on_connection_failed():
	$error.text = "Error de conexión."
