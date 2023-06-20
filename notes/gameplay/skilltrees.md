# Skills and trees

## Skilltree names

Abelon: Demon, Veteran, Executioner
Kath:   Defender, Hero, Cleric
Elaine: Huntress, Apprentice, Sniper
Shanti: Scholar, Sorceress
Lester: Firebrand, Assassin
Mona:   Caretaker

## Skill ideas

#### Elaine

- galeforce: push a huge wall of enemies a few spaces away

#### Abelon

- clutches: pull an enemy towards you (potentially lower its stats? Or dmg? Both?)
- Siphon: lifesteal by hitting an enemy

#### Kath

- shove: push an enemy or ally. Free
- riposte: kath retaliates against any weapon damage dealt to him

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

- searing_light: spell costing moderate ignea, scales with force. moderate range
- detonate: spell costing high ignea, scales with focus. short range
- heavy_swing: attack adjacent enemy for no cost, scales with force
- shine: no cost assist, provides small unique effect in a large radius, scales with affinity
- hypnotize: moderate cost assist, heavily improves force for nearby ally, scales minimally with affinity
- Renewal: allies who kill an enemy while on the assist and end their turn on it have their turn refreshed.

#### Enemies

- Living Rock: big phys aoe reduces agility

## Skill Mechanics

Have each skill have a potential displacement effect, which is either “slide” or “teleport” (controls animation) and specifies the distance/direction pushed as a function of skill direction and displacement from caster (so you could push “outward”). Enemies are pushed until they are stopped by a grid edge or another unit

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
