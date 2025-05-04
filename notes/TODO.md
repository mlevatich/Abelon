# TODO list

An ordered list of programming, writing, and artistic objectives to be completed before shipping a closed alpha test of the first quarter of the game. Commit often!

## Out-of-battle gameplay / scenes

- "Press 'R' to close tutorial" or something.
- Lester is down for a moment (mid getup) at the beginning of his introduction scene
- Lester should remain in the down animation even when attacked

- Add the cobblestone path in the monastery approach!

- New items/usage/presentation:
    - Journal:
        - Usage message updates once in 1-4.
    - Scroll
        - Present to Shanti for lore
    - Unidentified metal
        - Basic description on use
        - Present to kath (tutorial)
    - Brass key
        - Basic description on use
        - Special use when near the casket sprite (gain pristine whetstone)
    - Ornate dagger
        - Basic description on use
        - Present to Lester (gain skill point)
    - Spent ignea
        - Basic description on use
        - Present to Shanti (gain skill point)
    - Ritual slab
        - Basic description on use
        - Present to Shanti (lore and favor)
    - Pristine Whetstone
        - On use, option to gain +2 force
        - Unique present dialogue for each ally, give them +2 force (shanti just gives it back)
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
    - Elaine pester (Elaine guidance 1): What are we doing and how can I help?
        - Conversation happens in bursts, where the player can briefly move forward before Elaine bothers them again. Treating Elaine warmly will cause her to relax. Treating her coldly will make her withdraw and not offer any tracking help.
        - Kath explained about the monastery and everything. But when she asked him how she could contribute, he told her to go talk to Abelon. Was this Kath just trying to break the ice between them? Or deferring to Abelon's leadership? Player can comment.
        - Player can shut her down (just don't get in our way), or offer something ("not unless you can guide us to the monastery"). Elaine concedes she doesn't know where the monastery is. But later, she asks, "Don't you need to find your other two knights first?".
        - "Yes, regrettably", "Yes, and if you can't help, don't distract me", "Just one knight, Lester - Shanti is a researcher".
        - Elaine says she can at least tell someone came this way. Can respond "Obviously." or "How do you know that?". If you say the former, we're done (or if you were mean to her in the previous three interactions she won't even speak this part). If the latter, she explains her talents and offers to guide you in the right direction. First points north in the clearing. Can praise her for this, at which point she'll relax.
        - Either way, if she explains her talents you gain a couple more scenes where she helps navigate. (She is really just tailing shanti, since lester takes better care to conceal his footsteps. So she doesn’t see evidence that the log pile was crossed. But she may bring up that she is only seeing evidence of one person, which Kath can answer for. This comes up later).
    - Talk options after pester
        - If Elaine is helping navigate, she reminds you of the direction the tracks go, but says that of course you could explore other paths if there might be clues about the monastery. She is more confident, in her element.
        - If Elaine is not helping navigate, she is nervous, asks if you need something. Can tell her you don't trust her and not to try anything (upsets Elaine but points for Abelon), or remind her to stay safe (small points for Elaine), some lore detail about the valley.
    - Wolf den pre-battle
        - Kath is here. Fighting the wolf den is a challenge forced on them, but it's not all bad. If they pull it off, it's strategic - wolves in the area should disperse to a new home if their den is destroyed.
    - Wolf den battle callouts
        - Kath identifies the alpha wolves. Be careful!
    - Wolf den battle victory
        - Destroy the den with fire. Stay a moment to make sure it burns, Abelon can go on ahead.
    - Talk options after wolf den
        - Elaine and Kath have a chat about why there aren't more knights. Naturally this is one of the first things she's curious about as her understanding is that a Knight Captain's job is to command the knights, and she worries about what will happen to Ebonach while they're away. This prompts two conversation threads:
            - One where Kath explains that monsters attack large groups of people and they're less likely to run into trouble with a small, skilled party. But Elaine will have to pull her weight. This gets Elaine thinking about the fact that Ebonach's very existence is drawing hordes of monsters to it, making life difficult.
            - Another where Kath and Abelon discuss Jericho, the old retired captain who preceded Stefan and took his place temporarily after his death until Kath succeeded him. Jericho is in charge back home for the duration of the expedition. His capabilities, and Abelon's relationship with him, are called into question.
    - POI (before wolf den, no allies show up)
    - Crossroads re-group (Elaine guidance 2)
        - Idle throwaway comment on the fallen trees. A storm?
        - Elaine points to where to go next, if guidance. Kath is impressed.
    - Talk options after crossroads
        - Same as after wolf den, but with one new optional thread added. Abelon can start this up with either Kath or Elaine.
            - They've gone a long way.
                - If Elaine is guiding, she says she thinks she's only tailing one person. Kath says Lester is good at concealing himself. And that they're probably still together. To split up would be irresponsible. Abelon can chime in sarcastically that Lester's never been known to act irresponsibly. Elaine thinks this is funny.
                - If Elaine is not guiding, Kath says they must have found something, or else they would've turned back. Cautious optimism? And hope that Lester didn't do something dumb. Abelon can counter that they might be in dire straits, or dead.
    - POI2 (after crossroads, no allies show up)
    - POI3 (after crossroads, no allies show up)
    - Elaine guidance 3 (in the southeast)
        - Allies re-group here, but no changes to talk options. Short conversation if Elaine is not guiding, otherwise she points the way again.
    - Shanti ward
        - Who is this girl? Introducing Elaine and Shanti. Acts as an introduction to Shanti's character as well.
        - Shanti explains she found a weird magical ward that takes time to analyze and disable. It hides the monastery from view and makes it impossible to enter. Someone or something didn't want the monastery found. Lester was bored, she said he could look for other wards, since there didn't seem to be monsters about. She finishes with the ward, and then the party arrives. But the golems immediately appear, summoned by the Caretaker as a reaction to the ward being disabled.
    - Golem pre-battle (continuation of shanti ward scene)
    - Golem battle callouts (inc Kath warning about high defence enemies)
    - Golem battle victory
        - What just happened? Are all of the stone monoliths golems? If so, we're in trouble.
        - Worried that stone monsters are chasing Lester too.
    - Post-golem battle prevent north
    - Post-golem talk options
        - In 1-3, elaine asks shanti about ignea, prompted by shanti’s ability to decipher the magic ward. Shanti explains to elaine the basics with metaphors, drawing on elaine’s academy exercises (which shanti invented). The “blank” state of meditation when you have no thoughts feels like an absence, but it’s actually a presence of magic, a sixth sense. But like opening your eyes in a pitch black room, you aren’t made aware of the sense without something to perceive, which is the magic inside of ignea. If you can stay in that focused state you can manifest the stone’s power into spells. Elaine and shanti have multiple such conversations, perhaps more if elaine observes shanti and invests in focus and her apprentice tree.
        - Kath is worried about Lester. Some discussion of this guy, why is he so irresponsible, Kath trained him, they're friends, etc.
    - 1-4 transition scene (move allies to monastery approach with the same talk options as before)
        - Abelon is worried about deception from elaine and the terrors, wants to warn everyone somehow.

