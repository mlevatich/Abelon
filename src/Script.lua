require 'src.script.1-1'
require 'src.script.1-2'
require 'src.script.1-3'
require 'src.script.1-4'
require 'src.script.Items'
require 'src.script.All'

local sources = {
    ['1-1'] = s11,
    ['1-2'] = s12,
    ['1-3'] = s13,
    ['1-4'] = s14,
    ['all'] = sall,
    ['items'] = sitems
}
script = {}
for category,ss in pairs(sources) do
    for scene_name,scene in pairs(ss) do
        if category ~= 'items' and category ~= 'all' then
            script[category .. '-' .. scene_name] = scene
        elseif category ~= 'all' then
            script[scene_name] = scene
        end
    end
end
local ch_sources = {}
for category,_ in pairs(sources) do
    if category ~= 'items' and category ~= 'all' then
        table.insert(ch_sources, category)
    end
end
for scene_name,scene in pairs(sources['all']) do
    for j=1, #ch_sources do
        local c = ch_sources[j]
        script[c .. '-' .. scene_name] = scene
    end
end