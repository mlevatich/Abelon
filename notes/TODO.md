# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Engine work

- Proximity-based sfx. Test with torch crackle

- Implement the combatReady and combatExit functions to fire the combat entry/exit animations respectively and switch to combat/idle as a done action. Test with abelon-combat-entry-exit.

- Explore quieting music during scenes or jingles (e.g. ally phase start, level up, dialogue)

- Explore baked-in shadows under human/creature sprites to give the appearance of depth. Use a stock 'shadow' sprite that sits between the sprite and the ground.

- Profiling and refactoring Battle.lua to fix battle lag

## Scene work

- Choreograph dealing with Elaine and all subscenes
    - Something is broken at the moment - Elaine seems to always join
    - Insert debug statements that print when impressions change, to make sure its all correct. Try every dialogue path. Make sure impressions change at the moment the option is selected.

## Audio

- Interface sound effects:
    - Start game (from title screen)
    - Level up
    - Ally phase start
    - Enemy phase start

- Rework sound effects:
    - Menu hover
    - Menu select
    - Footsteps
    - Dialogue

- Animation sound effects:
    - Torch crackle
    - Combat entry
    - Combat exit
    - All skill usage animations (re-use liberally)
    - All skill animations (re-use liberally)

## Art

- Better portraits

- Sprites:
    - Stone marker by north forest exit.
    - kath-down
    - Better camp clutter/beds
    - Better wolf
    - Better alpha wolf

## Animation

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

- Character animations:
    - Elaine-idle
    - Elaine-walk
    - Elaine-getup

- Combat animations:
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
    - Elaine-death
    - Wolf-use-weapon
    - Wolf-hurt (single frame)
    - Wolf-death