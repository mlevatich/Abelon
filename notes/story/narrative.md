# Chapter-by-chapter narrative plans

The game is divided into two parts. Each part consists of seven chapters. Each chapter contains one or two "Battles", and may optionally contain "Roam" sequences where the player controls Abelon and can explore freely, and "Talk" sequences which are extended scenes of dialogue in which the player cannot move but may respond as Abelon.

## Areas

- The dense forest: A deep forest, untouched by humanity.
- The Monastery approach/entrance: Within the forest is hidden a path to a ruined Monastery.
- The Monastery sanctum ruins: A bright sanctum full of glass ceilings and beautiful artwork, fallen to ruin. A place of worship.
- The Monastery basement library/dorms: A dank, depressing library full of corpses, containing dorms for the monks of the old Monastery.
- The Caretaker's cavern: A sealed cavern below the lowest reaches of the Monastery.
- Outside Ebonach: A well defended natural haven near Ebonach. Either overrun with monsters or peaceful.

 ## Characters

- Abelon (Battlemage):     powerful, loyal, severe
- Kath (Paladin):          heroic, kind, jovial
- Elaine (Archer):         scared, courageous, starry-eyed
- Lester (Rogue):          clever, resentful, short-tempered
- Shanti (Scholar):        unflappable, bookish, incessant
- Caretaker Mona (Healer): tired, remorseful, curious

- King Sinclair: grave, pragmatic, paranoid
- Gaheris:       ancient, knowledgeable, reckless

# Part 1

## 1-1: Dense forest

Complete. See `notes/script/1-1.md`.

## 1-2: Dense forest

Complete. See `notes/script/1-2.md`.

## 1-3: Monastery approach

In progress. See `notes/TODO.md` and `src/script/1-3.lua`.

## 1-4: Monastery entrance

In progress. See `notes/TODO.md` and `src/script/1-4.lua`.

- After alpha, add the following conclusion to 1-4: After going underground, make camp inside, the party discusses their plans. They ought to lay low inside for awhile, which is perfect, since this is where the ritual needs to be performed anyway. But why were there what felt like defenses around the monastery? Isn't it abandoned? Who even would know about it? Abelon speaks more with the player after the party sleeps.

## 1-5: Monastery basement library

- 1-5 and 1-6 are the times to justify abelon’s change of heart. Up through 1-4 he is just panicking. His allies discover important truths and save his life. Even when abelon would not have done the same in their position. Maybe in 1-6 he gets separated from the party and talks to the player a bit as he resigns himself to fate? Not for too long though. Then the shock of celebrating the new year and the party being so carefree. He begins to understand the importance of happiness. This is foreshadowed by some key conversations in 1-4 and 1-5.
- seek the truth, and the ritual site, in the monastery library. Find out it must be farther in. (roam)
- Learn something important. First piece of the puzzle put together for Shanti.
- find trouble. Suits of armor. First suspect they are soldiers, then that they are empty, then finally find out they have skeletons in them. Gross! (battle). Kath is not in this one for some reason.
- post mortem, big revelations; there's more going on here than just finding a ritual site (talk)
- Lore heavy chapter!
- What if the caretaker was a tragic villain who showed up earlier? First to guide you, but then there is conflict re: treatment of the messenger. Shows up start of 1-5, abelon would’ve killed him, but loses control to player. Caretaker notices this.
- Shanti's big optional objective (see `notes/gameplay/inflection.md`).

## 1-6: Monastery basement dormitories

