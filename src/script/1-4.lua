require 'src.script.Util'

s14 = {}

s14['entry'] = {
    ['ids'] = {'abelon'},
    ['events'] = {
        blackout(),
        teleport(1, 100, 2, 'monastery-approach'), -- TODO: coords
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