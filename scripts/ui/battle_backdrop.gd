extends Control

# Paints a battle background from map tiles so each area's fights look like that area.
# Upper rows are wall/treeline tiles, the rest is floor, then a soft dark vignette on top.

const TILE_DRAW_SIZE = 64
const TOWN_ATLAS = preload("res://assets/town_tilemap.png")
const DUNGEON_ATLAS = preload("res://assets/dungeon_tilemap.png")

const BACKDROPS = {
	"castle": {"atlas": "dungeon", "wall": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(3, 1)], "wall_rows": 3, "floor": [Vector2i(0, 4), Vector2i(0, 4), Vector2i(0, 4), Vector2i(4, 4)], "tint": Color(0.75, 0.7, 0.8)},
	"woods": {"atlas": "town", "wall": [Vector2i(7, 1), Vector2i(10, 1), Vector2i(7, 1)], "wall_rows": 3, "floor": [Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(2, 0)], "tint": Color(1.0, 0.9, 0.8)},
	"mine": {"atlas": "dungeon", "wall": [Vector2i(1, 1), Vector2i(4, 2), Vector2i(1, 1), Vector2i(2, 2)], "wall_rows": 3, "floor": [Vector2i(0, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(0, 4)], "tint": Color(0.5, 0.45, 0.6)},
	"town": {"atlas": "town", "wall": [Vector2i(7, 1)], "wall_rows": 2, "floor": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(2, 0)], "tint": Color(1, 1, 1)},
}

var backdrop_name = "castle"


func show_backdrop(new_backdrop_name):
	backdrop_name = new_backdrop_name if BACKDROPS.has(new_backdrop_name) else "castle"
	queue_redraw()


func _draw():
	var backdrop = BACKDROPS[backdrop_name]
	var atlas = TOWN_ATLAS if backdrop["atlas"] == "town" else DUNGEON_ATLAS
	var columns = ceili(size.x / TILE_DRAW_SIZE)
	var rows = ceili(size.y / TILE_DRAW_SIZE)
	# Same pseudo-random pattern every time so the backdrop doesn't flicker on redraw.
	var random = RandomNumberGenerator.new()
	random.seed = hash(backdrop_name)
	for row in rows:
		for column in columns:
			var choices = backdrop["wall"] if row < backdrop["wall_rows"] else backdrop["floor"]
			var cell = choices[random.randi() % choices.size()]
			var destination = Rect2(column * TILE_DRAW_SIZE, row * TILE_DRAW_SIZE, TILE_DRAW_SIZE, TILE_DRAW_SIZE)
			draw_texture_rect_region(atlas, destination, Rect2(cell * 16, Vector2(16, 16)), backdrop["tint"])
	# The enemy's shadow, an ellipse under where its feet land
	draw_set_transform(Vector2(640, 432), 0.0, Vector2(1.0, 0.18))
	draw_circle(Vector2.ZERO, 100.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Vignette: darker towards the top and bottom edges
	for band in 12:
		var alpha = 0.06 * (12 - band) / 12.0
		draw_rect(Rect2(0, band * 8, size.x, 8), Color(0, 0, 0, alpha * 4))
		draw_rect(Rect2(0, size.y - (band + 1) * 8, size.x, 8), Color(0, 0, 0, alpha * 4))
