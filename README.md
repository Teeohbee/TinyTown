# TinyTown

A micro JRPG built using Godot 4.7 with assets from [https://www.kenney.nl/](https://www.kenney.nl/)

**Chapter 1 - Granny's Bees.** A wizard has stolen Granny's bees. Grow strong enough for the
blacksmith's sword, win the archer's bow, find the castle armour and take the bees back.

**Chapter 2 - The Lost Apprentice.** Granny's grandson Pip has gone missing in the Autumn Woods.
Find Bram the woodcutter, borrow his lantern and descend into the Old Mine, past the Mole King,
to face Mordrin, the wizard's vengeful apprentice. Help Fern the forager along the way.

## Playing

- Move: arrows / WASD / D-pad / left stick
- Talk, confirm: Enter / Space / Z / E / A
- Back: Esc / X / Backspace / B
- Menu (items, skills, quests, status, options, save): Esc / M / I / Start

Battles have Attack, Skill, Item, Defend and Run. Skills are learned by levelling up and from
equipment. Defend halves damage and restores 1 MP - use it when a brute winds up a big swing.
The game autosaves whenever you enter an area; you can also save from the menu.

## Project layout

- `scripts/data/` - items, skills, enemies and quests as plain tables; tune the game here
- `scripts/autoload/` - settings and audio; `scripts/player_state.gd` holds the save game
- `scripts/world/` - area, warp, door and base NPC scripts shared by every map
- `scripts/chapter_two/` - the woods and mine characters
- `scenes/areas/` - the Autumn Woods and the Old Mine

![Screenshot_20240322_162205](https://github.com/Teeohbee/TinyTown/assets/12451318/3058e5eb-7a53-4d19-b660-9c1909b58220)
![Screenshot_20240322_162310](https://github.com/Teeohbee/TinyTown/assets/12451318/016f70d8-9481-4557-8715-bff4d3e13624)
![Screenshot_20240322_165309](https://github.com/Teeohbee/TinyTown/assets/12451318/045678d0-bccf-46bf-9b5c-4036cfd23f6a)
