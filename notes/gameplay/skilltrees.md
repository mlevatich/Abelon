# Skills and trees

## Skilltree names

Abelon: Demon, Veteran, Executioner
Kath:   Defender, Hero, Cleric
Elaine: Huntress, Apprentice, Sniper
Shanti: Lanternfaire, Sorceress
Lester: Firebrand, Assassin
Mona:   Caretaker

## Skill ideas

Goal for Abelon/Kath: 8 assists, 16 attacks
- 8 in each tree
- Start with 8 at level 8 (3 assists, 5 attacks)
- Learn 5 over the game (5 levelups, expected level 13/15), 11 remain

Goal for Elaine: 7 assists, 14 attacks
- 7 in each tree
- Start with 3 at level 3 (1 of each)
- Learn 8 over the game (8 levelups, expected level 11/15), 10 remain

Goal for Shanti/Lester: 6 assists, 12 attacks
- 9 in each tree
- Start with 6 at level 6 (2 assists, 4 attacks)
- Learn 5 over the game (5 levelups, expected level 11/15), 7 remain

Goal for Mona: 4 assists, 5 attacks
- 9 in the tree
- Start with 5 at level 10 (2 assists, 3 attacks)
- Learn 2 over the game (2 levelups, expected level 12/15), 2 remain

#### Abelon

Ideas:
- Demon: Spell: The Contract: Invoke The Contract
- Demon: Spell: Retribution: Enemies that attack Abelon suffer a big debuff. Moderate cost.
- Demon: Assist:
- Executioner: Assist: Death Blessing: Grants allies agility and affinity on kill, scales with abelon's affinity. Moderate cost.
- Executioner: Spell: Gallows: Every turn, all stats of an enemy will permanently lower by one. Big cost.
- Executioner: Assist:
- Veteran: Assist: Knights of Ebonach: High cost assist with massive range and an assortment of stat buffs. Scales well with Affinity.
- Veteran: Attack:

#### Kath

- Cleric: Spell: Regenerate: Adjacent ally heals 5hp every turn for 5 turns. Free.
- Cleric: Assist: Ward: allies on the assist are immune to spell damage. Costs 4 ignea.
- Cleric: Assist: Disperse Ignea: assist costs 2 ignea, allies have ignea costs reduced by affinity * 0.2
- Defender: Weapon: Riposte: kath retaliates against any weapon damage dealt to him. Scales on reaction
- Hero: Assist: Reliance: Allies lose all force but gain big affinity.

#### Elaine

- Apprentice: Spell: Galeforce: push a huge wall of enemies a few spaces away
- Sniper: Weapon: Piercing Shot: diagonal line AOE.
- Sniper: Weapon: Perfect Shot: Single target long ranged directional that pushes.
- Hunter: Assist:

#### Lester

- first aid: Lester skill, heals an adjacent ally by 0.5 * Agility, costs 0 ignea
- pinpoint: find a weak spot. Very specific range required.
- assassinate: if pinpoint was used last turn, and you have at least 3 assists,
does 10 + Force x 3 weapon damage
- overload: high spell damage, cost to self, cost to ignea, scale with force
- bounty: assist skill costing small ignea, scale with affinity
- thrown dagger: low damage free ranged attack, no scaling
- in shadow: passive ability - if no assists, enemies wont target you
- free assist that costs health, scales with affinity
- free weak assist, scales with reaction

#### Shanti

- Lanternfaire: Weapon: Heavy Swing: bring down lantern on enemy. attack an adjacent target, no cost, 1.0 force weapon damage
- Lanternfaire: Weapon: Knockback: push three enemies back (same range as sweep), deal Force * 0.5 weapon damage. Free.
- Lanternfaire: Weapon: Prepare Lantern: Free, reduces all Ignea costs by one for four turns.
- Lanternfaire: Weapon: Throw Lantern: Thrown lantern explodes.
- Lanternfaire: Assist: Shine: no cost, provides small unique effect in a large radius, scales with affinity
- Lanternfaire: Weapon: Study: Does nothing, prep for findings.
- Lanternfaire: Assist: Findings: Big buff to allies if used Study previously
- Lanternfaire: Assist: Bleed Vitality: long range singe target (like inspire), give an ally 1.0 lifesteal (no scaling).
- Lanternfaire: Assist: Bleed Ignea: single target assist, give an ally on-hit ignea drain scaling with affinity.
- Sorceress: Spell: Searing Light: 1.0 force spell damage, 1 ignea cost. L shaped range (think knight in chess)
- Sorceress: Spell: Detonate: 10 + 1.0 Focus spell damage, costing moderate ignea. Diagonal range.
- Sorceress: Spell: Berserk: Free aim with small AOE. Raises enemy force by 10, lowers reaction by Focus * 0.5, 2 turns. Low cost.
- Sorceress: Spell: Gravity: Damage five enemies (similar to guardian angel range) and pull them in a lot.
- Sorceress: Spell: Illuminate: Some kind of non-attacking skill based on Agility. Something funky.
- Sorceress: Spell: Radiance: big aoe, big damage, big cost. Force scaling
- Sorceress: Spell: Rain of Shards: Target a ring far away from Shanti. Enemies take damage scaling with Focus. Allies caught in it recover 1 ignea.
- Sorceress: Assist: Hypnotize: moderate cost, heavily improves force for nearby ally, scales minimally with affinity
- Sorceress: Assist: Renewal: Massive cost. allies who kill an enemy while on the assist and end their turn on it have their turn refreshed.

#### Enemies

- Living Rock: big phys aoe reduces agility

## Skill Mechanics

Every character has skill "paths" to choose from, named by nouns
(e.g. Abelon has Veteran, Demon, and Executioner), with an associated icon and
color.

A skill in path X grants a point in path X, but may require a threshold of
points from paths X Y or Z.

Each level grants a skill point to spend on a skill. Characters are recruited at some level appropriate to where they arrive in the game, and get some number of starting skills and corresponding points. Essentially, they already have some skills "unlocked". However, the number of skills they start with may not be equal to their starting level – every character, at recruitment, only has 6-7 skills so as not to overwhelm the player, even if they start at a high level. Abelon will have 13-15 skills at the end of the game, while other characters will have fewer (Mona may only have 7-8).

The skill requirements should be designed such that a) there are enough choices
with each level up (3 or 4 seems like a good number), b) a character will
possess about half of their total unlockable skills by the end of the game,
and c) by the end of the game, a character will still not even meet the
requirements for a good number of skills (i.e. at least some skills have
specific high requirements and need heavy investment).

Skills with higher requirements should generally cost more ignea, but should be
much more (situationally!) powerful, and indicate an extreme specialization in
the particular path (i.e. the "top" of Kath's Defender tree should have an
expensive Forbearance-esque skill, and the "top" of Abelon's Executioner tree
could have an instant death ability that costs Abelon some stats or health).
Skills with high cross-path requirements should also be incredibly powerful,
and feel very unique.

Low requirement skills should be low-cost, low-cooldown, bread and butter
abilities like basic attacks, set-ups, and movement abilities that open lots of
strategic options without themselves doing much.

No skill should ever be a direct upgrade of another skill. On level up, there
should never be an obvious choice - every skill has situational uses and
tradeoffs.