- 1-5 and 1-6 are the times to justify abelon’s change of heart. Up through 1-4 he is just panicking. His allies discover important truths and save his life. Even when abelon would not have done the same in their position. Maybe in 1-6 he gets separated from the party and talks to the player a bit as he resigns himself to fate? Not for too long though. Then the shock of celebrating the new year and the party being so carefree. He begins to understand the importance of happiness. This is foreshadowed by some key conversations in 1-4 and 1-5.
- 1-6 idea: an enemy that can’t be damaged, but instead exhausts itself a little with each movement, and a lot with each attack. Tank test! Mona's other general who stayed behind?
- more truth-learning, this time in the underground dorms. (talk)
- more trouble. Proactive battle. Skeletal monks animated by ignea? (battle).
- revelations in the library, lots of books to read, something about the giant monster? (talk)
- Make camp in a dorm. Realize it's the turn of the new year. Kath brought party favors! (roam).
- At night, Abelon ponders killing the party. Decides against it. Needs to know more. Frustrated. On the verge of gaining control. Addresses the demon directly, ponders it (talk).
- Abelon decides not to kill the party due to the actions and choices of the players. He learns to wait, and observe, and learn before taking action, as discovering more and more about the situation leads him to disagree with the king that murdering dissenters and using brute force is the correct path. He learns that blindly following orders is a silent and insidious pain, as his possession causes him grief and his party reminds him that his obedience to the king is a similar relinquishing of agency. And he learns that there is value in companionship, camaraderie and kindness, when despite all of the party's grousing and arguing, Kath saves his life, and reveals that he cares deeply for Abelon and admires him.
- Party celebrates the turn of the new year over a campfire. Abelon can act vaguely out of character (e.g. too happy) under the influence of the player.
- Kath's small optional objective (see `notes/gameplay/inflection.md`).


## 1-7: Monastery basement cellar

- Party makes their way to important-seeming site in the cellar. Suspect that this is the ritual site, they seek confirmation from Abelon, but his responses are confusing. (talk)
- All of the sudden, battle!
- 1-7 is like radiant dawn 3-E. A pitched battle to survive as every turn abelon grows closer to breaking free. When the turnlimit is reached, he throws off his helmet and speaks.
- Abelon, in frustration, decides to trust the party instead of killing them and tell them what is happening to him as he can't see a way forward otherwise, asks for help (talk)
    - When abelon takes helmet off, blank dialogue responses. He says hes tired of being forced into this farce, the summoning already happened, and he needs help. Then disaster strikes, earthquake!
- In 1-7, when shit hits the fan, Kath says everyone just needs to put their faith in abelon, because he can get out of these situations.
- Kath saves Abelon, party is split, Kath and Abelon thrown into cave below (talk)
- Kath's big optional objective (see `notes/gameplay/inflection.md`).

# Part 2

## 2-1: Caretaker's cavern

- 2-1 is heart-to-heart!
- Just Abelon and Kath here.
- Truths revealed in deep discussion while clearing away stones to form an exit. Kath's history, why he saved Abelon, the murder plot, Abelon's possession (talk, roam).
- They find Mona, hooded, and give chase in a battle. Driven into a corner, she summons stone monsters (battle).
- Who the heck is Mona. Alive for so long! And has demon! Misunderstanding about how long she's been down here (talk).
- Learn that Abelon would not have saved Elaine without being possessed. Abelon should bring up the sheer coincidence of how likely it was that she was trying to sabotage them.
- Learn that Kath’s dad Stefan is the old third knight captain. Friend of Abelon’s. Not a great dude, kinda like Abelon. Prioritized his home of Lefally over Kath, after helping him escape the giant monster, Stefan went back into the blaze. Kath resolved to never do that, so he is kind. Kath hates that Abelon reminds him of his dad, but can't help but admire the old knight.
- At the end of their discussion, Abelon asks Kath if they are friends. Kath is not sure, but asks back what Abelon thinks. Kath's inflection point (see `notes/gameplay/inflection.md`).
- Kath and Abelon’s battle alone is because the caretaker flees from them, hooded, and summons more golems to defend herself. But when cornered, must explain that she only wanted to observe longer.

## 2-2: Caretaker's cavern -> Monastery approach -> Monastery entrance -> Monastery sanctum ruins

- Revelations through talking with Mona, mostly about the Demon and its role in helping the people of the past. Abelon is shocked to hear they were friends. Player may respond that it knows Mona (same demon) or doesn't (different demon) (talk).
- Investigate something (roam).
- Environmental battle, falling rocks and such. Mona left behind. Going outside from the cave, emerge at the monastery approach (same place as 1-3) (battle).
- Abelon wants to kill her but Kath reminds him there’s more to learn. Question the caretaker about why she attacked, why she’s here, how she sensed them. Its a long story, she says, first she has pressing questions of her own. Player can respond to this, either option she interjects, there it is again! She recognizes the demon. Shift to talking about that until she leaves them behind when the cave collapses.

