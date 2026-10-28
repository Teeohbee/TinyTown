extends RefCounted

# Every monster in the game. Sprites are cells in the dungeon tile atlas.
#   evasion   - chance the player's attack misses (0.0 to 1.0)
#   defence   - fraction of the player's damage ignored
#   abilities - ability id -> weight; the battle picks one each turn (see battle.gd)
#   passives  - "regenerate" heals 2 HP every turn
#   tint      - multiplies the sprite colour, so bosses can reuse a cell
#   boss      - can't be run from, gets the boss intro and music pitch

const ATLAS = "res://assets/dungeon_tilemap.png"

const ENEMIES = {
	# The castle dungeon (Chapter 1)
	"rat": {
		"name": "Rat",
		"cell": Vector2i(3, 10),
		"max_health": 12,
		"min_damage": 1,
		"max_damage": 4,
		"experience": [3, 6],
		"gold": [1, 4],
		"abilities": {"attack": 3, "nibble": 1},
		"drops": [["potion", 0.15]],
	},
	"spider": {
		"name": "Spider",
		"cell": Vector2i(2, 10),
		"max_health": 10,
		"min_damage": 2,
		"max_damage": 4,
		"experience": [3, 6],
		"gold": [2, 5],
		"abilities": {"attack": 2, "poison_bite": 1},
		"drops": [["antidote", 0.2]],
	},
	"ghost": {
		"name": "Ghost",
		"cell": Vector2i(1, 10),
		"max_health": 7,
		"min_damage": 3,
		"max_damage": 4,
		"evasion": 0.2,
		"experience": [3, 6],
		"gold": [2, 6],
		"abilities": {"attack": 1, "drain": 1},
		"drops": [["ether", 0.15]],
	},
	"cyclops": {
		"name": "Cyclops",
		"cell": Vector2i(1, 9),
		"max_health": 15,
		"min_damage": 2,
		"max_damage": 5,
		"experience": [4, 7],
		"gold": [3, 7],
		"abilities": {"attack": 2, "heavy_windup": 1},
		"drops": [["potion", 0.2]],
	},
	"wizard": {
		"name": "Wizard",
		"cell": Vector2i(0, 7),
		"max_health": 50,
		"min_damage": 5,
		"max_damage": 10,
		"experience": [100, 100],
		"gold": [40, 40],
		"abilities": {"attack": 2, "fireball": 2, "heal_self": 1},
		"enrages_below_half": true,
		"boss": true,
	},
	# The Autumn Woods (Chapter 2)
	"slime": {
		"name": "Slime",
		"cell": Vector2i(0, 9),
		"max_health": 16,
		"min_damage": 2,
		"max_damage": 5,
		"experience": [5, 8],
		"gold": [3, 6],
		"abilities": {"attack": 3, "engulf": 1},
		"passives": ["regenerate"],
		"drops": [["potion", 0.2]],
	},
	"bat": {
		"name": "Bat",
		"cell": Vector2i(0, 10),
		"max_health": 11,
		"min_damage": 3,
		"max_damage": 5,
		"evasion": 0.3,
		"experience": [5, 8],
		"gold": [2, 5],
		"abilities": {"attack": 2, "drain": 1},
		"drops": [["ether", 0.15]],
	},
	"snapper": {
		"name": "Snapper",
		"cell": Vector2i(2, 9),
		"max_health": 20,
		"min_damage": 3,
		"max_damage": 6,
		"defence": 0.3,
		"experience": [7, 10],
		"gold": [5, 9],
		"abilities": {"attack": 2, "harden": 1, "nibble": 1},
		"drops": [["hi_potion", 0.1]],
	},
	"wild_spider": {
		"name": "Wild Spider",
		"cell": Vector2i(2, 10),
		"tint": Color(1.0, 0.75, 0.55),
		"max_health": 15,
		"min_damage": 3,
		"max_damage": 6,
		"experience": [6, 9],
		"gold": [3, 7],
		"abilities": {"attack": 2, "poison_bite": 2},
		"drops": [["antidote", 0.3]],
	},
	# The Old Mine (Chapter 2)
	"cave_mole": {
		"name": "Cave Mole",
		"cell": Vector2i(4, 10),
		"max_health": 24,
		"min_damage": 4,
		"max_damage": 7,
		"defence": 0.15,
		"experience": [9, 12],
		"gold": [6, 10],
		"abilities": {"attack": 3, "harden": 1, "heavy_windup": 1},
		"drops": [["potion", 0.25]],
	},
	"acolyte": {
		"name": "Hooded Acolyte",
		"cell": Vector2i(3, 9),
		"max_health": 20,
		"min_damage": 4,
		"max_damage": 7,
		"evasion": 0.1,
		"experience": [10, 14],
		"gold": [8, 14],
		"abilities": {"attack": 2, "fireball": 2, "heal_self": 1},
		"drops": [["ether", 0.3]],
	},
	"cave_bat": {
		"name": "Cave Bat",
		"cell": Vector2i(0, 10),
		"tint": Color(0.75, 0.7, 1.0),
		"max_health": 16,
		"min_damage": 4,
		"max_damage": 6,
		"evasion": 0.3,
		"experience": [8, 11],
		"gold": [4, 8],
		"abilities": {"attack": 2, "drain": 2},
		"drops": [["ether", 0.2]],
	},
	"mimic": {
		"name": "Mimic",
		"cell": Vector2i(8, 7),
		"max_health": 34,
		"min_damage": 5,
		"max_damage": 9,
		"defence": 0.2,
		"experience": [25, 25],
		"gold": [40, 40],
		"abilities": {"attack": 2, "nibble": 2, "steal": 1},
		"drops": [["hi_potion", 1.0]],
		"cannot_flee": true,
	},
	"mole_king": {
		"name": "Mole King",
		"cell": Vector2i(4, 10),
		"tint": Color(1.0, 0.8, 0.45),
		"max_health": 90,
		"min_damage": 6,
		"max_damage": 10,
		"defence": 0.2,
		"experience": [60, 60],
		"gold": [50, 50],
		"abilities": {"attack": 3, "heavy_windup": 2, "harden": 1},
		"enrages_below_half": true,
		"boss": true,
	},
	"mordrin": {
		"name": "Mordrin",
		"cell": Vector2i(3, 9),
		"tint": Color(0.85, 0.6, 1.0),
		"max_health": 130,
		"min_damage": 7,
		"max_damage": 11,
		"evasion": 0.1,
		"experience": [150, 150],
		"gold": [100, 100],
		"abilities": {"attack": 2, "fireball": 2, "drain": 1, "curse": 1, "heal_self": 1},
		"enrages_below_half": true,
		"boss": true,
	},
}


static func enemy(enemy_id):
	return ENEMIES[enemy_id]


static func texture(enemy_id):
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = load(ATLAS)
	atlas_texture.region = Rect2(ENEMIES[enemy_id]["cell"] * 16, Vector2(16, 16))
	return atlas_texture
