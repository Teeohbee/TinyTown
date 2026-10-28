extends CanvasLayer

# The always-on character panel, plus the area name banner.

const HEALTH_COLOUR = Color(0.86, 0.25, 0.3)
const LOW_HEALTH_COLOUR = Color(1.0, 0.55, 0.2)
const MAGIC_COLOUR = Color(0.3, 0.55, 0.95)
const EQUIPMENT_ICONS = {
	"sword_upgrade": "res://assets/tile_0106.png",
	"bow_upgrade": "res://assets/tile_0118.png",
	"armour_upgrade": "res://assets/tile_0102.png",
}

@onready var level_label = $CharacterPanel/Rows/Header/Level
@onready var gold_label = $CharacterPanel/Rows/Header/Gold
@onready var health_bar = $CharacterPanel/Rows/HealthBar
@onready var magic_bar = $CharacterPanel/Rows/MagicBar
@onready var experience_label = $CharacterPanel/Rows/Experience
@onready var equipment_row = $CharacterPanel/Rows/Equipment
@onready var area_banner = $AreaBanner
@onready var hint_label = $Hint


func _ready():
	PlayerState.stats_changed.connect(refresh)
	tint_bar(health_bar, HEALTH_COLOUR)
	tint_bar(magic_bar, MAGIC_COLOUR)
	refresh()
	var fade_hint = create_tween()
	fade_hint.tween_interval(6.0)
	fade_hint.tween_property(hint_label, "modulate:a", 0.0, 1.0)


func tint_bar(bar, colour):
	var fill = bar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = colour
	bar.add_theme_stylebox_override("fill", fill)


func refresh():
	level_label.text = "Lv %d" % PlayerState.level
	gold_label.text = "%d G" % PlayerState.gold
	health_bar.max_value = PlayerState.max_health
	health_bar.value = PlayerState.health
	health_bar.get_node("Label").text = "HP %d/%d" % [PlayerState.health, PlayerState.max_health]
	var low_health = PlayerState.health * 4 <= PlayerState.max_health
	tint_bar(health_bar, LOW_HEALTH_COLOUR if low_health else HEALTH_COLOUR)
	magic_bar.max_value = PlayerState.max_magic
	magic_bar.value = PlayerState.magic
	magic_bar.get_node("Label").text = "MP %d/%d" % [PlayerState.magic, PlayerState.max_magic]
	experience_label.text = "EXP %d/%d" % [PlayerState.experience, PlayerState.experience_required]
	refresh_equipment()


func refresh_equipment():
	for child in equipment_row.get_children():
		child.queue_free()
	for flag in EQUIPMENT_ICONS.keys():
		if PlayerState.get(flag):
			add_equipment_icon(load(EQUIPMENT_ICONS[flag]))
	if PlayerState.axe_upgrade:
		var axe = AtlasTexture.new()
		axe.atlas = load("res://assets/town_tilemap.png")
		axe.region = Rect2(7 * 16, 10 * 16, 16, 16)
		add_equipment_icon(axe)


func add_equipment_icon(texture):
	var icon = TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	equipment_row.add_child(icon)


func show_area_name(area_name):
	if area_name == "":
		return
	area_banner.get_node("Label").text = area_name
	area_banner.reset_size()
	area_banner.position.x = (get_viewport().get_visible_rect().size.x - area_banner.size.x) / 2
	var tween = create_tween()
	tween.tween_property(area_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.8)
	tween.tween_property(area_banner, "modulate:a", 0.0, 0.6)
