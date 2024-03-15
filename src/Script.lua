require 'src.script.1-1'
require 'src.script.1-2'
require 'src.script.Items'

local sources = {
    ['1-1'] = s11,
    ['1-2'] = s12,
    ['items'] = sitems
}
script = {}
for category,ss in pairs(sources) do
    for scene_name,scene in pairs(ss) do
        if category ~= 'items' then
            script[category .. '-' .. scene_name] = scene
        else
            script[scene_name] = scene
        end
    end
end