- 1-4 script
    - Journal use text changes
    - Medallion gets a use
    - Terror just out of sight
    - Elaine confusion at moved logs
        - While she looks for tracks, chat with Shanti and Kath. Shanti says, you don't think she tailed us here? Kath is confident, says, look, why dont I probe her a bit more.
    - Talk options after Elaine confusion
        - Kath asks Elaine about what district she's from. She's close to the north gate, explains how she was getting out to hunt. Why hunt? Well, their family doesn't get much food. Kath is confused, what do her parents do? They're dead. Her and her grandfather get food from the district's communal kitchen because there's no one of working age in her household.
        - Elaine reluctantly reveals that her parents were knights. Her grandfather claims Abelon is responsible for their deaths and that's why the knights can't be trusted to care about the citizenry. Prompts some soul-searching from Kath and Abelon.
        - Follow-up with Shanti about the ward. What does she think? About the monastery? About the ritual?
    - POI4 (revealed by logs, no allies show up)
    - Crossroads re-group 2
        - Elaine guidance 4 (before monastery entrance)
    - Talk options after re-group 2
        - Same as prior, but with one addition, TK.
    - Lester pre-battle
        - Lester is in fact under attack, but he did find one of the wards. He was attacked after locating it. Just like Shanti. Hmm. Save him in a battle; Lester himself is not available as a unit, as he is incapacitated, but many of the golems are injured as well. He's clearly capable. This time some wolves show up as well and go straight for Lester. Defend him!
    - Lester battle callouts
        - Amount of wolves is abnormal. Something is forcing them into the party. The terror!
    - Lester post-battle
        - After the battle, looks like reinforcements are exhausted. Kath heals Lester while party discusses plans. Start limping over to the second ward so Shanti can begin to disable it. Abelon remains behind.
    - Talk options after lester battle
        - Elaine is curious about what it takes to be a knight exactly. How are they trained. Would her talents as an archer be useful?
            - Kath gives a little overview of battle tactics and why there aren't many archers among the knights anymore. The southwall has been an ongoing project for decades, as just protecting the farmers has become a full time job due to the unviability of hunting and fishing requiring more fields. To additionally defend a wall under construction by tradesmen is a tall order. The wall is makeshift in many places and monsters get through.
            - She trained from her grandfather, so his past is called into question - only Abelon knows that he was previously a soldier, as he didn't tell Elaine this.
        - Lester and Shanti are having a chat. A little info on King Sinclair.
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

- Start making use of everyone's impressions!

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