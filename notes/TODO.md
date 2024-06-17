# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Scene / Battle / Sprite work

- Golem battle:
    - Guard other in-battle scenes with the assertion that the sprite is in the battle. So if the sprite has escaped, a scene with them won't play (or will be something a little different). Turn limit defeat scene.
    - Victory scene fades and teleports the team, despawns any remaining golems, sets a trigger to the north preventing you from going back, sets a trigger for the walk south to transition to 1-4, team says a few words.
    - 1-4 transition scene, evening
    - Should not be able to stack caution. Have it give a special. Any ability with more than a 2 turn effect should have this property (ignea arrowheads, bond)
    - Stone markers, getups
    - Better golem sprite
    - Test and tweak

- Implement placeholder animations (use a word) to test timing on playing actions under a variety of circumstances
    - No counter enemy phase
    - Single counter enemy phase
    - Death from enemy
    - Kill on enemy
    - Multi counter
    - Death by counter
    - No damage taken (no hurt) from counter
    - full attack with assist, deal damage
    - full attack with assist, deal no damage
    - enemy phase, attack deals no damage

- Lester battle scenes, Wolves + golems
- Lester portrait
- Lester attributes and skills
- Implement win condition: Survive N turns
- Implement side objective: Heal Lester
- Balance and polish

- Final battle scenes
    - Battle opens with an absolute ton of wolves, arriving in waves. The terrors don't show up until right before its escape time.
- Forest terror sprite
- Forest terror skills
- Implement win condition: Escape
- Final scene transition and return to title screen
- Balance and polish
- Final terror sprite

- Monastery approach log piles, boulders and ground features (ignaeic runes, logs, markers, wolf den, scuffed ground, etc)
- Goodies, items, lore to pick up in monastery approach
- Dealing with Elaine, wander behavior after scene ends
- All 1-3, 1-4 scenes

## Audio

- New animation sfx:
    - Combat entry for each unit
    - Combat exit for each unit
    - Skill usage animations for each unit

- All skill animation sfx

- Final battle theme

- Monastery approach/entrance theme

## Art / Animation

- Better portraits

- Skill animations:
    - Clutches
    - Contempt
    - Trust
    - Inspire
    - Confidence
    - Flank
    - Punish
    - Judgement
    - Shove
    - Javelin
    - Hold the Line
    - Thrust
    - Sweep
    - Stun
    - Forbearance
    - Enrage
    - Caution
    - Healing Mist
    - Invigorate
    - Haste
    - Observe
    - Precise Shot
    - Terrain Survey
    - Hunting Shot
    - Lay Traps
    - Ignea Arrowheads
    - Wind Blast
    - Cover Fire
    - Farsight
    - Volley
    - All Shanti skills
    - All Lester skills
    - Bite
    - Golem slam
    - Golem spell
    - Terror howl
    - Terror claws
    - Terror AoE

- Basic character animations:
    - Elaine-idle
    - Elaine-walk
    - Elaine-getup
    - Shanti-idle
    - Shanti-walk
    - Lester-idle
    - Lester-walk
    - Lester-getup
    - Golem-getup

- Basic combat animations:
    - Abelon-combat-entry-exit
    - Abelon-combat-idle
    - Abelon-combat-run (try same feet as walk but bump animation speed?)
    - Kath-combat-entry-exit
    - Kath-combat-idle
    - Kath-combat-run
    - Elaine-combat-entry-exit
    - Elaine-combat-idle
    - Elaine-combat-run
    - Shanti-combat-entry-exit
    - Shanti-combat-idle
    - Shanti-combat-run
    - Lester-combat-entry-exit
    - Lester-combat-idle
    - Lester-combat-run
    - Wolf-idle (this doubles as Wolf-combat-idle)
    - Wolf-walk (this doubles as Wolf-combat-run)
    - Alpha-wolf-idle
    - Alpha-wolf-walk
    - Golem-idle (see above)
    - Golem-walk (see above)
    - Terror-idle (see above)
    - Terror-walk (see above)

- Skill usage animations:
    - Abelon-use-weapon
    - Abelon-use-spell
    - Abelon-use-assist
    - Abelon-use-util
    - Abelon-hurt (single frame, re-use for displacement)
    - Abelon-death
    - Kath-use-weapon
    - Kath-use-spell
    - Kath-use-assist
    - Kath-use-util
    - Kath-hurt (single frame, re-use for displacement)
    - Kath-death
    - Elaine-use-weapon
    - Elaine-use-spell
    - Elaine-use-assist
    - Elaine-use-util
    - Elaine-hurt (single frame, re-use for displacement)
    - Elaine-death (inverse of getup)
    - Shanti-use-weapon
    - Shanti-use-spell
    - Shanti-use-assist
    - Shanti-use-util
    - Shanti-hurt (single frame, re-use for displacement)
    - Shanti-death
    - Lester-use-weapon
    - Lester-use-spell
    - Lester-use-assist
    - Lester-use-util
    - Lester-hurt (single frame)
    - Lester-death (inverse of getup)
    - Wolf-use-weapon
    - Wolf-hurt (single frame, re-use for displacement)
    - Wolf-death
    - Golem-use-weapon
    - Golem-use-spell
    - Golem-hurt (single frame, re-use for displacement)
    - Golem-death
    - Terror-use-weapon
    - Terror-use-spell
    - Terror-use-util
    - Terror-hurt (single frame, re-use for displacement)
    - Terror-death