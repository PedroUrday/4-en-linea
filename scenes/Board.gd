extends Node2D

const COLUMNS = 7
const ROWS = 6
const CELL_SIZE = 64
const BOARD_WIDTH = COLUMNS * CELL_SIZE
const BOARD_HEIGHT = ROWS * CELL_SIZE
export (int) var PIECE_SPEED
var RedPiece = preload("res://scenes/RedPiece.tscn")
var YellowPiece = preload("res://scenes/YellowPiece.tscn")
var board = []
var piece = null
var is_my_turn = false
var is_input_blocked = false
var is_gameover = false
var status

func _ready():
	for x in COLUMNS:
		board.append([])
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	if get_tree().is_network_server():
		is_my_turn = true
	status = get_node("/root/Game/status")
	show_player_turn()

func _on_leave_game_pressed():
	get_tree().set_network_peer(null)
	get_tree().change_scene("res://scenes/Menu.tscn")

func show_player_turn():
	if is_my_turn:
		status.text = "Es tu turno"
	else:
		status.text = "Es el turno del oponente"

func show_opponent_left_game_msg():
	status.text = "El oponente ha abandonado la partida"

func _on_player_disconnected(peer_id):
	if get_tree().is_network_server():
		show_opponent_left_game_msg()
	
func _on_disconnected_from_server():
	show_opponent_left_game_msg()

func get_cell_color(x, y):
	if x < 0 || x >= COLUMNS || y < 0 || y >= ROWS || y >= board[x].size():
		return null
	else:
		return board[x][y].color

func get_winner_color():
	for y in range(0, ROWS - 3):
		for x in range(0, COLUMNS):
			var color = get_cell_color(x, y)
			if color != null and color == get_cell_color(x, y + 1) and color == get_cell_color(x, y + 2) and color == get_cell_color(x, y + 3):
				return color
	for x in range(0, COLUMNS - 3):
		for y in range(0, ROWS):
			var color = get_cell_color(x, y)
			if color != null and color == get_cell_color(x + 1, y) and color == get_cell_color(x + 2, y) and color == get_cell_color(x + 3, y):
				return color
	for x in range(3, COLUMNS):
		for y in range(0, ROWS - 3):
			var color = get_cell_color(x, y)
			if color != null and color == get_cell_color(x - 1, y + 1) and color == get_cell_color(x - 2, y + 2) and color == get_cell_color(x - 3, y + 3):
				return color
	for x in range(3, COLUMNS):
		for y in range(3, ROWS):
			var color = get_cell_color(x, y)
			if color != null and color == get_cell_color(x - 1, y - 1) and color == get_cell_color(x - 2, y - 2) and color == get_cell_color(x - 3, y - 3):
				return color
	return null

func get_column(pos_x):
	if pos_x >= 0 && pos_x < BOARD_WIDTH:
		return int(pos_x / CELL_SIZE)
	else:
		return -1

func get_pos_x(column):
	if column >= 0 && column < COLUMNS:
		return column * CELL_SIZE
	else:
		return -1

func can_place_piece(column):
	if column >= 0 && column < COLUMNS:
		if board[column].size() < ROWS:
			return true
	return false

func make_move(piece_color, column):
	var piece_pos_x = get_pos_x(column)
	if piece_color == "yellow":
		piece = YellowPiece.instance()
	elif piece_color == "red":
		piece = RedPiece.instance()
	else:
		return false
	piece.position.x = piece_pos_x
	piece.position.y = 0
	add_child(piece)
	is_input_blocked = true

remote func make_opponent_move(column):
	return make_move("red", column)

func _input(event):
	if not is_gameover && is_my_turn && not is_input_blocked && event.is_action_released("ui_touch"):
		var column = get_column(event.position.x)
		if can_place_piece(column):
			make_move("yellow", column)
			if get_tree().is_network_server():
				rpc("make_opponent_move", column)
			else:
				rpc_id(1, "make_opponent_move", column)

func _process(delta):
	if not is_gameover && is_input_blocked:
		var column = get_column(piece.position.x)
		var limit_y = BOARD_HEIGHT - board[column].size() * CELL_SIZE
		var new_piece_pos_y = piece.position.y + PIECE_SPEED * delta
		if new_piece_pos_y < limit_y:
			piece.position.y = new_piece_pos_y
		else:
			piece.position.y = limit_y
			board[column].append(piece)
			piece = null
			var winner_color = get_winner_color();
			if winner_color == null:
				is_input_blocked = false
				is_my_turn = not is_my_turn
				show_player_turn()
			else:
				if winner_color == "red":
					status.text = "Has perdido!"
				elif winner_color == "yellow":
					status.text = "Has ganado!"
				is_gameover = true
