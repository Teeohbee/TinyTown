extends RefCounted

# Every item in the game. Icons are cells in the dungeon or town tile atlas.
#   kind "consumable" can be used from the bag (in battle and/or on the field)
#   kind "key" is a quest item: never sold, never used up

const DUNGEON_ATLAS = "res://assets/dungeon_tilemap.png"
const TOWN_ATLAS = "res://assets/town_tilemap.png"

const ITEMS = {
	"potion": {
		"name": "Potion",
		"description": "Restores 20 HP.",
		"kind": "consumable",
		"atlas": DUNGEON_ATLAS,
		"cell": Vector2i(7, 10),
		"price": 12,
		"heal_health": 20,
		"usable_in_field": true,
	},
	"hi_potion": {
		"name": "Hi-Potion",
		"description": "Restores 50 HP.",
		"kind": "consumable",
		"atlas": DUNGEON_ATLAS,
		"cell": Vector2i(7, 9),
		"price": 30,
		"heal_health": 50,
		"usable_in_field": true,
	},
	"ether": {
		"name": "Ether",
		"description": "Restores 10 MP.",
		"kind": "consumable",
		"atlas": DUNGEON_ATLAS,
		"cell": Vector2i(8, 10),
		"price": 20,
		"heal_magic": 10,
		"usable_in_field": true,
	},
	"antidote": {
		"name": "Antidote",
		"description": "Cures poison and burns.",
		"kind": "consumable",
		"atlas": DUNGEON_ATLAS,
		"cell": Vector2i(6, 10),
		"price": 8,
		"cures_status": true,
		"usable_in_field": true,
	},
	"bomb": {
		"name": "Bomb",
		"description": "Deals 25 damage. Never misses.",
		"kind": "consumable",
		"atlas": TOWN_ATLAS,
		"cell": Vector2i(9, 8),
		"price": 25,
		"damage": 25,
		"usable_in_field": false,
	},
	"honey": {
		"name": "Honey Pot",
		"description": "Granny's best. Restores all HP and MP.",
		"kind": "consumable",
		"atlas": TOWN_ATLAS,
		"cell": Vector2i(10, 7),
		"price": 0,
		"heal_health": 999,
		"heal_magic": 999,
		"usable_in_field": true,
	},
	"mushroom": {
		"name": "Glowcap",
		"description": "A faintly glowing mushroom. Someone wants these.",
		"kind": "key",
		"atlas": TOWN_ATLAS,
		"cell": Vector2i(5, 2),
		"price": 0,
	},
	"gate_key": {
		"name": "Gate Key",
		"description": "Granny's key to the West Gate.",
		"kind": "key",
		"atlas": TOWN_ATLAS,
		"cell": Vector2i(9, 9),
		"price": 0,
	},
	"lantern": {
		"name": "Lantern",
		"description": "Bram's lantern. Lights the way in the Old Mine.",
		"kind": "key",
		"atlas": TOWN_ATLAS,
		"cell": Vector2i(8, 10),
		"price": 0,
	},
	"iron_key": {
		"name": "Iron Key",
		"description": "The Mole King swallowed it. Opens the deep gate.",
		"kind": "key",
		"atlas": TOWN_ATLAS,
		"cell": Vector2i(9, 9),
		"price": 0,
	},
}


static func item(item_id):
	return ITEMS[item_id]


static func display_name(item_id):
	return ITEMS[item_id]["name"]


static func is_key_item(item_id):
	return ITEMS[item_id]["kind"] == "key"


static func icon(item_id):
	var definition = ITEMS[item_id]
	var texture = AtlasTexture.new()
	texture.atlas = load(definition["atlas"])
	texture.region = Rect2(definition["cell"] * 16, Vector2(16, 16))
	return texture