## 2-3: Monastery basement cellar -> Monastery basement library -> Monastery sanctum ruins

- 2-3 lore heavy chapter!
- Find the others, they learned stuff too! Shanti will tell the story...
- 2-3 has no roam segments, though it includes long scenes of shanti just walking around, without much being said. Hopefully makes the player more aware of their control. When shanti, lester, elaine are alone, it’s shanti who brings up how likely it was that elaine was a traitor. Consider abelon’s position. Paranoia is his bedside companion
- Shanti, Lester, Elaine learn that there's something to be done here more important than any ritual. The ruins hold secrets about this giant monster, and the learn its true nature. They also chat, about themselves and about Abelon and Kath. NO roaming.
- Shanti finds the giant store of ignea in the sanctum here. Also explores the library.
- Shanti goes looking for monsters to confirm her findings; ignea re-animates them. Quick auto-battle.
- They hear a quake and go to the monastery approach where Abelon and Kath emerged from the tunnel.
- Learn that Lester became a knight to surpass Abelon and take his place as captain. Only cares to follow Kath.
- Shanti pursues a deeper investigation here based on whether the player completed the big optional lore objective for shanti in 1-5 She reflects that Abelon would approve/disapprove. (see `notes/gameplay/inflection.md`).

As the three chat, something like the following conversation occurs.

Lester: We need to find Captain Kath.
Elaine: Lester... You don't like Sir Abelon very much, do you?
Lester: Hmph. Does anyone? He's a heartless bastard. Sure, he knows his way around a blade, and a battlefield. But he's the tyrant's lapdog. That's all there is to say.
Shanti: Tyrant's lapdog? Slanderous words, Lester, if I've ever heard any. Do you keep such a loose tongue in town as well? It could get you in trouble.
Lester: Oh, am I not in good company? You know, Shanti, my mother followed your research quite closely. I recall the two of you even met privately in our home a few evenings, before she was murdered.
Lester: That was what, fifteen years ago? I was still in school. And even then you were looking into the correlations between mining operations, ignea usage, and monster attacks. What have you found since, I wonder? Anything that might put a target on your back?
Shanti: I am only interested in the answers my research leads me to. I try not to concern myself with King Sinclair and his preoccupations.
Lester: Oh? But I'm sure he very much concerns himself with your work. And any work that might undermine his reputation.
Elaine: Wait, why would finding a connection between mining, ignea, and monsters matter to His Majesty?
Lester: Well, think about it. Imagine if one day it came out that monsters have been after Ebonach more and more lately because of all of the ignea we've been mining.
Lester: Meanwhile Sinclair has been ordering the construction of new ignea mines, and conscripting kids into the military so they can learn to cast spells with ignea. Meaning everything he's done to fight off the monsters has been making the problem worse all along!
Lester: He'd look like a complete fool. Which he is.
Elaine: Is that true? If we closed down the mines, would the monsters go away?
Lester: If you ask me... hold on, Elaine, don't go saying anything like this around Ebonach or to your friends, ok? It could get your family in trouble.
Shanti: No, no, carry on Lester. I want to know what you think. What would happen if we closed all of the mines? Stopped using spells in battle?
Lester: Well, I wager the monsters would leave us alone. You tell me! You're the one who's figured out the two are related.
Shanti: I haven't "figured out" anything. I suspect. I investigate. And what if I were wrong? If we collapsed the mines, threw our gemstones into the Ebon, and wolves came howling at the gates? We'd be overrun within the week.
Lester: Hey, come on. I didn't mean... I wasn't trying to say it was that simple.
Lester: Whatever. None of that matters unless we find Captain Kath and get out of here.

*Later*

