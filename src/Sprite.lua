require 'src.Util'
require 'src.Constants'

require 'src.Animation'
require 'src.Menu'
require 'src.Skill'
require 'src.Script'
require 'src.Triggers'
require 'src.Battle'

Sprite = class('Sprite')

-- Class constants
INIT_DIRECTION = RIGHT
INIT_ANIMATION = 'idle'

-- Movement constants
WANDER_SPEED = 70
LEASH_DISTANCE = TILE_WIDTH * 1.5

-- Each spacter has 12 possible portraits for
-- 12 different emotions (some may not use them all)
PORTRAIT_INDICES = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-- EXP_NEXT[i] = how much experience is needed to level up at level i?
EXP_NEXT = { 1, 5, 15, 30, 50, 75, 100, 130, 160, 200, 240, 290, 340, 400 }

-- Initialize a new sprite
function Sprite:initialize(id, game)

    -- Unique identifier
    self.id = id

    -- Parse data file and helpers
    local file_id = self.id
    if tonumber(self.id:sub(#self.id, #self.id)) then
        file_id = self.id:sub(1, #self.id - 1)
    end
    local data_file = 'Abelon/data/sprites/' .. file_id .. '.txt'
    local data = { -- Defaults for unspecified fields
        "", "", "Name: ", "Ground: no", "Interactive: no", "Hitbox:", "Impression: 0",
        "Awareness: 0", "Discard: no", "Present:", "Level: 0", "Attributes:",
        "DiffiucultySubtraction:", "Skilltrees:", "Skills:", "Description: None. EOS"
    }
    if fileExists(data_file) then
        data = readLines(data_file)
    end

    local tobool = function(s) return s == 'yes' end
    local getSk = function(sk_id) return skills[sk_id] end

    -- In game displayed name
    self.name = string.sub(data[3], 7)

    -- Size
    self.w = sprite_graphics[self.id]['w']
    self.h = sprite_graphics[self.id]['h']

    -- Position
    self.x = 0
    self.y = 0

    -- Anchor position for a wandering sprite
    self.leash_x = 0
    self.leash_y = 0

    -- Velocity
    self.dx = 0
    self.dy = 0

    -- Initial animation state
    self.dir = INIT_DIRECTION
    self.animation_name = INIT_ANIMATION
    self.rot = 0 -- rotation, mainly for skill animations

    -- Sprite behaviors
    self.current_behavior = 'idle'
    self.behaviors = {
        ['wander'] = function(sp, dt) sp:_wanderBehavior(dt) end,
        ['battle'] = function(sp, dt) sp:_battleBehavior(dt) end,
        ['idle']   = function(sp, dt) sp:_idleBehavior(dt)   end,
        ['down']   = function(sp, dt) sp:_downBehavior(dt)   end,
    }

    -- Can the player interact with this sprite to start a scene?
    self.interactive = readField(data[5], tobool)

    -- Can other sprites walk through/over this sprite?
    self.ground = readField(data[4], tobool)
    self.hitbox = readArray(data[6], tonumber)

    -- Sprite's opinions
    self.impression = readField(data[7], tonumber)
    self.awareness = readField(data[8], tonumber)

    -- Info that allows this sprite to be treated as an item
    self.can_discard = readField(data[9], tobool)
    self.present_to = readArray(data[10])
    self.description = readMultiline(data, 16)

    -- Info that allows this sprite to be treated as a party member
    self.attributes = readDict(data[12], VAL, nil, tonumber)
    self.attr_difficulty_mods = readDict(data[13], VAL, nil, tonumber)
    self.skill_trees = readDict(data[14], ARR, {'name', 'skills'}, getSk)
    self.skills = readArray(data[15], getSk)
    self.skill_points = 0

    self.health = 0
    if self.attributes['endurance'] then
        self.health = self.attributes['endurance'] * 2
    end
    self.ignea = self.attributes['focus']
    self.level = readField(data[11], tonumber)
    self.exp = 0

    -- Pointer to game
    self.game = game
end

-- Get sprite's ID
function Sprite:getId()
    return self.id
end

-- Get sprite's name
function Sprite:getName()
    return self.name
end

-- Get sprite's position (top left)
function Sprite:getPosition()
    return self.x, self.y
end

-- Get sprite's position relative to where the camera is
function Sprite:getPositionOnScreen()
    return self.x - self.game.camera_x, self.y - self.game.camera_y
end

-- Get sprite's dimensions
function Sprite:getDimensions()
    return self.w, self.h
end

-- Get the sprite's opinion of Abelon
function Sprite:getImpression()
    return self.impression
end

-- Get how much the sprite knows about the player controlling Abelon
function Sprite:getAwareness()
    return self.awareness
end

-- Get the game this sprite is in
function Sprite:getGame()
    return self.game
end

-- Is this sprite interactive?
function Sprite:isInteractive()
    return self.interactive
end

-- Is this a ground sprite or standing sprite?
function Sprite:isGround()
    return self.ground
end

-- Is this sprite blocking?
function Sprite:isBlocking()
    return #self.hitbox > 0
end

function Sprite:getHitboxRect()
    local x, y = self.x + self.hitbox[1], self.y + self.hitbox[2]
    return x, y, self.hitbox[3], self.hitbox[4]
end

function Sprite:getPtexture()
    return sprite_graphics[self.id]['ptexture']
end

function Sprite:getPortrait(i)
    return sprite_graphics[self.id]['portraits'][i]
end

function Sprite:getCurrentAnimation()
    return sprite_graphics[self.id]['animations'][self.animation_name]
end

function Sprite:getRestingQuad()
    return sprite_graphics[self.id]['animations']['idle'].frames[1]
end

function Sprite:getCurrentQuad()
    return self:getCurrentAnimation():getCurrentFrame()
end

-- Sprite as an item in a menu
function Sprite:toItem()

    -- Initialize sprite options
    local u = MenuItem:new('Use', {}, nil, nil, self:mkUse())
    local p = MenuItem:new('Present', {}, nil, nil, self:mkPresent())
    local children = {u, p}
    if self.can_discard then
        local d = MenuItem:new('Discard', {}, nil, nil, self:mkDiscard(),
            "Discard the " .. string.lower(self.name) ..
            "? It will be gone forever."
        )
        table.insert(children, d)
    end

    -- Initialize hover information
    local hbox = {
        mkEle('text', {self.name}, HALF_MARGIN, HALF_MARGIN),
        mkEle('image', self:getPortrait(1),
            HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT, self:getPtexture()),
        mkEle('text', splitByCharLimit(self.description, HBOX_CHARS_PER_LINE),
            HALF_MARGIN * 3 + PORTRAIT_SIZE, BOX_MARGIN + LINE_HEIGHT)
    }

    -- Create menu item
    return MenuItem:new(self.name, children, 'See item options', {
        ['elements'] = hbox,
        ['w'] = HBOX_WIDTH
    })
end

function Sprite:mkUse()

    -- Add fail scene for this item
    script[self.id .. '-use-fail'] = {
        ['ids'] = {self.id},
        ['events'] = {
            say(1, 1, false,
                "There's no use for the " .. string.lower(self.name) .. " \z
                 at the moment."
            )
        },
        ['result'] = {}
    }

    -- Function is pulled from triggers file, unique for each item
    return item_triggers[self.id]
end

function Sprite:mkPresent()

    -- Add fail scene for this item
    script[self.id .. '-present-fail'] = {
        ['ids'] = {self.id},
        ['events'] = {
            say(1, 1, false,
                "You remove the " .. string.lower(self.name) .. " from your \z
                 pack, but no one nearby seems to notice."

            )
        },
        ['result'] = {}
    }

    -- Function checks if player is near a sprite in the present list, and if
    -- so, presents to them. Otherwise launch failure scene.
    return function(c)
        for _, sp_id in pairs(self.present_to) do
            if c:playerNearSprite(sp_id) then
                c:launchScene(self.id .. '-present-' .. sp_id)
                return
            end
        end
        c:launchScene(self.id .. '-present-fail')
    end
end

function Sprite:mkDiscard()

    -- Add discard scene for this item
    script[self.id .. '-discard'] = {
        ['ids'] = {self.id},
        ['events'] = {
            say(1, 1, false,
                "You remove the " .. string.lower(self.name) .. " from \z
                 your pack and leave it behind."
            )
        },
        ['result'] = {
            ['do'] = function(c)
                c.player:discard(self.id)
            end
        }
    }

    -- Function plays the discard scene
    return function(c)
        c:launchScene(self.id .. '-discard')
    end
end

-- Sprite as a party member in a menu
function Sprite:toPartyMember()

    local skills = self:mkSkillsMenu(true, false)

    local learn = self:mkLearnMenu()

    local hbox = self:buildAttributeBox()

    -- Put it all together!
    local opts = { skills, learn }
    return MenuItem:new(self.name, opts, "See options for " .. self.name, {
        ['elements'] = hbox,
        ['w'] = HBOX_WIDTH
    })
end

function Sprite:isLearnable(sk_id)
    if self.skill_points <= 0 then return false end
    for i = 1, #skills[sk_id].reqs do
        local tid = skills[sk_id].reqs[i][1]
        local threshold = skills[sk_id].reqs[i][2]
        points = #filter(function(s) return s.tree_id == tid end, self.skills)
        if points < threshold then return false end
    end
    return true
end

function Sprite:mkLearnable(sk_id, sk_item)
    sk_item.hover_desc = 'Learn ' .. sk_item.name
    if find(mapf(function(s) return s.id end, self.skills), sk_id) then
        sk_item.setPen = function(g)
            return DISABLE
        end
    elseif self:isLearnable(sk_id) then
        sk_item.setPen = function(g)
            return HIGHLIGHT
        end
        sk_item.action = function(g)

            if g.current_tutorial == "Experience and skill learning" then
                g:endTutorial()
            end
            self:learn(sk_id)
            local m = nil
            if g.player.open_menu then
                g.player:openInventory()
                m = g.player.open_menu
            else
                g.battle:closeMenu()
                g.battle:openBattleStartMenu()
                m = g.battle:getMenu()
            end

            -- Stupid
            m:hover(DOWN)
            m:forward()
            for i = 1, #g.player.party do
                if g.player.party[i] == self then break end
                m:hover(DOWN)
            end
            m:forward()
            m:hover(DOWN)
            m:forward()
            local skt = self.skill_trees
            local k = 1
            while k <= #skt do
                if skt[k]['name'] == skills[sk_id].tree_id then break end
                m:hover(DOWN)
                k = k + 1
            end
            m:forward()
            local sks = self.skill_trees[k]['skills']
            for i = 1, #sks do
                if sks[i].id == sk_id then break end
                m:hover(DOWN)
            end
        end
        local cm, _ = splitByCharLimit(
            "Spend one skill point to learn " .. sk_item.name .. "?",
            CBOX_CHARS_PER_LINE
        )
        sk_item.confirm_msg = cm
    end
    return sk_item
end

function Sprite:mkSkillsMenu(with_skilltrees, with_prio, attrs, hp, ign, hbox_w)

    -- Helpers
    local learnedOf = function(t)
        return filter(function(s) return s.type == t end, self.skills)
    end
    local skToMenu = function(s)
        return s:toMenuItem(icon_texture, icons, with_skilltrees, with_prio)
    end
    local hbox = {
        ['elements'] = self:buildAttributeBox(attrs, hp, ign),
        ['w'] = ite(hbox_w, hbox_w, HBOX_WIDTH)
    }

    -- Weapon and attack skills
    local skills = MenuItem:new('Skills', {
        MenuItem:new('Weapon', mapf(skToMenu, learnedOf(WEAPON)),
                 'View ' .. self.name .. "'s weapon skills", hbox),
        MenuItem:new('Spell', mapf(skToMenu, learnedOf(SPELL)),
                 'View ' .. self.name .. "'s spells", hbox)
    }, 'View ' .. self.name .. "'s learned skills", hbox)

    -- Assists, if this sprite has them
    if #learnedOf(ASSIST) > 0 then
        table.insert(skills.children, MenuItem:new('Assist',
            mapf(skToMenu, learnedOf(ASSIST)),
            'View ' .. self.name .. "'s assists", hbox)
        )
    end

    return skills
end

function Sprite:mkLearnMenu()
    local checkUnspent = function(g)
        if self.skill_points > 0 then
            return HIGHLIGHT
        end
    end
    local mkLearn = function(s)
        return self:mkLearnable(s.id,
            s:toMenuItem(icon_texture, icons, true, false)
        )
    end
    local hbox = {
        ['elements'] = self:buildAttributeBox(),
        ['w'] = HBOX_WIDTH
    }
    local skt = self.skill_trees
    local learn = MenuItem:new('Learn (' .. self.skill_points .. ')', {
        MenuItem:new(skt[1]['name'], mapf(mkLearn, skt[1]['skills']),
                 'View the ' .. skt[1]['name'] .. " tree", hbox),
        MenuItem:new(skt[2]['name'], mapf(mkLearn, skt[2]['skills']),
                 'View the ' .. skt[2]['name'] .. " tree", hbox),
        MenuItem:new(skt[3]['name'], mapf(mkLearn, skt[3]['skills']),
                 'View the ' .. skt[3]['name'] .. " tree", hbox)
    }, 'Learn new skills', hbox, nil, nil, checkUnspent)

    return learn
end

function Sprite:buildAttributeBox(tmp_attrs, tmp_hp, tmp_ign)

    -- If temp attributes were provided, use those
    local att = ite(tmp_attrs, tmp_attrs, self.attributes)

    -- Constants
    local attrib_x = BOX_MARGIN + 110
    local skills_x = attrib_x + 260
    local indent = 40
    local indent2 = 30
    local sp_x = HALF_MARGIN + indent
    local attrib_ind = attrib_x + indent
    local skills_ind = skills_x + indent
    local line = function(i)
        return HALF_MARGIN + LINE_HEIGHT * (i - 1)
    end

    -- Creating some needed strings
    local lvl_str = 'Lvl: ' .. tostring(self.level)
    local hp_str  = 'Hp: '  .. tostring(ite(tmp_hp, tmp_hp, self.health)) .. '/'
                            .. tostring(self.attributes['endurance'] * 2)
    local ign_str = 'Ign: ' .. tostring(ite(tmp_ign, tmp_ign, self.ignea)) .. '/'
                            .. tostring(self.attributes['focus'])
    local nxt = "MAX"
    if self.level <= #EXP_NEXT then
        nxt = EXP_NEXT[self.level]
    end
    local exp_str = 'Exp: ' .. tostring(self.exp) .. '/' .. nxt
    local icon = function(i)
        return icons[str_to_icon[self.skill_trees[i]['name']]]
    end
    local learnedIn = function(tn)
        local name = self.skill_trees[tn]['name']
        return #filter(function(s) return s.tree_id == name end, self.skills)
    end
    local aC = function(s)
        local old = self.attributes
        return ite(att[s] > old[s], GREEN, ite(att[s] < old[s], RED, WHITE))
    end

    -- Build all elements
    local elements = {
        mkEle('text', {self.name}, HALF_MARGIN, line(1)),
        mkEle('text', {'Attributes'}, attrib_x, line(1)),
        mkEle('image', self:getRestingQuad(),
            sp_x, line(2) + 5, spritesheet),
        mkEle('text', {hp_str},
            sp_x - #hp_str * CHAR_WIDTH / 2 + self.w / 2, line(5)),
        mkEle('text', {ign_str},
            sp_x - #ign_str * CHAR_WIDTH / 2 + self.w / 2, line(6)),
        mkEle('text', {'Endurance'}, attrib_ind,      line(2), aC('endurance')),
        mkEle('text', {'Focus'},     attrib_ind,      line(4), aC('focus')),
        mkEle('text', {'Force'},     attrib_ind,      line(6), aC('force')),
        mkEle('text', {'Affinity'}, attrib_ind + 125, line(2), aC('affinity')),
        mkEle('text', {'Reaction'}, attrib_ind + 125, line(4), aC('reaction')),
        mkEle('text', {'Agility'},  attrib_ind + 125, line(6), aC('agility')),
        mkEle('image', icons[str_to_icon['endurance']],
            attrib_ind - 25,  line(2), icon_texture),
        mkEle('image', icons[str_to_icon['focus']],
            attrib_ind - 25,  line(4), icon_texture),
        mkEle('image', icons[str_to_icon['force']],
            attrib_ind - 25,  line(6), icon_texture),
        mkEle('image', icons[str_to_icon['affinity']],
            attrib_ind + 100, line(2), icon_texture),
        mkEle('image', icons[str_to_icon['reaction']],
            attrib_ind + 100, line(4), icon_texture),
        mkEle('image', icons[str_to_icon['agility']],
            attrib_ind + 100, line(6), icon_texture),
        mkEle('text', {tostring(att['endurance'])},
            attrib_ind + indent2,       line(3), aC('endurance')),
        mkEle('text', {tostring(att['focus'])},
            attrib_ind + indent2,       line(5), aC('focus')),
        mkEle('text', {tostring(att['force'])},
            attrib_ind + indent2,       line(7), aC('force')),
        mkEle('text', {tostring(att['affinity'])},
            attrib_ind + indent2 + 100, line(3), aC('affinity')),
        mkEle('text', {tostring(att['reaction'])},
            attrib_ind + indent2 + 100, line(5), aC('reaction')),
        mkEle('text', {tostring(att['agility'])},
            attrib_ind + indent2 + 100, line(7), aC('agility'))
    }

    -- Additional elements if sprite has skill trees
    if next(self.skill_trees) ~= nil then
        elements = concat(elements, {
            mkEle('text', {lvl_str},
                sp_x - #lvl_str * CHAR_WIDTH / 2 + self.w / 2, line(4)),
            mkEle('text', {exp_str},
                sp_x - #exp_str * CHAR_WIDTH / 2 + self.w / 2, line(7)),
            mkEle('text', {'Skills Learned'}, skills_x, line(1)),
            mkEle('text', {self.skill_trees[1]['name']}, skills_ind, line(2)),
            mkEle('text', {self.skill_trees[2]['name']}, skills_ind, line(4)),
            mkEle('text', {self.skill_trees[3]['name']}, skills_ind, line(6)),
            mkEle('image', icon(1), skills_ind - 25, line(2), icon_texture),
            mkEle('image', icon(2), skills_ind - 25, line(4), icon_texture),
            mkEle('image', icon(3), skills_ind - 25, line(6), icon_texture),
            mkEle('text', {tostring(learnedIn(1))},
                skills_ind + indent2, line(3)),
            mkEle('text', {tostring(learnedIn(2))},
                skills_ind + indent2, line(5)),
            mkEle('text', {tostring(learnedIn(3))},
                skills_ind + indent2, line(7))
        })
    end

    return elements
end

-- Learn a new skill
function Sprite:learn(sk_id)
    if self.skill_points > 0 then
        self.skill_points = self.skill_points - 1
        table.insert(self.skills, skills[sk_id])
    end
end

function Sprite:computeLevels(e)

    -- How many level ups?
    local total = EXP_NEXT[self.level]
    if not total then total = math.huge end
    local new = self.exp + e
    local levels = 0
    while new >= total do
        new = new - total
        levels = levels + 1
        total = EXP_NEXT[self.level + levels]
    end
    return new, levels
end

-- Gain exp and potentially level up, increasing attributes and
-- earning skill points
function Sprite:gainExp(e)
    local new, levels = self:computeLevels(e)
    self.exp = new
    self.level = self.level + levels
    self.skill_points = self.skill_points + levels
    for k, v in pairs(self.attributes) do
        self.attributes[k] = self.attributes[k] + levels
    end
    self.health = self.health + (levels * 2)
    self.ignea = self.ignea + levels
    return levels
end

-- Stop sprite's velocity
function Sprite:stop()
    self.dx = 0
    self.dy = 0
end

-- Modify a sprite's base position
function Sprite:resetPosition(new_x, new_y)

    -- Chain sprite to position so they can't wander too far
    self.leash_x = new_x
    self.leash_y = new_y

    -- Move sprite to new position
    self.x = new_x
    self.y = new_y

    -- Stop sprite
    self:stop()
end

-- Move sprite to new position
function Sprite:move(x, y)
    self.x = x
    self.y = y
end

-- Change a sprite's impression of Abelon (cannot drop below zero)
function Sprite:changeImpression(value)
    self.impression = math.max(self.impression + value, 0)
end

-- Change a sprite's awareness of the player
function Sprite:changeAwareness(value)
    self.awareness = self.awareness + value
end

function Sprite:djikstra(graph, src, dst, depth)

    local map = self.game:getMap()

    -- If no source was provided, source is the sprite's current tile
    if not src then
        src_tile = map:tileAt(self.x + self.w / 2, self.y + self.h / 2)
        src = { src_tile['y'], src_tile['x'] }
    end

    -- If no depth was provided, depth is infinite
    if not depth then depth = math.huge end

    -- If source and dest are the same, path is empty
    if dst and src[1] == dst[1] and src[2] == dst[2] then
        return {}
    end

    -- If no graph was provided, build one from the sprite's current map
    if not graph then

        -- Build graph from scratch (expensive)
        graph = {}
        for i = 1, #map.tiles do
            graph[i] = {}
            for j = 1, #map.tiles[i] do
                if map.collide_tiles[map.tiles[i][j]] then
                    graph[i][j] = false
                else
                    graph[i][j] = GridSpace:new()
                end
            end
        end

        -- Occupy graph with blocking sprites on map
        local sps = map:getSprites()
        for i = 1, #sps do
            if sps[i]:isBlocking() then
                local x, y, w, h = sps[i]:getHitboxRect()
                local corners = {
                    map:tileAt(x, y),         map:tileAt(x + w - 1, y),
                    map:tileAt(x, y + h - 1), map:tileAt(x + w - 1, y + h - 1)
                }
                for j = 1, #corners do
                    graph[corners[j]['y']][corners[j]['x']].occupied = sps[i]
                end
            end
        end
        graph[src[1]][src[2]].occupied = self
    end

    -- Initialization
    local dist = {} -- Distance to node (i, j)
    local prev = {} -- Previous node on path to (i, j)
    local un   = {} -- Is (i, j) not yet visited?
    for i = 1, #graph do
        dist[i] = {}
        prev[i] = {}
        un[i]   = {}
        for j = 1, #graph[i] do
            dist[i][j] = math.huge
            prev[i][j] = nil
            un[i][j]   = true
        end
    end
    dist[src[1]][src[2]] = 0 -- Distance to source is 0

    -- Djikstra loop
    while true do

        -- Get min dist node among unvisited nodes which are on the grid, if
        -- such a node exists
        local n = nil
        local min_dist = math.huge
        for i = 1, #graph do
            for j = 1, #graph[i] do
                if un[i][j] and graph[i][j]
                and not (graph[i][j].occupied and graph[i][j].occupied ~= self)
                then
                    if dist[i][j] < min_dist then
                        n = { i, j }
                        min_dist = dist[i][j]
                    end
                end
            end
        end

        -- If there is a node to visit, visit it, otherwise we're done
        if n then

            -- Mark min_dist_node as visited
            un[n[1]][n[2]] = false

            -- If dst was specified, and min_dist_node is dst, we're done
            if dst and dst[1] == n[1] and dst[2] == n[2] then break end

            -- Get tentative distance (every edge has weight 1)
            local d = dist[n[1]][n[2]] + 1

            -- If tentative distance is greater than depth, skip
            if d <= depth then

                -- Get all neighbors of min_dist_node
                local neighbors = {
                    { n[1] - 1, n[2] }, { n[1] + 1, n[2] },
                    { n[1], n[2] - 1 }, { n[1], n[2] + 1 }
                }
                local k = 1
                while k <= #neighbors do

                    -- Filter neighbors to on grid and unoccupied
                    local v = neighbors[k]
                    if not un[v[1]]
                    or not un[v[1]][v[2]]
                    or not graph[v[1]][v[2]]
                    or (graph[v[1]][v[2]].occupied and
                        graph[v[1]][v[2]].occupied ~= self)
                    then
                        table.remove(neighbors, k)
                    else

                        -- If tentative distance less than actual, replace
                        -- distance and make n the prev of this neighbor
                        if d < dist[v[1]][v[2]] then
                            dist[v[1]][v[2]] = d
                            prev[v[1]][v[2]] = n
                        end

                        -- Move on to next neighbor
                        k = k + 1
                    end
                end
            end
        else
            break
        end
    end

    -- If a dst node was provided and there is a path to it, return path
    -- Otherwise just return distances
    if dst and prev[dst[1]][dst[2]] then

        -- Compute and return path
        local path = {}
        local cur = dst
        while cur[1] ~= src[1] or cur[2] ~= src[2] do
            table.insert(path, 1, cur)
            cur = prev[cur[1]][cur[2]]
        end
        return path
    end
    return dist, prev
end

-- Play an animation once, followed by a doneAction
function Sprite:fireAnimation(animation_name, doneAction)
    self:changeAnimation(animation_name)
    self:getCurrentAnimation():setDoneAction(doneAction)
end

-- Change the animation the sprite is performing
function Sprite:changeAnimation(new_animation_name)

    -- Get the new animation for the sprite
    local current_animation = self:getCurrentAnimation()
    self.animation_name = new_animation_name
    local new_animation = self:getCurrentAnimation()

    -- Start the new animation from the beginning (if it's actually new)
    if new_animation ~= current_animation then
        new_animation:restart()
    end

    -- Fire done action if the old animation had one
    current_animation:fireDoneAction()
end

-- Change a sprite's behavior so that they perform different actions
function Sprite:changeBehavior(new_behavior)
    self.current_behavior = new_behavior
end

-- Add new behavior functions or replace old ones for this sprite
function Sprite:addBehaviors(new_behaviors)
    for name, fxn in pairs(new_behaviors) do
        self.behaviors[name] = fxn
    end
end

function Sprite:_behaviorSequence(i, behaviors, doneAction)
    if i == #behaviors then
        self.behaviors['seq'] = nil
        return behaviors[i](doneAction)
    end
    return behaviors[i](function()
        self:addBehaviors({
            ['seq'] = self:_behaviorSequence(i + 1, behaviors, doneAction)
        })
        self:changeBehavior('seq')
    end)
end

function Sprite:behaviorSequence(mkBehaviors, doneAction)
    if not next(mkBehaviors) then return doneAction() end
    self:addBehaviors({
        ['seq'] = self:_behaviorSequence(1, mkBehaviors, doneAction)
    })
    self:changeBehavior('seq')
end

function Sprite:skillBehaviorGeneric(doneAction, sk, sk_dir, x, y, affected_tiles)
    local anim_type = ite(sk.type == WEAPON, 'weapon',
                          ite(sk.type == SPELL, 'spell', 'assist'))
    local skill_anim_done = false
    local skill_anim_fired = false
    local fired = false
    if abs((x - 1) * TILE_WIDTH - self.x) > TILE_WIDTH / 2 then
        self.dir = ite((x - 1) * TILE_WIDTH > self.x, RIGHT, LEFT)
    end
    return function(sp, dt)
        self:stop()
        if not skill_anim_fired then
            self:fireAnimation(anim_type, function()
                self:changeAnimation('combat')
                skill_anim_done = true
                doneAction()
            end)
            skill_anim_fired = true
        end
        local frame = self:getCurrentAnimation().current_frame
        if not fired and (frame >= 6 or skill_anim_done) then
            if sk.anim_type == SKILL_ANIM_RELATIVE then

                -- Spawn animation with arbitrary high position so it renders above everything
                local skill_anim_sp = self.game:spawnSprite(sk.id, 10000, 10000, self.dir)

                -- Change its position to be centered on caster
                skill_anim_sp:resetPosition(
                    self.x - (skill_anim_sp.w - self.w) / 2, 
                    self.y - (skill_anim_sp.h - self.h) / 2
                )

                -- Set rotation based on direction of skill and direction of caster
                local turns = 0
                if (sk_dir == UP and self.dir == RIGHT) or (sk_dir == DOWN and self.dir == LEFT)  then turns = 3 end
                if (sk_dir == UP and self.dir == LEFT)  or (sk_dir == DOWN and self.dir == RIGHT) then turns = 1 end
                skill_anim_sp.rot = math.pi * turns / 2

                -- Play skill animation, delete its sprite when done
                skill_anim_sp:behaviorSequence({ function(d)
                    skill_anim_sp:fireAnimation('play', function()
                        self.game:deleteSprite(skill_anim_sp:getId())
                    end)
                    return pass
                end }, pass)

            elseif sk.anim_type == SKILL_ANIM_GRID then
                for i = 1, #affected_tiles do
                    
                    -- Spawn animation with arbitrary high position so it renders above everything
                    local skill_anim_sp = self.game:spawnSprite(sk.id .. tostring(i), 10000, 10000, RIGHT)

                    -- Change its position to be centered on tile
                    local t = affected_tiles[i]
                    skill_anim_sp:resetPosition(
                        t[2] * TILE_WIDTH - (skill_anim_sp.w - self.w) / 2,
                        t[1] * TILE_HEIGHT - (skill_anim_sp.h - self.h) / 2
                    )

                    -- Play skill animation, delete its sprite when done
                    skill_anim_sp:behaviorSequence({ function(d)
                        skill_anim_sp:fireAnimation('play', function()
                            self.game:deleteSprite(skill_anim_sp:getId())
                        end)
                        return pass
                    end }, pass)
                end
            end
            fired = true
        end
    end
end

function Sprite:waitBehaviorGeneric(doneAction, waitAnimation, s)
    local timer = s
    return function(sp, dt)
        self:stop()
        self:changeAnimation(waitAnimation)
        timer = timer - dt
        if timer < 0 then doneAction() end
    end
end

function Sprite:walkToBehaviorGeneric(doneAction, tile_x, tile_y, run, anim)

    -- How fast are we walking?
    local speed = ite(run, WANDER_SPEED * 2, WANDER_SPEED)

    -- Where are we going?
    local x_dst, y_dst = tileToPixels(tile_x, tile_y)

    -- Path ordering info
    local order = {
        ite(self.y > y_dst, UP, DOWN), ite(self.x > x_dst, LEFT, RIGHT)
    }
    local prev_x, prev_y = -1, -1
    local since_reorder = 0
    local reorder = function(i)
        local tmp = order[1]
        order[1] = order[2]
        order[2] = tmp
        since_reorder = i
    end

    -- Behavior function
    return function(sp, dt)

        -- Reordering direction taken when an obstacle is hit
        local x, y = self:getPosition()
        if since_reorder ~= 0 then since_reorder = since_reorder - dt end
        if since_reorder < 0 then reorder(0) end
        if x == prev_x and y == prev_y then reorder(1) end
        prev_x = x
        prev_y = y

        -- Are we done?
        if (order[2] == UP and x == x_dst and y <= y_dst) or
           (order[2] == DOWN and x == x_dst and y >= y_dst) then
            self.y = y_dst
            self:resetPosition(self.x, self.y)
            self:changeBehavior('idle')
            doneAction()
        elseif (order[2] == LEFT and y == y_dst and x <= x_dst) or
               (order[2] == RIGHT and y == y_dst and x >= x_dst) then
            self.x = x_dst
            self:resetPosition(self.x, self.y)
            self:changeBehavior('idle')
            doneAction()
        else

            -- Keep walking!
            self:changeAnimation(ite(anim, anim, 'walking'))
            if order[1] == UP then
                if y <= y_dst then
                    self.y = y_dst
                    self.dy = 0
                    self.dx = speed * order[2]
                    self.dir = order[2]
                else
                    self.dx = 0
                    self.dy = -speed
                end
            elseif order[1] == DOWN then
                if y >= y_dst then
                    self.y = y_dst
                    self.dy = 0
                    self.dx = speed * order[2]
                    self.dir = order[2]
                else
                    self.dx = 0
                    self.dy = speed
                end
            elseif order[1] == LEFT then
                if x <= x_dst then
                    self.x = x_dst
                    self.dx = 0
                    self.dy = speed * ite(order[2] == DOWN, 1, -1)
                else
                    self.dy = 0
                    self.dx = -speed
                    self.dir = LEFT
                end
            elseif order[1] == RIGHT then
                if x >= x_dst then
                    self.x = x_dst
                    self.dx = 0
                    self.dy = speed * ite(order[2] == DOWN, 1, -1)
                else
                    self.dy = 0
                    self.dx = speed
                    self.dir = RIGHT
                end
            end

            -- Update our position
            self:updatePosition(dt, x_dst, y_dst)
        end
    end
end

-- Sprite wandering behavior
function Sprite:_wanderBehavior(dt)

    -- Chance to stop walking if walking
    if (self.dx ~= 0 or self.dy ~= 0) and math.random() <= 0.05 then

        -- Stop moving
        self:stop()
        self:changeAnimation('idle')

    -- Chance to start walking in random direction if still
    elseif self.dx == 0 and self.dy == 0 and math.random() <= 0.01 then

        -- Pick a random direction to move in
        dir = math.random()
        if dir >= 0.75 then
            self.dx = WANDER_SPEED
            self.dir = RIGHT
        elseif dir < 0.75 and dir >= 0.5 then
            self.dx = -WANDER_SPEED
            self.dir = LEFT
        elseif dir < 0.50 and dir >= 0.25 then
            self.dy = WANDER_SPEED
        else
            self.dy = -WANDER_SPEED
        end

        -- Start walking animation
        self:changeAnimation('walking')
    end

    -- Get distance from sprite's leash
    x_dist = self.x - self.leash_x
    y_dist = self.y - self.leash_y

    -- If too far right, go left
    if x_dist > LEASH_DISTANCE then
        self:changeAnimation('walking')
        self.dx = -WANDER_SPEED
        self.dir = LEFT
        self.dy = 0

    -- If too far left, go right
    elseif x_dist < -LEASH_DISTANCE then
        self:changeAnimation('walking')
        self.dir = RIGHT
        self.dx = WANDER_SPEED
        self.dy = 0

    -- If too far down, go up
    elseif y_dist > LEASH_DISTANCE then
        self:changeAnimation('walking')
        self.dy = -WANDER_SPEED
        self.dx = 0

    -- If too far up, go down
    elseif y_dist < -LEASH_DISTANCE then
        self:changeAnimation('walking')
        self.dy = WANDER_SPEED
        self.dx = 0
    end

    self:updatePosition(dt)
end

-- Sprite idle behavior
function Sprite:_idleBehavior(dt)
    self:stop()
    self:changeAnimation('idle')
end

-- Sprite battle behavior
function Sprite:_battleBehavior(dt)
    self:stop()
    self:changeAnimation('combat')
end

-- Sprite downed behavior
function Sprite:_downBehavior(dt)
    self:stop()
    self:changeAnimation('downed')
end

-- Check whether a sprite is on a tile and return displacement
function Sprite:onTile(x, y)

    -- Check if the tile matches the tile at any corner of the sprite
    local map = self.game:getMap()
    local sx, sy, w, h = self:getHitboxRect()

    -- Check northwest tile
    local match, new_x, new_y = map:pixelOnTile(sx, sy, x, y)
    if match then
        return true, new_x, new_y
    end

    -- Check northeast tile
    match, new_x, new_y = map:pixelOnTile(sx + w, sy, x, y)
    if match then
        return true, new_x - w, new_y
    end

    -- Check southwest tile
    match, new_x, new_y = map:pixelOnTile(sx, sy + h, x, y)
    if match then
        return true, new_x, new_y - h
    end

    -- Check southeast tile
    match, new_x, new_y = map:pixelOnTile(sx + w, sy + h, x, y)
    if match then
        return true, new_x - w, new_y - h
    end

    -- Return nil if no match
    return false, nil, nil
end

-- Check if the given sprite is within an offset distance to self
function Sprite:AABB(sp, offset)
    local x, y, w, h  = self:getHitboxRect()
    local x2, y2 = sp:getPosition()
    local w2, h2 = sp:getDimensions()
    if sp:isBlocking() then
        x2, y2, w2, h2 = sp:getHitboxRect()
    end
    local x_inside = (x < x2 + w2 + offset) and (x + w > x2 - offset)
    local y_inside = (y < y2 + h2 + offset) and (y + h > y2 - offset)
    return x_inside and y_inside
end

-- Handle all collisions in current frame
function Sprite:checkCollisions()
    self:_checkMapCollisions()
    self:_checkSpriteCollisions()
end

-- Handle collisions with other sprites for this sprite
function Sprite:_checkSpriteCollisions()

    -- Iterate over all active sprites
    for _, sp in ipairs(self.game:getActiveSprites()) do
        if sp.name ~= self.name and sp:isBlocking() then

            local x,  y,  w,  h  = self:getHitboxRect()
            local x2, y2, w2, h2 = sp:getHitboxRect()

            -- Collision from right or left of target
            local x_move = nil
            local y_inside = (y < y2 + h2) and (y + h > y2)
            local right_dist = x - (x2 + w2)
            local left_dist = x2 - (x + w)
            if y_inside and right_dist <= 0 and
               right_dist > -w2/2 and self.dx < 0 then
                x_move = x2 + w2
            elseif y_inside and left_dist <= 0 and
                   left_dist > -w2/2 and self.dx > 0 then
                x_move = x2 - w
            end

            -- Collision from below target or above target
            local y_move = nil
            local x_inside = (x < x2 + w2) and (x + w > x2)
            local down_dist = y - (y2 + h2)
            local up_dist = y2 - (y + h)
            if x_inside and down_dist <= 0 and
               down_dist > -h2/2 and self.dy < 0 then
                y_move = y2 + h2
            elseif x_inside and up_dist <= 0 and
                   up_dist > -h2/2 and self.dy > 0 then
                y_move = y2 - h
            end

            -- Perform shorter move
            if x_move and y_move then
                if abs(x_move - x) < abs(y_move - y) then
                    self.x = x_move - (x - self.x)
                else
                    self.y = y_move - (y - self.y)
                end
            elseif x_move then
                self.x = x_move - (x - self.x)
            elseif y_move then
                self.y = y_move - (y - self.y)
            end
        end
    end
end

-- Handle map collisions for this sprite
function Sprite:_checkMapCollisions()

    -- Convenience variables
    local map = self.game:getMap()
    local x, y, w, h = self:getHitboxRect()

    -- Check all surrounding tiles
    local above_left = map:collides(map:tileAt(x, y - 1))
    local above_right = map:collides(map:tileAt(x + w - 1, y - 1))

    local below_left = map:collides(map:tileAt(x, y + h))
    local below_right = map:collides(map:tileAt(x + w - 1, y + h))

    local right = map:collides(map:tileAt(x + w, y + h / 2))
    local right_above = map:collides(map:tileAt(x + w, y))
    local right_below = map:collides(map:tileAt(x + w, y + h - 1))

    local left = map:collides(map:tileAt(x - 1, y + h / 2))
    local left_above = map:collides(map:tileAt(x - 1, y))
    local left_below = map:collides(map:tileAt(x - 1, y + h - 1))

    -- Conditions for a collision
    local above_condition = (above_left and above_right)
                         or (above_left and not left and not left_below)
                         or (above_right and not right and not right_below)

    local below_condition = (below_left and below_right)
                         or (below_left and not left and not left_above)
                         or (below_right and not right and not right_above)

    local left_condition = (left_above and left)
                        or (left_below and left)
                        or (left_above and not above_right)
                        or (left_below and not below_right)

    local right_condition = (right_above and right)
                         or (right_below and right)
                         or (right_above and not above_left)
                         or (right_below and not below_left)

    -- Perform up-down move if it's small enough
    if above_condition then
        local y_move = map:tileAt(x, y - 1).y * TILE_HEIGHT
        if abs(y_move - y) <= 2 then
            self.y = y_move - (y - self.y)
        end
    elseif below_condition then
        local y_move = (map:tileAt(x, y + h).y - 1) * TILE_HEIGHT - h
        if abs(y_move - y) <= 2 then
            self.y = y_move - (y - self.y)
        end
    end

    -- perform left-right move if it's small enough
    if left_condition then
        local x_move = map:tileAt(x - 1, y).x * TILE_WIDTH
        if abs(x_move - x) <= 2 then
            self.x = x_move - (x - self.x)
        end
    elseif right_condition then
        local x_move = (map:tileAt(x + w, y).x - 1) * TILE_WIDTH - w
        if abs(x_move - x) <= 2 then
            self.x = x_move - (x - self.x)
        end
    end
end

-- Update rendered frame of animation
function Sprite:updateAnimation(dt)
    self:getCurrentAnimation():update(dt)
end

-- Update sprite's position from dt
function Sprite:updatePosition(dt, x_dst, y_dst)
    pre_x  = self.x
    post_x = self.x + self.dx * dt
    pre_y  = self.y
    post_y = self.y + self.dy * dt

    if x_dst and (pre_x < x_dst) ~= (post_x < x_dst) then
        self.x = x_dst
    else
        self.x = post_x
    end

    if y_dst and (pre_y < y_dst) ~= (post_y < y_dst) then
        self.y = y_dst
    else
        self.y = post_y
    end

    local w, h = self.game:getMap():getPixelDimensions()
    self.x = math.max(math.min(self.x, w - self.w - 1), 1)
    self.y = math.max(math.min(self.y, h - self.h - 1), 1)
end

-- Per-frame updates to a sprite's state
function Sprite:update(dt)

    -- Store starting y value, in case it changes
    local y_init = self.y

    -- Update velocity, direction, behavior,
    -- and animation based on current behavior
    self.behaviors[self.current_behavior](self, dt)

    -- Update frame of animation
    self:updateAnimation(dt)

    -- Handle collisions with walls or other sprites
    if self:isBlocking() then
        self:checkCollisions()
    end
    return self.y - y_init
end

-- Render a sprite to the screen
function Sprite:render()

    -- Set special rendering color based on battle
    local b = self.game.battle
    local mono, alpha, skull = false, 1, false
    if b and not self.game.current_scene then
        mono, alpha, skull = b:getSpriteRenderFlags(self)
    end
    local clr = { 1, 1, 1, 1 }
    if mono then clr = { 0.3, 0.3, 0.3, 1 } end
    clr[4] = alpha
    
    -- Draw sprite's current animation frame, at its current position,
    -- in its current direction
    love.graphics.push('all')
    love.graphics.setColor(unpack(clr))
    love.graphics.draw(
        spritesheet,
        self:getCurrentQuad(),
        self.x + self.w / 2,
        self.y + self.h / 2,
        self.rot,
        self.dir,
        1,
        self.w / 2,
        self.h / 2
    )
    love.graphics.setColor(1, 1, 1, 0.3)
    if skull then
        local y_off = ite(b.pulse, 0, 1)
        love.graphics.draw(icon_texture, status_icons[5],
            self.x + self.w / 2 - 3, self.y + 11
        )
    end
    love.graphics.pop()
end

-- INITIALIZE GRAPHICAL DATA
living = {
    ['idle'] = { 2.5, { 0, 1, 2, 3 } },
    ['walking'] = { 6.5, { 7, 4, 5, 6 } },
    ['weapon'] = { 6.5, { 3, 4, 3, 4, 3, 4, 3, 4 } },
    ['spell'] = { 6.5, { 3, 4, 3, 4, 3, 4, 3, 4 } },
    ['assist'] = { 6.5, { 3, 4, 3, 4, 3, 4, 3, 4 } },
    ['combat'] = { 6.5, { 4, 5, 6, 7 } },
    ['hurt'] = { 6.5, { 7, 7, 7, 7 } },
    ['death'] = { 6.5, { 8, 8, 8, 8 } },
    ['displace'] = { 6.5, { 6, 6, 6, 6 } },
    ['entry'] = { 6.5, { 0 } },
    ['downed'] = { 6.5, { 16 } },
    ['getup'] = { 6.5, { 17, 18, 19, 20, 21, 22 } } 
}
inanimate = { ['idle'] = { 3.25, { 0 } } }
sprite_data = {
    {
        ['id'] = 'abelon',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living
    },
    {
        ['id'] = 'kath',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living
    },
    {
        ['id'] = 'elaine',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living
    },
    {
        ['id'] = 'lester',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living
    },
    {
        ['id'] = 'shanti',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living
    },
    {
        ['id'] = 'alphawolf',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living,
        ['n'] = 2
    },
    {
        ['id'] = 'wolf',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living,
        ['n'] = 4
    },
    {
        ['id'] = 'living_rock',
        ['w'] = 31,
        ['h'] = 31,
        ['animations'] = living,
        ['n'] = 3
    },
    {
        ['id'] = 'torch',
        ['w'] = 22,
        ['h'] = 31,
        ['animations'] = {
            ['idle'] = { 6.5, { 1, 2, 3, 4, 5, 6, 7, 8 } },
            ['downed'] = { 6.5, { 0 } }
        },
        ['n'] = 4
    },
    {
        ['id'] = 'medallion',
        ['w'] = 20,
        ['h'] = 22
    },
    {
        ['id'] = 'book',
        ['w'] = 25,
        ['h'] = 22
    },
    {
        ['id'] = 'log',
        ['w'] = 80,
        ['h'] = 28
    },
    {
        ['id'] = 'rock',
        ['w'] = 23,
        ['h'] = 16
    },
    {
        ['id'] = 'shafe',
        ['w'] = 23,
        ['h'] = 15
    },
    {
        ['id'] = 'forniese',
        ['w'] = 22,
        ['h'] = 24
    },
    {
        ['id'] = 'colblossom',
        ['w'] = 31,
        ['h'] = 21
    },
    {
        ['id'] = 'grass',
        ['w'] = 31,
        ['h'] = 21
    },
    {
        ['id'] = 'grass2nd',
        ['w'] = 31,
        ['h'] = 21
    },
    {
        ['id'] = 'wornfleet',
        ['w'] = 18,
        ['h'] = 26
    },
    {
        ['id'] = 'bloodrite',
        ['w'] = 157,
        ['h'] = 127
    },
    {
        ['id'] = 'scroll',
        ['w'] = 24,
        ['h'] = 22
    },
    {
        ['id'] = 'igneashard',
        ['w'] = 12,
        ['h'] = 15
    },
    {
        ['id'] = 'campfire',
        ['w'] = 65,
        ['h'] = 40
    },
    {
        ['id'] = 'campbed-used',
        ['w'] = 40,
        ['h'] = 30,
        ['n'] = 3
    },
    {
        ['id'] = 'campbed',
        ['w'] = 40,
        ['h'] = 30
    },
    {
        ['id'] = 'campclutter',
        ['w'] = 40,
        ['h'] = 40
    },
    {
        ['id'] = 'sever',
        ['w'] = 64,
        ['h'] = 32,
        ['animations'] = {
            ['idle'] = { 6.5, { 4 } },
            ['play'] = { 18, { 0, 1, 2, 3 } }
        }
    },
    {
        ['id'] = 'conflagration',
        ['w'] = 32,
        ['h'] = 38,
        ['animations'] = {
            ['idle'] = { 6.5, { 13 } },
            ['play'] = { 13, { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 } }
        },
        ['n'] = 20
    },
    {
        ['id'] = 'guard_blindspot',
        ['w'] = 32,
        ['h'] = 32,
        ['animations'] = {
            ['idle'] = { 6.5, { 10 } },
            ['play'] = { 6.5, { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 } }
        },
        ['n'] = 1
    },
    {
        ['id'] = 'journal',
        ['w'] = 0,
        ['h'] = 0
    }
}
sprite_graphics = {}
local sheet_y = 0
for i = 1, #sprite_data do
    local data = sprite_data[i]
    local id = data['id']
    if data['animations'] == nil then data['animations'] = inanimate end

    local gs = {}
    if data['n'] then
        for x = 1, data['n'] do
            sprite_graphics[id .. x] = {}
            table.insert(gs, sprite_graphics[id .. x])
        end
    else
        sprite_graphics[id] = {}
        table.insert(gs, sprite_graphics[id])
    end

    for j = 1, #gs do
        local g = gs[j]
        local portrait_file = 'graphics/portraits/' .. id .. '.png'
        if love.filesystem.getInfo(portrait_file) then
            g['ptexture'] = love.graphics.newImage(portrait_file)
            g['portraits'] = getSpriteQuads(PORTRAIT_INDICES, g['ptexture'],
                PORTRAIT_SIZE, PORTRAIT_SIZE, 0
            )
        end
        g['w'] = data['w']
        g['h'] = data['h']
        g['animations'] = {}
        for name, frames in pairs(data['animations']) do
            local spd, idxs = frames[1], frames[2]
            g['animations'][name] = Animation:new(id .. '_' .. name,
                getSpriteQuads(idxs, spritesheet, data['w'], data['h'], sheet_y),
                spd
            )
        end
    end
    sheet_y = sheet_y + (data['h'] + 1)
end