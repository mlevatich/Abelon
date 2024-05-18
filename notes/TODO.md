# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Scene / map work

- Choreograph dealing with Elaine
- Add stone markers
- Insert debug statements that print when impressions change, to make sure its all correct. Try every dialogue path (something is broken at the moment).

## Engine work / bugfixing

- Support animation on combat entry (bridges idle -> combat), and on combat exit (this can just be the combat entry animation played in reverse).
- Change ignea shards to all spawn in 1-1, and be distinct sprites that point to the same re-usable script (re-purpose the items script for all chapter-independent scenes).
- Explore baked-in shadows under human/creature sprites to give the appearance of depth.
- Profiling, fix battle slowness

## SFX

- #4: SFX for: start game (from title screen), level up, ally phase start, enemy phase start.
- Animation sound effects for: torch crackle, combat entry, use weapon skill, use spell, use assist, all skills (can re-use liberally).
- Proximity-based sfx.
- Better text, menu hover, walk, menu select sound effects.

## Art and animation

- Stone marker sprite
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

- #47: Better portraits