require 'src.script.Util'

s14 = {}

s14['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        teleport(1, 100, 2, 'monastery-approach'),
        focus(1, 10000),
        evening(),
        chaptercard(),
        changeMusic('Canopied-Steps'),
        wait(1),
        fade(0.4),
        wait(3),
    },
    ['result'] = {
        ['do'] = function(g)
            g:getMap():blockExit('monastery-entrance') -- TODO: selectively block one side
        end
    }
}

s14['kath'] = {
    ['ids'] = {'abelon', 'kath'},
    ['events'] = {
        face(1, 2),
        say(2, 3, false,
            "It's getting to be evening... We've been apart from Lester nearly an entire day. How did he \z
             get so far ahead of us? The sheer irresponsibility of it..."
        )
    },
    ['result'] = {}
}

s14['elaine'] = {
    ['ids'] = {'abelon', 'elaine', 'shanti'},
    ['events'] = {
        lookAt(1, 2),
        lookAt(2, 3),
        say(2, 1, false,
            "Miss Shanti, um... How did you cast such amazing spells? Can you teach me?"
        )
    },
    ['result'] = {}
}

s14['shanti'] = {
    ['ids'] = {'abelon', 'shanti'},
    ['events'] = {
        lookAt(1, 2),
        say(2, 1, false,
            "But then, if that's true... yes, fascinating..."
        )
    },
    ['result'] = {}
}