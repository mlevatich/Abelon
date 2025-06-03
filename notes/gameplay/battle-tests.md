# General notes

- Use 1-3-init for testing, as 1-1 and 1-2 are the same fights every time.
- For the demo I consider that EXP requirements for levelups are roughly half of what they would be in the main game (with a steeper curve so you can still get a couple of levelups early). The level of power in the final battle of the demo is roughly what I would expect when the player is 3/4ths through the game.
    - This means the leveling curve in the main game will slow down a lot. To keep progression from feeling too sluggish, I should probably start every unit a level down from what they're at in the demo. So Abelon, Kath and Shanti all lose a skill. Think about which this should be. Shanti -> Lasso, Kath -> Riposte, Abelon -> Confidence.

# Golem battle (557be638)

- Test 1 (Get satchel, Abelon Endurance, Elaine Affinity, Kath Reaction):
    - XP: Shanti 86, Kath 77, Abelon 166, Elaine 98 (Total 427)
    - Ignea: 12 used (10 gained)
    - Difficulty: Very challenging
- Test 2 (No satchel, Abelon Endurance, Elaine Affinity, Kath Reaction):
    - XP: Shanti 125, Kath 80, Abelon 152, Elaine 103 (Total 460)
    - Ignea: 11 used (0 gained)
    - Difficulty: Moderate
- Test 3 (Get satchel, Abelon Force, Elaine Focus, Kath Affinity):
    - XP: Shanti 65, Kath 110, Abelon 154, Elaine 87 (Total 416)
    - Ignea: 27 used (10 gained) (worth noting I fucked up at the end and wasted a lot of ignea. Build is fine.)
    - Difficulty: Very challenging
    - Inversion with an Abelon force build has amazing potential
- Test 4 (Get satchel, Abelon Affinity, Elaine Reaction, Kath Force):
    - XP: Shanti 132, Kath 139, Abelon 142, Elaine 149 (Total 562)
    - Ignea: 13 used (10 gained)
    - Difficulty: Challenging
    - Notes: Death blessing and Lay Traps both very effective here

# Lester battle (1fb58476)

- Test 1 (Heal Lester, Abelon Affinity, Elaine Force, Kath Reaction):
    - XP: Abelon 197, Shanti 220, Kath 248, Elaine 256, Lester 100 (Total: 1021)
    - Ignea: 17 used
    - Difficulty: Moderate
    - Notes: High force Elaine does absurd damage. Volley and Piercing Shot plenty effective here. Farsight effective with Riposte, although maybe Farsight should be free? Riposte Kath does work here. Bleed Vitality probably needs a buff, it isn't that useful.

# Final battle (1fb58476)

- Test 1 (Abelon Affinity, Elaine Force, Kath Reaction):
    - Difficulty: Moderate
    - Notes: Last two terrors should spawn in the same scene Shanti brings the barrier down, and reinforcements from the north should appear at the same time. Allow an extra turn to fight the terror.

# Lester battle (ec451318)

- Test 1 (Abelon Endurance, Elaine Affinity, Kath Force, Shanti Force):
    - XP: Abelon 303, Shanti 264, Kath 222, Elaine 171, Lester 100 (Total: 1060)
    - Ignea: 13 used
    - Difficulty: Moderate
    - Notes: Used a lot of retribution and riposte. Even without a high force Elaine, still kind of easy. Basic combo of trust->blindspot->riposte->forbearance lets abelon and kath just kill everything. Maybe toss an Alpha wolf into the last two sets of reinforcements. Farsight will be needed to really get the most out of riposte.

# Final battle (ec451318)

- Test 1 (Abelon Endurance, Elaine Affinity, Kath Force, Shanti Force):
    - Difficulty: Very challenging
    - Notes: Changes made to spawns are good. Battle is going to be hard no matter what. I used poison coat to tank claws for the terror, although a retribution-based strategy to tank the full damage could be very cool. More feasible if you surround it and let it use eyes first, so that it gets the reduced movement. Gambit is very strong but I don't think it's overpowered. Found a good use-case for judgement, and seeking arrow is also extremely strong, worth the cost in many circumstances.

# Whole demo (0a6de17)

- Test 1 (Elaine Reaction/Affinity/Huntress, Kath Reaction/Defender, Abelon Force/Executioner)
    - Difficulty: Moderate
    - Revisions:
        - Nerfed lay traps to 0.8 scaling
        - Buff taunt to 0 ignea
    - Notes:
        - It was fairly straightforward to buff Abelon and Lester with Elaine and Kath, then steamroll. Kath trivialized the Terror by stunning it repeatedly.
        - This method can trivialize Terror as long as elaine learns lay traps, Kath will be able to stun and the low defence lets Abelon and Lester go in hard. But the build requirements are specific enough I think I'll allow it with the nerfed Lay Traps
        - It's clear how scaling begins to drastically affect how combat works and emphasizes different skills. The power level represented at demo 1-4 should be something like the player's power level 75% of the way through the main game (even though 1-4 is only about 1/4-1/3 of the way through the game). 
- Test 2 (Abelon Focus/Demon, Kath Force/Hero, Elaine Force/Sniper, Lester Force/Assassin, Shanti Focus/Sorceress)
    - Difficulty: Moderate
    - Revisions:
        - Buff range of Sweep
    - Notes:
        - As one might expect, less emphasis on assists in this build, but the game didn't really get any easier. Elaine was exp starved and couldn't get Deadeye, since Kath and Abelon took all of the exp. Everyone wants force assists to some extent but there aren't many to go around, so really what this build offers is the flexibility to have a different unit take the lead each turn according to their attack ranges. For example, sometimes Elaine was useful, sometimes Kath was useful, sometimes Abelon. This is good! But I'll have to see if the affinity build is significantly harder. The full force build isn't synergistic, so I don't really want it to be the easiest to execute. (at the very least, it's harder to execute than the previous, more synergistic lay traps build, even post-nerf).
        - Contempt in a focus build was very effective at dealing with the Terror. I suspect even in a non-focus build this would be the case. That's alright, it doesn't see too many uses in the rest of the game.
- Test 3 (Abelon Affinity/Veteran, Kath Affinity/Cleric, Elaine Focus/Apprentice, Lester Affinity/Naturalist, Shanti Affinity/Lanternfaire)
    - Difficulty: Challenging
    - Notes:
        - This build struggles until the synergy of Peace -> Trust -> Courage can be used effectively, or Exploding Shot comes online. So it is a difficult build for the golem battle, but afterwards it works quite well, even being easier than my previous two builds. Satisfied overall.
        - Peace is strong, but so is Haste, so it's fair. Rest of Cleric should also be worth picking up, to avoid dipping being the best strategy. Guardian Angel is very strong so I think we're good here.
        - Didn't make it to the final battle because I got bored, but I'm confident the build will work there. Yet to test Leadership, Spell Ward.