require 'src.script.Util'

s13 = {}

s13['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        teleport(1, 27, 77.5, 'monastery-approach'),
        focus(1, 10000),
        pan(0, -3000, 10000),
        daytime(),
        chaptercard(),
        changeMusic('Canopied-Steps'),
        wait(1),
        fade(0.2),
        focus(1, 300),
        wait(8),
    },
    ['result'] = {
        ['do'] = function(g)
            g:getMap():blockExit('west-forest')
        end
    }
}