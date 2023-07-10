# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## 1-1

- Assets: ignea-stone, campfire, camp beds, stone reliefs, Lester-down, Shanti-down, Kath-down Elaine-idle, Elaine-walk, Elaine-getup, Elaine portrait
- Implement 1-1, connect to 1-2 battle

## 1-2

- Finish script 1-2
- #69: Implement rest of 1-2, its optional content (present medallion, extra convos, etc) and barrier dialogue preventing going north

## Game presentation

- #51: Support animation on combat entry (bridges idle -> combat), and on for  combat exit (this can just be the combat entry animation played in reverse). Abelon-combat-entry-exit, Abelon-combat-idle, Abelon-combat-run (try same feet as walk but bump animation speed?), Kath-combat-entry-exit, Kath-combat-idle, Kath-combat-run, Elaine-combat-entry-exit, Elaine-combat-idle, Elaine-combat-run.
- Two mostly identical wolf sprites, Wolf-idle (this doubles as Wolf-combat-idle), Wolf-walk (this doubles as Wolf-combat-run).
- #52: Every skill has an associated single-fire animation, with render position determined by the cursor location of the cast. This has nothing to do with the sprite casting the skill. For some skills, the animation should play at every affected tile, for others, the animation should play centered on the cursor and affected by direction. This should be provided as an option. Make skill animations for all basic skills.
- #53: Each sprite that battles has single-fire animations: one for weapon skills, one for spells, one for assists, one for being injured, and one for dying. Displacement is a still frame from the 'injured' animation. Abelon-weapon, Abelon-spell, Abelon-assist, Abelon-util, Abelon-hurt, Abelon-death, Kath-weapon, Kath-spell, Kath-assist, Kath-util, Kath-hurt, Kath-death, Elaine-weapon, Elaine-spell, Elaine-assist, Elaine-util, Elaine-hurt, Elaine-death, Wolf-weapon, Wolf-hurt, Wolf-death.

- Animation sound effects: Explore "animation sound effects": looping sound effects associated with an animation and based on proximity to the sprite, like a crackling torch, or a person's footsteps.
- #4: SFX for:, menu select (not too different from current), text sound effects, start game (from title screen).
- #56: SFX for: battle cursor move, Mute ally turn start/enemy turn start/victory/defeat menus. battle select ally/enemy, target for move/attack/assist, confirm end action, battle enemy turn start, battle ally turn start, level up, use weapon skill, use spell, use assist, skills (can re-use liberally).

- Profiling, fix battle slowness
- Add a turn reset mechanic, from the in-battle options menu. Single-use.
- A static foreground (to outline and "frame" the game) per map could be fun and not that hard

- Music fade is quieter than it should be
- #63: Title screen music, use the voice memo on my phone: Time Slows. Tentative track name: The Lonely Knight. Experiment with slow crescendos! And quiet bass. Don't let game music interrupt title music.
- #64: Defeat theme: Despair - Short theme that plays during the battle loss scene.
- #67: Better forest theme - more tense investigation, less funeral march
- #65: Enemy approaches theme - for rising action before a fight! Consider Face of Shadow

- Pretty title screen: Background art, fancy title, moving sprites, sfx, etc
- #47: Better portraits

- #73: Make executable cross-platform app
- Mini-release

## 1-3

- #70: Shanti, Living Rock sprites and animations

- Update narrative.md 1-1 and 1-2. Write 1-3, 1-4 of narrative.md.
- Write script 1-3.md

- #71: Implement 1-3. Includes additional map to the north of north forest, the monastery approach.

## 1-4

- Write 1-4 script
- #68: Last pass over script for consistency

- Lester, Forest terror sprite and animations

- #72: Implement 1-4
- Improve AI algorithm - use other plans! In particular, enemies shouldn't interfere with each other. If one enemy has only a single path to attack their target, the acting enemy shouldn't get in the way of that path unless it needs to in order to attack its own target. To minimize interference in general, the strongest enemies should take their turns first, and the enemies who start farther away from the allies should also be prioritized.

- #66: 1-4 battle theme: "final boss"
- #66: 1-1 battle theme

- #74: Pre-alpha closed release