# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Engine work

- Finish script converter
- Change ignea shards to all spawn in 1-1, and be distinct sprites that point to the same script (re-purpose the items script for all chapter-independent scenes).
- Make campfire flicker a little bit
- Support animation sound effects: looping sound effects associated with an animation and based on proximity to the sprite, like a crackling torch, or a person's footsteps. A particular frame of an animation should have an optional associated SFX and volume.
- Profiling, fix battle slowness
- Add a turn reset mechanic, from the in-battle options menu. Single-use.
- #73: Make executable cross-platform app

## Scene work

- 1-1:
    - Pan over campsite when entering west forest
    - Static camp dialogues
    - Carrying Elaine transition
    - 1-2 transition via camp bed
- 1-2: (#69)
    - Ally phase 3 if Elaine not carried
    - Dealing with Elaine
    - North transition
    - Post-battle dialogues

## SFX and music

- Music fade is quieter than it should be

- #4: SFX for: menu select (not too different from current), text sound effects, start game (from title screen).
- #56: SFX for: battle cursor move, Mute ally turn start/enemy turn start/victory/defeat menus. battle select ally/enemy, target for move/attack/assist, confirm end action, battle enemy turn start, battle ally turn start, level up.
- Animation sound effects for: walking, torch crackle, use weapon skill, use spell, use assist, all skills (can re-use liberally).

- #63: Title screen music, use the voice memo on my phone: Time Slows. Tentative track name: The Lonely Knight. Experiment with slow crescendos! And quiet bass. Don't let game music interrupt title music.
- #64: Defeat theme: Despair - Short theme that plays during the battle loss scene.
- #67: Better forest theme - more tense investigation, less funeral march
- #65: Enemy approaches theme - for rising action before a fight! Consider Face of Shadow

## Art and animation

- Camp beds, camp clutter, stone markers
- Better wolf and alpha wolf sprites
- Pretty title screen: Background art, fancy title, moving sprites, sfx, etc

- Kath-down, Elaine-idle, Elaine-walk, Elaine-getup

- #51: Support animation on combat entry (bridges idle -> combat), and on combat exit (this can just be the combat entry animation played in reverse). Abelon-combat-entry-exit, Abelon-combat-idle, Abelon-combat-run (try same feet as walk but bump animation speed?), Kath-combat-entry-exit, Kath-combat-idle, Kath-combat-run, Elaine-combat-entry-exit, Elaine-combat-idle, Elaine-combat-run. Wolf-idle (this doubles as Wolf-combat-idle), Wolf-walk (this doubles as Wolf-combat-run), alpha-wolf-idle, alpha-wolf-walk.

- #53: Each sprite that battles has single-fire animations: one for weapon skills, one for spells, one for assists, one for utility skills, one for being injured (still frame), and one for dying. Displacement is the same as the 'injured' animation. Abelon-weapon, Abelon-spell, Abelon-assist, Abelon-util, Abelon-hurt, Abelon-death, Kath-weapon, Kath-spell, Kath-assist, Kath-util, Kath-hurt, Kath-death, Elaine-weapon, Elaine-spell, Elaine-assist, Elaine-util, Elaine-hurt, Elaine-death, Wolf-weapon, Wolf-hurt, Wolf-death.

- #52: Skill animations for (31): Clutches, Contempt, Trust, Inspire, Confidence, Flank, Punish, Judgement, Shove, Javelin, Hold the Line, Thrust, Sweep, Stun, Forbearance, Enrage, Caution, Healing Mist, Invigorate, Haste, Observe, Precise Shot, Terrain Survey, Hunting Shot, Lay Traps, Ignea Arrowheads, Wind Blast, Cover Fire, Farsight, Volley

- #47: Better portraits

## 1-3

- Update narrative.md 1-1 and 1-2. Write 1-3, 1-4 of narrative.md.
- #70: Shanti, Living Rock animations
- Write script 1-3.md
- #71: Implement 1-3. Includes additional map to the north of north forest, the monastery approach.

## 1-4

- #68: Write 1-4 script, last pass over script for consistency
- Lester, Forest terror sprite and animations
- #72: Implement 1-4
- #66: 1-4 battle theme: "final boss"
- #74: Pre-alpha closed release