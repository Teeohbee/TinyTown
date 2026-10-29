extends RefCounted

# Battle skills. A skill is known once its requirement is met:
#   "level": the player's level, or "flag": an equipment / story flag on PlayerState.
# The battle scene reads "effect" to decide what happens:
#   "strike"  - damage_multiplier x a normal hit, hit_count times
#   "heal"    - restore heal_fraction of max HP
#   "stun"    - a weaker hit with stun_chance of making the enemy lose its turn

const SKILLS = {
	"power_strike": {
		"name": "Power Strike",
		"description": "A heavy blow. 1.8x damage, never misses.",
		"magic_cost": 3,
		"requires_level": 2,
		"effect": "strike",
		"damage_multiplier": 1.8,
		"hit_count": 1,
		"never_misses": true,
	},
	"mend": {
		"name": "Mend",
		"description": "Patch yourself up. Heals half your max HP.",
		"magic_cost": 4,
		"requires_level": 3,
		"effect": "heal",
		"heal_fraction": 0.5,
	},
	"shield_bash": {
		"name": "Shield Bash",
		"description": "A weak hit that may stun the enemy for a turn.",
		"magic_cost": 3,
		"requires_level": 4,
		"effect": "stun",
		"damage_multiplier": 0.6,
		"stun_chance": 0.6,
	},
	"volley": {
		"name": "Volley",
		"description": "Loose three arrows at 0.6x damage each.",
		"magic_cost": 5,
		"requires_flag": "bow_upgrade",
		"effect": "strike",
		"damage_multiplier": 0.6,
		"hit_count": 3,
		"never_misses": false,
	},
	"timber": {
		"name": "Timber!",
		"description": "Bram's secret swing. 3x damage, never misses.",
		"magic_cost": 8,
		"requires_flag": "axe_upgrade",
		"effect": "strike",
		"damage_multiplier": 3.0,
		"hit_count": 1,
		"never_misses": true,
	},
}

const SKILL_ORDER = ["power_strike", "mend", "shield_bash", "volley", "timber"]


static func skill(skill_id):
	return SKILLS[skill_id]


static func is_known(skill_id, player_state):
	var definition = SKILLS[skill_id]
	if definition.has("requires_level"):
		return player_state.level >= definition["requires_level"]
	return player_state.get(definition["requires_flag"]) == true


static func known_skills(player_state):
	var known = []
	for skill_id in SKILL_ORDER:
		if is_known(skill_id, player_state):
			known.append(skill_id)
	return known


# Skills that become known exactly at this level, for the level-up message.
static func skills_learned_at_level(level):
	var learned = []
	for skill_id in SKILL_ORDER:
		if SKILLS[skill_id].get("requires_level", -1) == level:
			learned.append(skill_id)
	return learned
