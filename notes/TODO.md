# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of the first quarter of the game. Commit often!

## Fixes

- Inversion -> 1 ignea
- Trust -> Confidence feels too strong. Maybe confidence gives just 0.8 Force? Or it costs 1 ignea? Or both.
- An extra golem on each side at the end of the final battle
- Another alpha wolf or two in lester battle.
- Poison coat can last just one turn
- Lester is down for a moment (mid getup) at the beginning of his introduction scene
- Shove shouldn't work when Lester is downed
- Lester should remain in the down animation even when attacked
- Add the cobblestone path in the monastery approach!
- If kath has left the battlefield, forbearance should have no effect
- "we will remain oblivious" -> "they will remain oblivious"

## Battle gameplay

- Test a full playthrough with different builds, and on different difficulties
    - Tested: Abelon Force, Elaine Focus, Kath Reaction

- Results of first test:
    - "Smart" play didn't really involve using my new fancy skills too much. Pursuit, punish, judgement, inversion went mostly untouched. Also other fancy skills, like bleed vitality. Using situational abilities to gain an advantage, rather than the basic general purpose stuff, should feel rewarding!
    - The game is a bit too easy still on Master.
    - Conclusion: Slightly nerf some of the basic skills and lower some ignea costs of fancy skills to make fancy strategy more appealing/necessary. Particularly fancy skills that aren't just massive damage abilities.

## Out-of-battle gameplay / scenes

- New items/usage/presentation:
    - Journal:
        - Usage message updates once in 1-4.
    - Scroll:
        - Present to Shanti for lore
    - Unidentified metal:
        - Basic description on use
        - Present to kath (tutorial)
    - Brass key
        - Basic description on use
        - Special use when near the casket sprite (gain pristine whetstone)
    - Ornate dagger
        - Basic description on use
        - Present to Lester (gain skill point)
    - Old buckler
        - Basic description on use
        - Present to Kath (gain skill point)
    - Ritual slab
        - Basic description on use
        - Present to Shanti (lore and favor)
    - Pristine Whetstone
        - On use, option to gain +2 force
        - Unique present dialogue for each ally, give them +2 force
    - Spade
        - Didn't find anything on use normally
        - Special use in tutorial to dig up ignea, or to dig up casket in suspicious ground, or to dig up old buckler
    - Compass
        - Tells what direction you're facing on use
        - Present to Kath to get information about world orientation
    - Waterskin
        - Drink some water on use. After 5 drinks, it runs out, makes a little joke.
        - On present to Elaine, she says Kath gave her one

- New sprites (placeholder art):
    - Casket
    - Buried ignea
    - Tree pile
    - Giant boulder
    - Scuffed ground
    - Ignaeic site
    - Wolf den
    - Metal scraps
    - Monastery entrance

- Place tree piles / giant boulders / scuffed ground around monastery approach and move them in the entry to 1-4

- Add ignaeic site, wolf den, monastery approach

- Place buried ignea, ornate dagger, old buckler, ritual slab

- Populate monastery approach with stone markers, metal scraps, logs.

- Tutorial scene: Use spade to dig up ignea, key, pauldron along the main path while allies block the way. Then present pauldron to kath (initially unidentified metal, present it and kath says its a pauldron). Get commentary on an old battle that mustve been fought here. Happens in the first clearing of 1-3 when Kath catches up.

- Usage and presentation scenes for the above

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

- Triggers and placeholder scenes for the items in the script below

- Choreograph entire demo based on complete script
    - Including a pass over already-choreographed scenes
    - Decide wander or idle behavior after scenes end.

## Script

