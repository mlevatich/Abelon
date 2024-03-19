# Item scripts

## journal-use

```
Journal: You remove the small, leather-bound book from your pack.

A: Read it

    Journal: You remove the leather binding and attempt to read the journal, but it will not open. There must be something else sealing it shut.
A: Put it away
```

## scroll-use

```
Scroll: The ancient scroll is dense with information, but none of it is intelligible to you. You aren't sure how you might use it at the moment.
```

## scroll-present-kath

```
Kath (content): That's King Sinclair's ritual scroll, isn't it? The whole reason we're on this damn expedition... I must say, the thing's been nothing but a disappointment so far.

Kath (content): All that talk about 'heralding doom when the seal is broken', only for it to unfurl without so much as a fart after His Majesty took it from the vault!

Kath (serious): Why have you taken it out? Did you forget the instructions? The ritual site will be in a holy monastery along the road through the Red Mountain Valley.

Kath (worried): Never mind that no one has even heard of this monastery. And it'll be little more than monster-infested ruins by now, if the rumors are true about the scroll's age. 

Kath (serious): I've about had it with rituals and their strange prescriptions... But ach, orders are orders, so here we are.

-> Callback:

    Kath (content): Don't you think you ought to keep that thing in your pack? It looks fragile enough to fall to pieces under the wind and sun.
```

## medallion-use

```
Medallion: The medallion turns lazily as you hold it by the rope. You pull it over your head. The fraying rope itches the back of your neck, and the metal lump weighs on you like armor.

Medallion: Who would wear this? You put it away.
```

## medallion-present-kath

```
Kath (serious): A strung medallion? Now where have I seen that engraving before... Oh!

Kath (content): It looks a lot like a piece one of my younger knights was fiddling with! I think he was borrowing time at the blacksmith's forge to work on it.

Kath (content): For a little encouragement, I told him to show it to me when he was finished with it, but he gave me this crestfallen look, and I never heard about it again from him.

Kath (content): It looks the same as it did then, so I suppose he never got around to...

Kath (worried): ...Ach. He was already done with it, wasn't he?

A: Nice going

    Kath (content): Oops. Ha ha.

A: I'd have said the same, the metalwork is awful

    Kath (content): Poor kid. I wonder what he was intending to do with it.

Kath (worried): More importantly, what would it be doing all the way out here? I know it's not yours, and I certainly didn't bring it...

-> Callback:

    Kath (worried): A medallion that isn't either of ours... We're the only ones who have come out here recently, right?
```

## medallion-present-elaine

```
Elaine (content): Hey, that's mine! Oh, I thought it was lost for good! Sir Abelon, did you find it on the ground somewhere? May I have it?

A: Certainly (Elaine +2)

    Elaine (content): Thank you! I know it probably doesn't look like much. But it's important to me. It was a gift.

    -> Discard: Medallion

A: You wear this? It looks uncomfortable

    Elaine (content): Ah... yes, it's not very comfortable to wear. Or convenient. But it's important to me. It was a gift. May I have it back?

    A: Certainly (Elaine +2)

    A: Well, I've no use for it (Elaine +1)

    Elaine (content): Thank you!

    -> Discard: Medallion
```

## igneashard-use

```
Igneashard: Activate the ignea shard and regain 3 Ignea? You can also present it to an ally to restore their ignea.

A: Yes

    Igneashard: You grip the red stone tightly and focus your energy. It begins to glow softly. You add the activated shard to your supply.

    -> Discard: Igneashard
    -> Event: Abelon gains 3 ignea

A: No
```

## igneashard-present-kath

```
Kath (content): I see you happened on some natural Ignea! That's good news for all of us. Every little stone helps... hold on, are you offering it to me?

A: Yes

    Kath (content): You must have enough for yourself, then. Well, I'll gladly take it. And as ever, I'll make sure your trust in me is well-placed.

    -> Discard: Igneashard
    -> Event: Kath gains 3 ignea

A: No

    Kath (content): Ah. Sorry for getting ahead of myself. You'll make better use of it, in any case.
```

## igneashard-present-elaine

```
Elaine (content): That's... Ignea, isn't it, Sir Abelon? This is the first time I've ever needed to use it in a real fight. It's a beautiful stone...

Elaine (content): Oh, but, I do know how to cast spells! I think. They taught us at the academy. So if you did share some Ignea with me, I could put it to use... Um... Are you sharing it?

A: Yes (Elaine +1)

    Elaine (content): Thank you, Sir Abelon! I won't let it go to waste, I promise! I already have some ideas for spells.

    -> Discard: Igneashard
    -> Event: Elaine gains 3 ignea

A: No

    Elaine (worried): Oh... well, that's only right, isn't it. I'm the least experienced person here, and there's only so much magic to go around...
```