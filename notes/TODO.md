# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Scene work

- Choreograph/trigger north forest transition
- Choreograph ally phase 3 if Elaine not carried
- Insert debug statements that print when impressions change, to make sure its all correct
- Choreograph wolf den battle if elaine is gone
- kath-down, better camp clutter/beds, stone markers
- Campfire flicker
- Change ignea shards to all spawn in 1-1, and be distinct sprites that point to the same re-usable script (re-purpose the items script for all chapter-independent scenes).
- Choreograph dealing with Elaine

## Engine work

- Support animation sound effects: looping sound effects associated with an animation and based on proximity to the sprite, like a crackling torch, or a person's footsteps. A particular frame of an animation should have an optional associated SFX and volume.
- Profiling, fix battle slowness
- Explore baked-in shadows under human/creature sprites to give the appearance of depth.
- #73: Make executable cross-platform app

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

- Elaine-idle, Elaine-walk, Elaine-getup
- Better wolf, alpha wolf sprites

- #51: Support animation on combat entry (bridges idle -> combat), and on combat exit (this can just be the combat entry animation played in reverse). Abelon-combat-entry-exit, Abelon-combat-idle, Abelon-combat-run (try same feet as walk but bump animation speed?), Kath-combat-entry-exit, Kath-combat-idle, Kath-combat-run, Elaine-combat-entry-exit, Elaine-combat-idle, Elaine-combat-run. Wolf-idle (this doubles as Wolf-combat-idle), Wolf-walk (this doubles as Wolf-combat-run), alpha-wolf-idle, alpha-wolf-walk.

- #52: Skill animations for (31): Clutches, Contempt, Trust, Inspire, Confidence, Flank, Punish, Judgement, Shove, Javelin, Hold the Line, Thrust, Sweep, Stun, Forbearance, Enrage, Caution, Healing Mist, Invigorate, Haste, Observe, Precise Shot, Terrain Survey, Hunting Shot, Lay Traps, Ignea Arrowheads, Wind Blast, Cover Fire, Farsight, Volley

- #53: Each sprite that battles has single-fire animations: one for weapon skills, one for spells, one for assists, one for utility skills, one for being injured (still frame), and one for dying. Displacement is the same as the 'injured' animation. Abelon-weapon, Abelon-spell, Abelon-assist, Abelon-util, Abelon-hurt, Abelon-death, Kath-weapon, Kath-spell, Kath-assist, Kath-util, Kath-hurt, Kath-death, Elaine-weapon, Elaine-spell, Elaine-assist, Elaine-util, Elaine-hurt, Elaine-death, Wolf-weapon, Wolf-hurt, Wolf-death.

- Pretty title screen: Background art, fancy title, moving sprites, sfx, etc

- #47: Better portraits