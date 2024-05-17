# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Scene work

- Choreograph dealing with Elaine
- Add stone markers
- Insert debug statements that print when impressions change, to make sure its all correct. Try every dialogue path.

## Engine work / bugfixing

- Fix overflowing dialogue boxes. Map book and Elaine saying "or whatever"
- Change ignea shards to all spawn in 1-1, and be distinct sprites that point to the same re-usable script (re-purpose the items script for all chapter-independent scenes).
- Campfire flicker
- Support animation on combat entry (bridges idle -> combat), and on combat exit (this can just be the combat entry animation played in reverse).
- Explore baked-in shadows under human/creature sprites to give the appearance of depth.
- Support animation sound effects: looping sound effects associated with an animation and based on proximity to the sprite, like a crackling torch, or a person's footsteps. A particular frame of an animation should have an optional associated SFX and volume.
- Profiling, fix battle slowness

## SFX and music

- #4: SFX for: menu select (not too different from current), text sound effects, start game (from title screen).
- #56: SFX for: battle cursor move, Mute ally turn start/enemy turn start/victory/defeat menus. battle select ally/enemy, target for move/attack/assist, confirm end action, battle enemy turn start, battle ally turn start, level up.
- Animation sound effects for: walking, torch crackle, use weapon skill, use spell, use assist, all skills (can re-use liberally).

- Final boss theme! For fun.

## Art and animation

- kath-down, better camp clutter/beds, stone markers
- Elaine-idle, Elaine-walk, Elaine-getup
- Better wolf, alpha wolf sprites

- #51: Abelon-combat-entry-exit, Abelon-combat-idle, Abelon-combat-run (try same feet as walk but bump animation speed?), Kath-combat-entry-exit, Kath-combat-idle, Kath-combat-run, Elaine-combat-entry-exit, Elaine-combat-idle, Elaine-combat-run. Wolf-idle (this doubles as Wolf-combat-idle), Wolf-walk (this doubles as Wolf-combat-run), alpha-wolf-idle, alpha-wolf-walk.

- #52: Skill animations for (31): Clutches, Contempt, Trust, Inspire, Confidence, Flank, Punish, Judgement, Shove, Javelin, Hold the Line, Thrust, Sweep, Stun, Forbearance, Enrage, Caution, Healing Mist, Invigorate, Haste, Observe, Precise Shot, Terrain Survey, Hunting Shot, Lay Traps, Ignea Arrowheads, Wind Blast, Cover Fire, Farsight, Volley

- #53:
- Abelon-use-weapon, Abelon-use-spell, Abelon-use-assist, Abelon-use-util, Abelon-hurt (single frame, re-use for displacement), Abelon-death
- Kath-use-weapon, Kath-use-spell, Kath-use-assist, Kath-use-util, Kath-hurt, Kath-death
- Elaine-use-weapon, Elaine-use-spell, Elaine-use-assist, Elaine-use-util, Elaine-hurt, Elaine-death
- Wolf-use-weapon, Wolf-hurt, Wolf-death.

- Pretty title screen: Background art, fancy title, moving sprites, sfx, etc

- #47: Better portraits