- 1-3 script
    - Elaine pester (Elaine guidance 1)
        - On the left side, Elaine has questions, Abelon can answer or tell her to be quiet. But she just wants to help. Kath is following behind some distance, watching their back. If you entertain elaine, she offers to help track. If you accept, she’ll point the way. And gain a couple more scenes where she helps navigate. (She is really just tailing shanti, since lester takes better care to conceal his footsteps. So she doesn’t see evidence that the log pile was crossed. But she may bring up that she is only seeing evidence of one person, which Kath can answer for. This comes up later).
    - Talk options after pester
    - Wolf den pre-battle
    - Wolf den battle callouts
    - Wolf den battle victory
    - Talk options after wolf den
    - POI (before wolf den, no allies show up)
    - Crossroads re-group (Elaine guidance 2)
        - Idle throwaway comment on the fallen trees.
    - Talk options after crossroads
    - POI2 (after crossroads, no allies show up)
    - POI3 (after crossroads, no allies show up)
    - Elaine guidance 3 (in the southeast)
    - Elaine guidance 4 (before monastery entrance)
    - Shanti ward
        - Shanti explains she found a weird magical ward that takes time to analyze and disable. It hides the monastery from view and makes it impossible to enter. Someone or something didn't want the monastery found. Lester was bored, she said he could look for other wards, since there didn't seem to be monsters about. She finishes with the ward, and then the party arrives. But the golems immediately appear, summoned by the Caretaker as a reaction to the ward being disabled.
    - Golem pre-battle (continuation of shanti ward scene)
    - Golem battle callouts (inc Kath warning about high defence enemies)
    - Golem battle victory
        - What just happened?
        - Worried that stone monsters are chasing Lester too.
    - Post-golem battle prevent north
    - Post-golem talk options
        - In 1-3, elaine asks shanti about ignea, prompted by shanti’s ability to decipher the magic ward. Shanti explains to elaine the basics with metaphors, drawing on elaine’s academy exercises (which shanti invented). The “blank” state of meditation when you have no thoughts feels like an absence, but it’s actually a presence of magic, a sixth sense. But like opening your eyes in a pitch black room, you aren’t made aware of the sense without something to perceive, which is the magic inside of ignea. If you can stay in that focused state you can manifest the stone’s power into spells. Elaine and shanti have multiple such conversations, perhaps more if elaine observes shanti and invests in focus and her apprentice tree.
    - 1-4 transition scene (move allies to monastery approach with the same talk options as before)
        - Abelon is worried about deception from elaine and the terrors, wants to warn everyone somehow.

- 1-4 script
    - Journal use text changes
    - Medallion gets a use
    - Terror just out of sight
    - Elaine confusion at moved logs
        - While she looks for tracks, chat with Shanti and Kath. Shanti says, you don't think she tailed us here?
    - Talk options after Elaine confusion
    - POI4 (revealed by logs, no allies show up)
    - Crossroads re-group 2
    - Talk options after re-group 2
    - Lester pre-battle
        - Lester is in fact under attack, but he did find one of the wards. He was attacked after locating it. Just like Shanti. Hmm. Save him in a battle; Lester himself is not available as a unit, as he is incapacitated, but many of the golems are injured as well. He's clearly capable. This time some wolves show up as well and go straight for Lester. Defend him!
    - Lester battle callouts
        - Amount of wolves is abnormal. Something is forcing them into the party. The terror!
    - Lester post-battle
        - After the battle, looks like reinforcements are exhausted. Kath heals Lester while party discusses plans. Start limping over to the second ward so Shanti can begin to disable it. Abelon remains behind.
    - Talk options after lester battle
    - Terror pre-battle
        - At the ward, the monastery entrance is now visible, Shanti works to disable.
        - Funny moment after lester wakes up where elaine says something and lester turns and stares at her and says, “Kath, who’s this kid?”
        - After healing lester, (in the clearing before the monastery) he claims the log blockage wasn’t there. Prompts a terrible realization: a terror.
    - Terror battle callouts
        - Fear, panic.
        - This is it! Use everything you have!
    - Terror post-battle
        - Escape underground into the monastery just as a second Terror arrives because Shanti disables the ward, and the underground entrance won't fit a terror. Through the large Sanctum entrance the party would be chased.
    - Demo conclusion scene
        - Abelon is confused. Reflects on all that happened, addressed the player directly but still as ???. Saving Elaine affected him. He is mad about it, wouldn't have done that. But, he concedes... she is useful. Still angry, fighting for control, doesn't feel confident to take it.

- Start making use of everyone’s impressions!

## Audio

- Text sfx for Shanti
- Text sfx for Lester

- Final battle theme
- Monastery approach/entrance theme

- New animation sfx:
    - Combat entry for each unit
    - Combat exit for each unit
    - Skill usage animations for each unit

- All skill animation sfx

## Art and animation

- Redo placeholder sprites on spritesheet
- Redo placeholder portraits

- Skill animations

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