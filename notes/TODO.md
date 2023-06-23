# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of a small portion of the game.

Each bullet point should be at least one commit.

Bullets that reference a github issue should close the issue when committed.

# Checklist

## Immediate

- No assists allowed, no battle prep in 1-1
- Elaine-downed, 1-1 Elaine interaction
- #48: Tutorial information should appear on the right side of the screen, in the middle. Tutorial paragraphs are given in the script. They are also accessible from the settings menu in a "tutorial" menu.
- Adjust road, add campsite, stone reliefs
- Lester-sleep, Shanti-sleep, Kath-sleep
- Abelon-combat-entry-exit, Abelon-combat-idle
- Support GOTOs in scenes for sane script-writing.
- Music fade is quieter than it should be.
- Implement 1-1 script and 1-2 opening scene and battle.
- #69: Elaine sprite, Elaine portrait, Elaine-idle, Elaine-walk, Elaine-getup.
- In battle, HUD should show how much damage/healing you are about to do and what statuses you will apply to each enemy/ally, when an attack is selected. When an assist is selected, HUD should show the effect that will apply to the assisted tiles.
- Finish script 1-2 and implement it up to 1-3 transition.

## Near

- #33: Chapter -> Context refactor. Simplify lesser used features like tileset variation, sprite versions, chapterfile, base interactions, etc. Prepare for inclusion of title screen.
- Add in skills from notes, support displacement effects, test with a buffed Elaine and more wolves.
- Ignea restore on battle finish depending on difficulty (50%/25%/0%)
- #51: Support animation on combat entry (bridges idle -> combat), and on for  combat exit (this can just be the combat entry animation played in reverse). Abelon-combat-run (try same feet as walk but bump animation speed?), Kath-combat-entry-exit, Kath-combat-idle, Kath-combat-run, Elaine-combat-entry-exit, Elaine-combat-idle, Elaine-combat-run.
- Two mostly identical wolf sprites, Wolf-idle (this doubles as Wolf-combat-idle), Wolf-walk (this doubles as Wolf-combat-run).
- #52: Every skill has an associated single-fire animation, with render position determined by the cursor location of the cast. This has nothing to do with the sprite casting the skill. For some skills, the animation should play at every affected tile, for others, the animation should play centered on the cursor and affected by direction. This should be provided as an option. Make skill animations for all basic skills.
- #53: Each sprite that battles has single-fire animations: one for weapon skills, one for spells, one for assists, one for utilities, one for being injured, and one for  dying. Abelon-weapon, Abelon-spell, Abelon-assist, Abelon-util, Abelon-hurt, Abelon-death, Kath-weapon, Kath-spell, Kath-assist, Kath-util, Kath-hurt, Kath-death, Elaine-weapon, Elaine-spell, Elaine-assist, Elaine-util, Elaine-hurt, Elaine-death, Wolf-weapon, Wolf-hurt, Wolf-death.
- #4: SFX for:, menu select (not too different from current), text sound effects, start game (from title screen).
- #56: SFX for: battle cursor move, Mute ally turn start, enemy turn start, victory, defeat menus, battle select ally/enemy, target for move/attack/assist, confirm end action, battle enemy turn start, battle ally turn start, level up, use weapon skill, use spell, use assist, use utility, skills (can re-use liberally).
- #16: Title screen v0 (continue (if save file detected), new game -> choose difficulty). Title screen should have controls in one corner. Return player to title screen after conclusion of 1-2.
- #63: Title screen music, use the voice memo on my phone: Time Slows. Tentative track name: The Lonely Knight. Experiment with slow crescendos! And quiet bass.
- #64: Defeat theme: Despair - Short theme that plays during the battle loss scene.
- #67: Better forest theme - more tense investigation, less funeral march
- #65: Enemy approaches theme - for rising action before a fight!

## Distant

- Write 1-3, 1-4 of narrative.md
- Write script 1-3
- #70: Lester sprite, Lester portrait, Lester-idle, Lester-walk, Lester-combat-entry-exit, Lester-combat-idle, Lester-combat-run, Lester-weapon, Lester-spell, Lester-assist, Lester-hurt, Lester-death, Stone sprite data and graphics, Shanti sprite, Shanti portrait, Shanti-idle, Shanti-walk, Shanti-combat-entry-exit, Shanti-combat, Shanti-combat-run, Shanti-weapon, Shanti-spell, Shanti-assist, Shanti-hurt, Shanti-death
- Improve AI algorithm - use other plans! In particular, enemies shouldn't interfere with each other. If one enemy has only a single path to attack their target, the acting enemy shouldn't get in the way of that path unless it needs to in order to attack its own target. To minimize interference in general, the strongest enemies should take their turns first, and the enemies who start farther away from the allies should also be prioritized.
- Write 1-4 script
- #71: Implement 1-3. Includes additional map to the north of north forest, the monastery approach.

## Finally

- #72: Implement 1-4
- 1-4 battle theme
- #68: Last pass over script for consistency
- #66: Second battle theme - more slow and tense, for 1-1 and maybe others
- Animation sound effects: Explore "animation sound effects": looping sound effects associated with an animation and based on proximity to the sprite, like a crackling torch, or a person's footsteps. Not an easy task!!
- #9: Lighting engine. Flickering, smoothing, obstacle detection (sprite parameter deciding whether it blocks light may be needed. e.g. abelon blocks light but a log doesn't), proper color computation. Look up lua/love shaders. Alternate, darken with patterns of black pixels over tiles?
- "Splash" animations: When sprites take damage, a damage splash should be rendered. When they heal, a heal splash should be rendered. This should happen as the damage is dealt. The idea of a "splash" animation could be re-used for skill animations. When sprites gain exp, render exp splash. This should happen on a delay, so the exp splash renders after the relevant action has just finished playing out.
- #47: Better portraits
- #73: Make executable
- #74: Pre-alpha closed release