Elaine: Well, I like Sir Abelon. He saved my life! And he and Sir Kath agreed to take me with you all, even though I've been nothing but a burden.
Lester: With the way this expedition has been going, joining us was more a curse than a blessing...
Shanti: It's admirable you've kept your head, Elaine. Figuratively. And literally, I suppose. I'm sure all of this has been quite overwhelming for you.
Elaine: Thank you, Shanti. I guess when all of you are able to stay so calm, I feel reassured...
Lester: Actually, it's been bothering me. Abelon going out of the way to take on some useless baggage–
Shanti: *Ahem*
Lester: ...er, sorry Elaine. I shouldn't have put it quite like that.
Elaine: No, you're right. I haven't been very useful...
Lester: The point is, it's just not like him. And then there's everything he was saying about not being in control of himself, and for a second he looked so... I don't know, I've never seen him look that way before.
Shanti: It was a peculiar outburst. I'm not sure there's much more to say. Not until we find him and ask him ourselves.
Lester: There's plenty else I'd like to ask him about...

## 2-4: Monastery sanctum ruins -> Monastery entrance -> Monastery approach

- It's been a long day. After everyone shares what they've learned, it's time to make camp and discuss the next steps.
- Before settling down, Abelon comes clean, at Kath's urging. Explains his possession, to much skepticism. Finally, the punchline: memory scene where king explains the murder plot to Abelon (talk).
- Astonishment. Abelon would have killed them all the first night if he hadn't been possessed. Lester gets pissed, not going to make camp with Abelon, runs out into the forest (talk).
- Go after Lester in the dark (roam).
- Unintended monster battle in darkness, pissed off forest terrors and wolves, Elaine sticks up for Abelon in mid-battle cutaways (battle).
- Lester and Abelon fight (talk).
- Lester's big optional objective (see `notes/gameplay/inflection.md`).
- Lester's inflection point (see `notes/gameplay/inflection.md`).

We begin with a big reveal memory, after Abelon talks to the player alone and rejoins the others to settle down for camp.

Abelon first shares the nature of his possession and the reason for his outburst in 1-7. He recalls arriving at the monastery ruins and offering to take the second watch. Upon being woken up for the second watch, he absconded into the trees and performed the summoning ritual out of sight, at which point he became possessed by the Demon of Old identified by the scroll. The party is skeptical, and confused as to why he performed the summoning. Abelon, to explain, tells the story of when the King entrusted him with the scroll.

In the throne room, King Sinclair gives Abelon the scroll and they chat. The king is sober, cold, calculating, and slightly paranoid, but he treats Abelon as a genuine comrade. He tells Abelon there is no ritual site; while the scroll makes mention of the monastery where it was penned 500 years ago, there is no specification that the ritual must be done there. King Sinclair wants Abelon to summon the demon and use its power to kill the party once they have reached the monastery ruins, far from the city. He wants to kill the party because they are too smart and have different ideas on how to solve the problem (e.g. stop mining ignea, etc). He fears they will oppose him. Kath is a public hero, so executing him is no good. The expedition is a strong excuse; they will die valiantly in battle. The king believes power will save the kingdom, and has placed his bet on the ritual scroll. He is ultimately wrong, but given the state of things, it’s not an unfathomable point of view. The king trusts Abelon and confides in him like a friend. He is not evil, but he is cunning and believes in his own authority by birthright. Abelon has absolute faith in the King, and considers the king his only friend. It is the two of them against the masses, acting in the peoples’ best interest and enduring their ire. Abelon has embraced this role fully and is not accustomed to thinking for himself. The scene closes with the king apologizing for asking Abelon to kill Kath, as Kath is a good friend. Abelon responds frankly by saying Kath is not his friend.

The party comes to the realization that, after summoning the demon, Abelon intended to kill the group on his return to camp, and would have done so if not for his possession.

Lester is infuriated and runs from camp into forest.

After the party chases lester after big reveal scene, elaine has a hero moment of advocating for abelon, saying she was scared but just doesnt think he could do those things. But monsters appear. Afterwards, he and abelon fight, no player intervention. Lester just needed some time to cool off, he regrets endangering them. But Kath saying abelon was just following kings orders sets lester off. Lester claims Abelon believed he was right, always. Abelon says lester’s mom isnt innocent, reveals what lester’s mom did (kill soldier in home invasion to investigate/find treasonous documents). Lester furious, I dont believe this, did you come after me just to goad me into killing you, but when pressed Abelon says he wouldnt do it again. Lester demands to know abelon isnt just fishing for forgiveness. No forgiveness. Abelon doesnt lie. Or if inflection failed, Lester goes eerily silent. Apologizes for going into the forest. Will kill Abelon after the expedition ends.

