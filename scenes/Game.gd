extends Node2D

const COLUMNS = 7
const ROWS = 6
const PIECE_SIZE = 48
const PIECE_MARGIN = 8
const CELL_SIZE = PIECE_SIZE + 2 * PIECE_MARGIN
const BOARD_MARGIN = 8
const BOARD_WIDTH = COLUMNS * CELL_SIZE
const BOARD_HEIGHT = ROWS * CELL_SIZE

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

const RedPiece = preload("res://scenes/RedPiece.tscn")
const YellowPiece = preload("res://scenes/YellowPiece.tscn")

var board = []
var is_my_turn = false
var is_input_blocked = false
var is_gameover = false

func _ready():
	for x in COLUMNS:
		board.append([])

	match get_lang():
		"es":
			$leave_game.text = "Abandonar"
		"en":
			$leave_game.text = "Leave game"
	if get_tree().is_network_server():
		is_my_turn = true
	show_player_turn()

	get_tree().connect("network_peer_disconnected", self, "on_player_disconnected")
	get_tree().connect("server_disconnected", self, "on_disconnected_from_server")

func show_player_turn():
	if is_my_turn:
		match get_lang():
			"es":
				$status.text = "Es tu turno"
			"en":
				$status.text = "It's your turn"
	else:
		match get_lang():
			"es":
				$status.text = "Es el turno del oponente"
			"en":
				$status.text = "It's the opponent's turn"

func show_opponent_left_game_msg():
	match get_lang():
		"es":
			$status.text = "El oponente ha abandonado la partida"
		"en":
			$status.text = "The opponent has left the game"

func on_player_disconnected(peer_id):
	if get_tree().is_network_server():
		is_gameover = true
		show_opponent_left_game_msg()
	
func on_disconnected_from_server():
	is_gameover = true
	show_opponent_left_game_msg()

func end_game():
	get_tree().set_network_peer(null)
	get_tree().change_scene("res://scenes/Menu.tscn")

func on_leave_game_pressed():
	end_game()

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
	if pos_x >= BOARD_MARGIN && pos_x < BOARD_MARGIN + BOARD_WIDTH:
		return int((pos_x - BOARD_MARGIN) / CELL_SIZE)
	else:
		return -1

func get_piece_target_pos(column):
	if column >= 0 && column < COLUMNS:
		var target_pos = Vector2()
		target_pos.x = BOARD_MARGIN + column * CELL_SIZE + PIECE_MARGIN
		target_pos.y = BOARD_MARGIN + BOARD_HEIGHT - board[column].size() * CELL_SIZE
		return target_pos
	else:
		return null

func can_place_piece(column):
	if column >= 0 && column < COLUMNS:
		if board[column].size() < ROWS:
			return true
	return false

func make_move(piece_color, column):
	var piece
	match piece_color:
		"yellow":
			piece = YellowPiece.instance()
		"red":
			piece = RedPiece.instance()
	piece.position.x = BOARD_MARGIN + column * CELL_SIZE + PIECE_MARGIN
	piece.position.y = -(PIECE_MARGIN + PIECE_SIZE)
	add_child(piece)
	board[column].append(piece)
	var piece_target_pos = get_piece_target_pos(column)
	piece.move_toward(piece_target_pos, $Timer.wait_time)
	is_input_blocked = true
	$Timer.start()

func on_piece_fall():
	var winner_color = get_winner_color();
	if winner_color == null:
		is_input_blocked = false
		is_my_turn = not is_my_turn
		show_player_turn()
	else:
		if winner_color == "red":
			match get_lang():
				"es":
					$status.text = "Has perdido!"
				"en":
					$status.text = "You've lost!"
		elif winner_color == "yellow":
			match get_lang():
				"es":
					$status.text = "Has ganado!"
				"en":
					$status.text = "You've won!"
		is_gameover = true

remote func make_opponent_move(column):
	if can_place_piece(column):
		make_move("red", column)

func _input(event):
	if not is_gameover && is_my_turn && not is_input_blocked && event.is_action_released("ui_touch"):
		var column = get_column(event.position.x)
		if can_place_piece(column):
			make_move("yellow", column)
			if get_tree().is_network_server():
				rpc("make_opponent_move", column)
			else:
				rpc_id(1, "make_opponent_move", column)
