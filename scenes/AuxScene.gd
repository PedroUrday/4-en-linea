extends Node2D

# Auxiliary scene for drawing the game board

const COLUMNS = 7
const ROWS = 6
const BOARD_PADDING = 8
const PIECE_MARGIN = 8
const PIECE_SIZE = 48
const CELL_SIZE = PIECE_SIZE + 2 * PIECE_MARGIN
const BOARD_COLOR = Color.blue
const PIECE_PLACE_COLOR = Color.white

func _draw():
	draw_rect(Rect2(0, 0, COLUMNS * CELL_SIZE + 2 * BOARD_PADDING, ROWS * CELL_SIZE + 2 * BOARD_PADDING), BOARD_COLOR)
	for x in COLUMNS:
		for y in ROWS:
			draw_circle(Vector2(BOARD_PADDING + CELL_SIZE / 2 + x * CELL_SIZE, BOARD_PADDING + CELL_SIZE / 2 + y * CELL_SIZE), PIECE_SIZE / 2 - 1, PIECE_PLACE_COLOR)