## 2-5: Monastery approach -> Dense forest -> Caretaker's cave

- Outside the Monastery, Abelon and Kath combine what they learned with the others. Now they know what must be done. We know there's a Messenger, and we should find it and deal with it. But it's supposed to be in the caretaker's cave, which collapsed, find another entrance. (talk).
- Finding the other entrance to the cave, put more puzzle pieces together, proactive battle that is forced because we're going into the cave again (battle).
- Prepare to make camp inside because anything could happen (roam). 
- When settling down, in a moment alone, Abelon confides in the demon (talk).
- Elaine's big optional objective (see `notes/gameplay/inflection.md`).
- Shanti's inflection point (see `notes/gameplay/inflection.md`).

For 2-5 we go back to having the player doing a decent amount of the talking for Abelon, but he pipes in every now and again. It is a little awkward when you both have control, but it seems that Abelon is beginning not to resent the player. He is confused about it. Culminates in him confiding in the demon and understanding that he needs to get it off his chest. The demon can agree, or not.

By the time we reach battle 10 (reunite w/ elaine/shanti/lester) the caretaker helped abelon put the puzzle pieces together, and the other three have the last missing piece of info. We know what needs to be done. Before battle 10 discussion of what needs to be done and sharing of knowledge. Battle 10 is a proactive step, not an ambush.

## 2-6: Monastery sanctum ruins

- Party is woken up by Mona. Shares the rest of her knowledge, confirming much of what they've learned and shedding additional light on the Messenger and its history. She expresses shame that she did not know it was wrecking the world. She did not know ignea was the problem, Shanti found that out. She believes she can summon it here, but the heroes must pacify it. Teleport to the sanctum ruins.
- Abelon talks to the demon frankly, finally. Expresses his pain. The player may say sorry, which Abelon finds as a great comfort, because it confirms that the demon is something close to humans, or at least understands them. Either way, he expresses gratitude.
- Final battle.
- Post mortem, final truths and reflections.
- Option to pack up and go home, or proceed to final final challenge. Can check on everyone to see what they're thinking of doing. Some secrets are still buried.
- If not doing final challenge, fast-forward to epilogue. The player can choose whether or not to continue to the ultimate battle (2-7) or end the game with the expedition a success. Mona strenuously advises against continuing, almost but not quite to the point of fourth wall breaking (i.e. don't continue unless you are very, very skilled). Ending the game here skips to the epilogue, with some changes.
- Elaine's inflection point (see `notes/gameplay/inflection.md`).

## 2-7: Monastery inner sanctum

- If choose to do final challenge, full ignea refill, do battle with infinite ignea in the great sanctum store. Subdue the ignea heart so it cannot re-summon a messenger! (battle)
- Talk about victory (talk)
- Ultimate battle

## Epilogue: Outside Ebonach

Timeskip forward into a scene where an older Abelon speaks to the suddenly stirring demon as an old friend. Having completed 2-7 has some details changed to reflect a more "complete" golden path ending. Depending on which inflection points Abelon succeeded, the fates of the party members may be different, and Kath and Shanti may come to visit.

## Bad path

## 1-3-a: Monastery approach

- One extra turn before the golems appear.
- On finding it Abelon briefly is able to talk to the player (as ???). Confident, Demon understands him, prepared to proceed (talk).

## 1-4-a: Monastery entrance

- This time, Lester not incapacitated.
- At night, Abelon talks to the player. Understanding. Says he can control the power, and that it is a kindred spirit; they will have a long and fruitful partnership. Wakes up, kills everyone (talk).

## 1-5-a: Outside Ebonach

- Timeskip forward. Abelon falls alone to the horde, despite infinite Ignea and OP abilities (battle).