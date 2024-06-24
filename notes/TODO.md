# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of the first quarter of the game. Commit often!

## Scene / Battle work

- Stats after golem battle v1 (escaped turn 8, 2 turns bexp saved, pre-weapon xp nerf):
    - Abelon: Lv.11, 52/240
    - Kath: Lv.10, 11/200
    - Elaine: Lv.7, 23/100
    - Shanti: Lv.8, 128/130
    - Ignea: collected all shards, Shanti/Kath/Abelon are down 2 but 2 shards in reserve.

- Abelon is pulling away from the pack in exp because he does so much damage. Lower the exp ratio from dealing damage a little bit.
- Inspire should grant only 0.5 affinity. It is absurdly strong with Trust.
- Add another ignea shard by the one accessible after the lester fight.
- Shanti present ignea scene.
- Allies move too quickly after attacking; if they are moving through a dead unit, the enemy does not have time to die and despawn before the ally runs into them
- Agility effects and assists seem to apply twice: once for the first move, once for the second move. Including from the same assist. This doesn't really make sense. Come up with how it should work.
- Given the enemy's next skill and their movement points, when hovering them display the union of their potential attack locations, except when they intersect their own movement squares.
- Golem battle: When the reinforcements arrive, add a second golem at the finish to really up the pressure. There's an unused open tile to put it in.
- Golem battle: Move Shanti's start tile down by one? Try it out. If you do, also move the satchel the same amount.
- Golem battle: Move Shanti's satchel 2 tiles closer to the escape, but have the reinforcements spawn one turn earlier. Keeps the momentum and makes the battle still challenging if not aiming for the side objective.
- Victory scene recovers 10 of Shanti's ignea if the pack was acquired.
- 1-4 transition scene and prevent going north, evening. Allies TP to monastery appraoch with same talk dialogue. Logs also move at this point.
- Place stone marker sprites, and golem getups

- Lester battle
    - Wolves + golems
    - Lester unavailable (at least at first).
- Implement win condition: Survive N turns (or just make it a rout map?)
- Implement side objective: Heal Lester
- Balance and polish

- Final battle
    - Battle opens with an absolute ton of wolves, arriving in waves. The terrors don't show up until right before its escape time
    - “waves” of enemies with one or two turns of downtime, to reward slow-paced, setup playstyles
    - Shanti is unavailable until she disables the ward, at which point the terrors appear and the escape objective opens up.
- Final scene transition and return to title screen
- Balance and polish

- Points of interest and items to pick up in monastery approach
- Re-script and choreograph dealing with elaine, all 1-3, 1-4 scenes. Wander behavior after scene ends.

## Engine work

- Currently, input stalls are imperfect because they only clear keyboard inputs at the beginning of the frame, but the keyboard state may be updated asynchronously in the middle of a frame. Should be a guard.

- Fix stuttering/flickering when walking around
    - Idea: measure the distance the camera moves on each frame, and as a function of time passed. Should be very consistent! If it is consistent, maybe things just arent always rendering in the same place?
    - May be an issue with push.lua? Or am I not drawing to a canvas.
- Implement performance improvements: https://www.dragonflydb.io/faq/love2d-performance-optimization

## Script work

- Start making use of everyone’s impressions!

- Tutorialize usage (use that on the blockage) and presentation (give it to me) somewhere in alpha.

- Two presentable items in 1-3 that have an eventual positive use outside tutorial. One use in the right spot, one present to the right person. Unlock new skill, big ignea dump. Example, key for a door.

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
        - While she looks for tracks, chat with Shanti and Kath.
    - Talk options after Elaine confusion
    - POI4 (revealed by logs, no allies show up)
    - Crossroads re-group 2
    - Talk options after re-group 2
    - Lester pre-battle
        - Lester is in fact under attack, but he did find one of the wards. He was attacked after locating it. Just like Shanti. Hmm. Save him in a battle; Lester himself is not available as a unit, as he is incapacitated, but many of the golems are injured as well. He's clearly capable. This time some wolves show up as well and go straight for Lester. Defend him!
    - Lester battle callouts
    - Lester post-battle
        - After the battle, looks like reinforcements are exhausted. Kath heals Lester while party discusses plans. Start limping over to the second ward so Shanti can begin to disable it. Abelon remains behind.
    - Talk options after lester battle
    - Terror pre-battle
        - At the ward, the monastery entrance is now visible, Shanti works to disable.
        - Funny moment after lester wakes up where elaine says something and lester turns and stares at her and says, “Kath, who’s this kid?”
        - After healing lester, (in the clearing before the monastery) he claims the log blockage wasn’t there. Prompts a terrible realization: a terror.
    - Terror battle callouts
        - Amount of wolves is abnormal. Something is forcing them into the party. The terror!
    - Terror post-battle
        - Escape underground into the monastery just as a second Terror arrives because Shanti disables the ward, and the underground entrance won't fit a terror. Through the large Sanctum entrance the party would be chased.
    - Demo conclusion scene
        - Abelon is confused. Reflects on all that happened, addressed the player directly but still as ???. Saving Elaine affected him. He is mad about it, wouldn't have done that. But, he concedes... she is useful. Still angry, fighting for control, doesn't feel confident to take it.

## Audio

- New animation sfx:
    - Combat entry for each unit
    - Combat exit for each unit
    - Skill usage animations for each unit

- All skill animation sfx

- Final battle theme

- Monastery approach/entrance theme

## Art / Animation

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

- Better golem sprite, better terror sprite
- Monastery approach log piles, boulders and ground features (ignaeic runes, logs, markers, wolf den, scuffed ground, etc)

- Better portraits

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