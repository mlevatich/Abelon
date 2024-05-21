# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Imminent

- Choreograph dealing with Elaine and all subscenes
    - Something is broken at the moment - Elaine seems to always join
    - Insert debug statements that print when impressions change, to make sure its all correct. Try every dialogue path. Make sure impressions change at the moment the option is selected.

- New/revamped sfx:
    - Start game (from title screen)
    - Torch crackle (animation sfx)

- Sprites:
    - Stone marker by north forest exit.
    - kath-down
    - Better camp clutter/beds
    - Better wolf
    - Better alpha wolf

- Profiling and refactoring Battle.lua to fix battle lag

## Audio

- New animation sfx:
    - Combat entry for each unit
    - Combat exit for each unit
    - Skill usage animations for each unit

- All skill animations

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

- Basic character animations:
    - Elaine-idle
    - Elaine-walk
    - Elaine-getup

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
    - Wolf-idle (this doubles as Wolf-combat-idle)
    - Wolf-walk (this doubles as Wolf-combat-run)
    - Alpha-wolf-idle
    - Alpha-wolf-walk

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
    - Kath-hurt (single frame)
    - Kath-death
    - Elaine-use-weapon
    - Elaine-use-spell
    - Elaine-use-assist
    - Elaine-use-util
    - Elaine-hurt (single frame)
    - Elaine-death (inverse of getup)
    - Wolf-use-weapon
    - Wolf-hurt (single frame)
    - Wolf-death