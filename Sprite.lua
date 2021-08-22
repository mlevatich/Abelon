require 'Util'
require 'Constants'

require 'Animation'
require 'Menu'
require 'Skill'
require 'Scripts'
require 'Triggers'

Sprite = Class{}

-- Class constants
local INIT_DIRECTION = RIGHT
local INIT_ANIMATION = 'idle'
local INIT_VERSION = 'standard'

-- Movement constants
local WANDER_SPEED = 70
local LEASH_DISTANCE = TILE_WIDTH * 1.5

-- Each spacter has 12 possible portraits for
-- 12 different emotions (some may not use them all)
local PORTRAIT_INDICES = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-- Initialize a new sprite
function Sprite:init(id, spritesheet, chapter)

    -- Unique identifier
    self.id = id

    -- Parse data file and helpers
    local data_file = 'Abelon/data/sprites/' .. self.id .. '.txt'
    local data = readLines(data_file)
    local tobool = function(s) return s == 'yes' end
    local getSk = function(sk_id) return skills[sk_id] end

    -- In game displayed name
    self.name = string.sub(data[3], 7)

    -- Size
    self.w = readField(data[4], tonumber)
    self.h = readField(data[5], tonumber)

    -- Position
    self.x = 0
    self.y = 0
    self.z = readField(data[6], tonumber) -- Affects rendering order

    -- Anchor position for a wandering sprite
    self.leash_x = 0
    self.leash_y = 0

    -- Velocity
    self.dx = 0
    self.dy = 0

    -- Portrait texture, if the sprite has a portrait
    self.ptexture = nil
    self.portraits = nil
    if readField(data[13], tobool) then
        local portrait_file = 'graphics/portraits/' .. self.id .. '.png'
        self.ptexture = love.graphics.newImage(portrait_file)
        self.portraits = getSpriteQuads(
            PORTRAIT_INDICES,
            self.ptexture,
            PORTRAIT_SIZE,
            PORTRAIT_SIZE,
            0
        )
    end

    self.itex = chapter.itex
    self.icons = chapter.icons

    -- y-position on spritesheet of first costume
    local base_y = readField(data[7], tonumber)

    -- Costume names
    local version_names = readArray(data[11])

    -- Number of frames in each named animation
    local animations = readDict(data[10], ARR, nil, tonumber)

    -- The master sheet containing all versions of this sprite
    self.sheet = spritesheet

    -- All animation quads for each version (costume) of the sprite
    self.versions = {}

    -- Need a different set of animations for each version of the sprite
    for i = 1, #version_names do

        -- Y position on spritesheet for this version of the sprite
        local s_offset = base_y + (i - 1) * self.h

        -- Pull the animations from the spritesheet
        local quads = {}
        for name, frames in pairs(animations) do
            sqs = getSpriteQuads(frames, self.sheet, self.w, self.h, s_offset)
            quads[name] = Animation(sqs)
        end

        -- Associate the created animations with this version of the sprite
        self.versions[version_names[i]] = quads
    end

    -- Initial animation state
    self.dir = INIT_DIRECTION
    self.animation_name = INIT_ANIMATION
    self.version_name = INIT_VERSION
    local curam = self.versions[self.version_name][self.animation_name]
    self.current_animation = curam
    self.on_frame = self.current_animation:getCurrentFrame()

    -- Sprite behaviors
    self.resting_behavior = readField(data[12])
    self.current_behavior = self.resting_behavior
    self.behaviors = {
        ['wander'] = function() self:_wanderBehavior() end,
        ['battle'] = function() self:_battleBehavior() end,
        ['idle'] = function() self:_idleBehavior() end
    }

    -- Can the player interact with this sprite to start a scene?
    self.interactive = readField(data[8], tobool)

    -- Can other sprites walk through/over this sprite?
    self.blocking = readField(data[9], tobool)

    -- Sprite's opinions
    self.impression = readField(data[14], tonumber)
    self.awareness = readField(data[15], tonumber)

    -- Info that allows this sprite to be treated as an item
    self.can_discard = readField(data[16], tobool)
    self.present_to = readArray(data[17])
    self.description = readMultiline(data, 22)

    -- Info that allows this sprite to be treated as a party member
    self.attributes = readDict(data[19], VAL, nil, tonumber)
    self.skill_trees = readDict(data[20], ARR, {'name', 'skills'}, getSk)
    self.skills = readArray(data[21], getSk)
    self.skill_points = 0

    self.health = self.attributes['endurance']
    self.ignea = self.attributes['focus']
    self.level = readField(data[18], tonumber)
    self.exp = 0

    -- Current chapter inhabited by sprite
    self.chapter = chapter
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

-- Get sprite's depth for rendering order
function Sprite:getDepth()
    return self.z
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

-- Get the chapter this sprite is in
function Sprite:getChapter()
    return self.chapter
end

-- Is this sprite interactive?
function Sprite:isInteractive()
    return self.interactive
end

-- Is this sprite blocking?
function Sprite:isBlocking()
    return self.blocking
end

-- Sprite as an item in a menu
function Sprite:toItem()

    -- Initialize sprite options
    local u = MenuItem('Use', {}, nil, nil, self:mkUse())
    local p = MenuItem('Present', {}, nil, nil, self:mkPresent())
    local children = {u, p}
    if self.can_discard then
        local d = MenuItem('Discard', {}, nil, nil, self:mkDiscard(),
            "Discard the " .. string.lower(self.name) ..
            "? It will be gone forever."
        )
        table.insert(children, d)
    end

    -- Initialize hover information
    local hbox = {
        mkEle('text', {self.name}, HALF_MARGIN, HALF_MARGIN),
        mkEle('image', self.portraits[1],
            HALF_MARGIN, HALF_MARGIN + LINE_HEIGHT, self.ptexture),
        mkEle('text', splitByCharLimit(self.description, HBOX_CHARS_PER_LINE),
            HALF_MARGIN * 3 + PORTRAIT_SIZE, BOX_MARGIN + LINE_HEIGHT)
    }

    -- Create menu item
    return MenuItem(self.name, children, 'See item options', {
        ['elements'] = hbox,
        ['w'] = HBOX_WIDTH
    })
end

function Sprite:mkUse()

    -- Add fail scene for this item
    scripts[self.id .. '_use_fail'] = {
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
    scripts[self.id .. '_present_fail'] = {
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
                c:launchScene(self.id .. '_present_' .. sp_id)
                return
            end
        end
        c:launchScene(self.id .. '_present_fail')
    end
end

function Sprite:mkDiscard()

    -- Add discard scene for this item
    scripts[self.id .. '_discard'] = {
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
        c:launchScene(self.id .. '_discard')
    end
end

-- Sprite as a party member in a menu
function Sprite:toPartyMember()

    local skills = self:mkSkillsMenu(true)

    local learn = self:mkLearnMenu()

    local hbox = self:buildAttributeBox()

    -- Put it all together!
    local opts = { skills, learn }
    return MenuItem(self.name, opts, "See options for " .. self.name, {
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
    if find(self.skills, skills[sk_id]) then
        sk_item.setPen = function(c)
            love.graphics.setColor(unpack(DISABLE))
        end
    elseif self:isLearnable(sk_id) then
        sk_item.setPen = function(c)
            love.graphics.setColor(unpack(HIGHLIGHT))
        end
        sk_item.action = function(c)
            self:learn(sk_id)
            c.player:changeMode('free')
        end
        local cm, _ = splitByCharLimit(
            "Spend one skill point to learn " .. sk_item.name .. "?",
            CBOX_CHARS_PER_LINE
        )
        sk_item.confirm_msg = cm
    end
    return sk_item
end

function Sprite:mkSkillsMenu(with_skilltrees)

    -- Helpers
    local learnedOf = function(t)
        return filter(function(s) return s.type == t end, self.skills)
    end
    local skToMenu = function(s)
        return s:toMenuItem(self.itex, self.icons, with_skilltrees)
    end

    -- Weapon and attack skills
    local skills = MenuItem('Skills', {
        MenuItem('Weapon', mapf(skToMenu, learnedOf(WEAPON)),
                 'View ' .. self.name .. "'s weapon skills"),
        MenuItem('Spell', mapf(skToMenu, learnedOf(SPELL)),
                 'View ' .. self.name .. "'s spells")
    }, 'View ' .. self.name .. "'s learned skills")

    -- Assists, if this sprite has them
    if #learnedOf(ASSIST) > 0 then
        table.insert(skills.children, MenuItem('Assist',
            mapf(skToMenu, learnedOf(ASSIST)),
            'View ' .. self.name .. "'s assists")
        )
    end

    return skills
end

function Sprite:mkLearnMenu()
    local checkUnspent = function(c)
        if self.skill_points > 0 then
            love.graphics.setColor(unpack(HIGHLIGHT))
        end
    end
    local mkLearn = function(s)
        return self:mkLearnable(s.id, s:toMenuItem(self.itex, self.icons, true))
    end
    local skt = self.skill_trees
    local learn = MenuItem('Learn (' .. self.skill_points .. ')', {
        MenuItem(skt[1]['name'], mapf(mkLearn, skt[1]['skills']),
                 'View the ' .. skt[1]['name'] .. " tree"),
        MenuItem(skt[2]['name'], mapf(mkLearn, skt[2]['skills']),
                 'View the ' .. skt[2]['name'] .. " tree"),
        MenuItem(skt[3]['name'], mapf(mkLearn, skt[3]['skills']),
                 'View the ' .. skt[3]['name'] .. " tree")
    }, 'Learn new skills', nil, nil, nil, checkUnspent)

    return learn
end

function Sprite:buildAttributeBox()

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
    local hp_str  = 'Hp: '  .. tostring(self.health) .. '/'
                            .. tostring(self.attributes['endurance'])
    local ign_str = 'Ign: ' .. tostring(self.ignea) .. '/'
                            .. tostring(self.attributes['focus'])
    local exp_str = 'Exp: ' .. tostring(self.exp) .. '/100'
    local icon = function(i)
        return self.icons[str_to_icon[self.skill_trees[i]['name']]]
    end
    local learnedIn = function(tn)
        local tree = self.skill_trees[tn]['skills']
        return filter(function(s) return find(self.skills, s) end, tree)
    end

    -- Build all elements
    local elements = {
        mkEle('text', {self.name}, HALF_MARGIN, line(1)),
        mkEle('text', {'Attributes'}, attrib_x, line(1)),
        mkEle('image', self.versions[self.version_name]['idle'].frames[1],
            sp_x, line(2) + 5, self.sheet),
        mkEle('text', {hp_str},
            sp_x - #hp_str * CHAR_WIDTH / 2 + self.w / 2, line(5)),
        mkEle('text', {ign_str},
            sp_x - #ign_str * CHAR_WIDTH / 2 + self.w / 2, line(6)),
        mkEle('text', {'Endurance'}, attrib_ind,       line(2)),
        mkEle('text', {'Focus'},     attrib_ind,       line(4)),
        mkEle('text', {'Force'},     attrib_ind,       line(6)),
        mkEle('text', {'Affinity'},  attrib_ind + 125, line(2)),
        mkEle('text', {'Reaction'},  attrib_ind + 125, line(4)),
        mkEle('text', {'Agility'},   attrib_ind + 125, line(6)),
        mkEle('image', self.icons[str_to_icon['endurance']],
            attrib_ind - 25,  line(2), self.itex),
        mkEle('image', self.icons[str_to_icon['focus']],
            attrib_ind - 25,  line(4), self.itex),
        mkEle('image', self.icons[str_to_icon['force']],
            attrib_ind - 25,  line(6), self.itex),
        mkEle('image', self.icons[str_to_icon['affinity']],
            attrib_ind + 100, line(2), self.itex),
        mkEle('image', self.icons[str_to_icon['reaction']],
            attrib_ind + 100, line(4), self.itex),
        mkEle('image', self.icons[str_to_icon['agility']],
            attrib_ind + 100, line(6), self.itex),
        mkEle('text', {tostring(self.attributes['endurance'])},
            attrib_ind + indent2,       line(3)),
        mkEle('text', {tostring(self.attributes['focus'])},
            attrib_ind + indent2,       line(5)),
        mkEle('text', {tostring(self.attributes['force'])},
            attrib_ind + indent2,       line(7)),
        mkEle('text', {tostring(self.attributes['affinity'])},
            attrib_ind + indent2 + 100, line(3)),
        mkEle('text', {tostring(self.attributes['reaction'])},
            attrib_ind + indent2 + 100, line(5)),
        mkEle('text', {tostring(self.attributes['agility'])},
            attrib_ind + indent2 + 100, line(7))
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
            mkEle('image', icon(1), skills_ind - 25, line(2), self.itex),
            mkEle('image', icon(2), skills_ind - 25, line(4), self.itex),
            mkEle('image', icon(3), skills_ind - 25, line(6), self.itex),
            mkEle('text', {tostring(#learnedIn(1))},
                skills_ind + indent2,       line(3)),
            mkEle('text', {tostring(#learnedIn(2))},
                skills_ind + indent2,       line(5)),
            mkEle('text', {tostring(#learnedIn(3))},
                skills_ind + indent2,       line(7))
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

-- Change the animation the sprite is performing
function Sprite:changeAnimation(new_animation_name)

    -- Get the new animation for the current version of the sprite
    local new_animation = self.versions[self.version_name][new_animation_name]

    -- Start the new animation from the beginning (if it's actually new)
    if new_animation ~= self.current_animation then
        new_animation:restart()

        -- Set the sprite's current animation to the new animation
        self.current_animation = new_animation
        self.animation_name = new_animation_name
    end
end

-- Change a sprite's version so that it is rendered
-- using a different set of animations
function Sprite:changeVersion(new_version_name)

    -- Get the animation for the new version, based on current state
    local new_animation = self.versions[new_version_name][self.animation_name]

    -- Sync the exact timing between the animations so there is no stuttering
    self.new_animation:syncWith(self.current_animation)

    -- Set the current animation to be the new animation
    self.current_animation = new_animation
    self.version_name = new_version_name
end

-- Change a sprite's behavior so that they perform different actions
function Sprite:changeBehavior(new_behavior)
    self.current_behavior = new_behavior
end

-- Change sprite to resting behavior
function Sprite:atEase()
    self:changeBehavior(self.resting_behavior)
end

function Sprite:rePath(path)
    local tmp = path[1]
    path[1] = path[2]
    path[2] = tmp
    return path
end

function Sprite:pathTo(x, y, first)
    local path = {}
    if first and first == LEFT or first == RIGHT then
        path = {RIGHT, DOWN}
        if self.x > x then
            path[1] = LEFT
        end
        if self.y > y then
            path[2] = UP
        end
    else
        path = {DOWN, RIGHT}
        if self.x > x then
            path[2] = LEFT
        end
        if self.y > y then
            path[1] = UP
        end
    end
    return path
end

-- Add new behavior functions or replace old ones for this sprite
function Sprite:addBehaviors(new_behaviors)
    for name, fxn in pairs(new_behaviors) do
        self.behaviors[name] = fxn
    end
end

function Sprite:walkToBehaviorGeneric(scene, tile_x, tile_y, label, first)
    local map = self.chapter:getMap()
    local x_dst, y_dst = map:tileToPixels(tile_x, tile_y)
    local path = self:pathTo(x_dst, y_dst, first)
    local prev_x, prev_y = -1, -1
    local since_repath = 0
    return function(dt)

        if since_repath ~= 0 then
            since_repath = since_repath - dt
        end
        if since_repath < 0 then
            since_repath = 0
            path = self:rePath(path)
        end

        local x, y = self:getPosition()
        if x == prev_x and y == prev_y then
            path = self:rePath(path)
            since_repath = 1
        end
        prev_x = x
        prev_y = y

        if (path[2] == UP and x == x_dst and y <= y_dst) or
           (path[2] == DOWN and x == x_dst and y >= y_dst) then
            self.y = y_dst
            self:resetPosition(self.x, self.y)
            self:changeBehavior('idle')
            scene:release(label)
        elseif (path[2] == LEFT and y == y_dst and x <= x_dst) or
               (path[2] == RIGHT and y == y_dst and x >= x_dst) then
            self.x = x_dst
            self:resetPosition(self.x, self.y)
            self:changeBehavior('idle')
            scene:release(label)
        else
            self:changeAnimation('walking')
            if path[1] == UP then
                if y <= y_dst then
                    self.y = y_dst
                    self.dy = 0
                    self.dx = WANDER_SPEED * path[2]
                    self.dir = path[2]
                else
                    self.dx = 0
                    self.dy = -WANDER_SPEED
                    self.dir = path[2]
                end
            elseif path[1] == DOWN then
                if y >= y_dst then
                    self.y = y_dst
                    self.dy = 0
                    self.dx = WANDER_SPEED * path[2]
                    self.dir = path[2]
                else
                    self.dx = 0
                    self.dy = WANDER_SPEED
                    self.dir = path[2]
                end
            elseif path[1] == LEFT then
                if x <= x_dst then
                    self.x = x_dst
                    self.dx = 0
                    self.dy = WANDER_SPEED * ite(path[2] == DOWN, 1, -1)
                else
                    self.dy = 0
                    self.dx = -WANDER_SPEED
                    self.dir = LEFT
                end
            elseif path[1] == RIGHT then
                if x >= x_dst then
                    self.x = x_dst
                    self.dx = 0
                    self.dy = WANDER_SPEED * ite(path[2] == DOWN, 1, -1)
                else
                    self.dy = 0
                    self.dx = WANDER_SPEED
                    self.dir = RIGHT
                end
            end
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
end

-- Sprite idle behavior
function Sprite:_idleBehavior(dt)
    self:stop()
    self:changeAnimation('idle')
end

-- Sprite idle behavior
function Sprite:_battleBehavior(dt)
    self:stop()
    self:changeAnimation('walking')
end

-- Check whether a sprite is on a tile and return displacement
function Sprite:onTile(x, y)

    -- Check if the tile matches the tile at any corner of the sprite
    local map = self.chapter:getMap()

    -- Check northwest tile
    local match, new_x, new_y = map:pixelOnTile(self.x, self.y, x, y)
    if match then
        return true, new_x, new_y
    end

    -- Check northeast tile
    match, new_x, new_y = map:pixelOnTile(self.x + self.w, self.y, x, y)
    if match then
        return true, new_x - self.w, new_y
    end

    -- Check southwest tile
    match, new_x, new_y = map:pixelOnTile(self.x, self.y + self.h, x, y)
    if match then
        return true, new_x, new_y - self.h
    end

    -- Check southeast tile
    match, new_x, new_y = map:pixelOnTile(self.x + self.w,
                                          self.y + self.h, x, y)
    if match then
        return true, new_x - self.w, new_y - self.h
    end

    -- Return nil if no match
    return false, nil, nil
end

-- Check if the given sprite is within an offset distance to self
function Sprite:AABB(sp, offset)
    local x_inside = (self.x < sp.x + sp.w + offset) and
                     (self.x + self.w > sp.x - offset)
    local y_inside = (self.y < sp.y + sp.h + offset) and
                     (self.y + self.h > sp.y - offset)
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
    for _, sp in ipairs(self.chapter:getActiveSprites()) do
        if sp.name ~= self.name and sp.blocking then

            -- Collision from right or left of target
            local x_move = nil
            local y_inside = (self.y < sp.y + sp.h) and (self.y + self.h > sp.y)
            local right_dist = self.x - (sp.x + sp.w)
            local left_dist = sp.x - (self.x + self.w)
            if y_inside and right_dist <= 0 and
               right_dist > -sp.w/2 and self.dx < 0 then
                x_move = sp.x + sp.w
            elseif y_inside and left_dist <= 0 and
                   left_dist > -sp.w/2 and self.dx > 0 then
                x_move = sp.x - self.w
            end

            -- Collision from below target or above target
            local y_move = nil
            local x_inside = (self.x < sp.x + sp.w) and (self.x + self.w > sp.x)
            local down_dist = self.y - (sp.y + sp.h)
            local up_dist = sp.y - (self.y + self.h)
            if x_inside and down_dist <= 0 and
               down_dist > -sp.h/2 and self.dy < 0 then
                y_move = sp.y + sp.h
            elseif x_inside and up_dist <= 0 and
                   up_dist > -sp.h/2 and self.dy > 0 then
                y_move = sp.y - self.h
            end

            -- Perform shorter move
            if x_move and y_move then
                if abs(x_move - self.x) < abs(y_move - self.y) then
                    self.x = x_move
                else
                    self.y = y_move
                end
            elseif x_move then
                self.x = x_move
            elseif y_move then
                self.y = y_move
            end
        end
    end
end

-- Handle map collisions for this sprite
function Sprite:_checkMapCollisions()

    -- Convenience variables
    local map = self.chapter:getMap()
    local h = self.h
    local w = self.w

    -- Check all surrounding tiles
    local above_left = map:collides(map:tileAt(self.x, self.y - 1))
    local above_right = map:collides(map:tileAt(self.x + w - 1, self.y - 1))

    local below_left = map:collides(map:tileAt(self.x, self.y + h))
    local below_right = map:collides(map:tileAt(self.x + w - 1, self.y + h))

    local right = map:collides(map:tileAt(self.x + w, self.y + h / 2))
    local right_above = map:collides(map:tileAt(self.x + w, self.y))
    local right_below = map:collides(map:tileAt(self.x + w, self.y + h - 1))

    local left = map:collides(map:tileAt(self.x - 1, self.y + h / 2))
    local left_above = map:collides(map:tileAt(self.x - 1, self.y))
    local left_below = map:collides(map:tileAt(self.x - 1, self.y + h - 1))

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
        local y_move = map:tileAt(self.x, self.y - 1).y * TILE_HEIGHT
        if abs(y_move - self.y) <= 3 then
            self.y = y_move
        end
    elseif below_condition then
        local y_move = (map:tileAt(self.x, self.y + h).y - 1) * TILE_HEIGHT - h
        if abs(y_move - self.y) <= 3 then
            self.y = y_move
        end
    end

    -- perform left-right move if it's small enough
    if left_condition then
        local x_move = map:tileAt(self.x - 1, self.y).x * TILE_WIDTH
        if abs(x_move - self.x) <= 3 then
            self.x = x_move
        end
    elseif right_condition then
        local x_move = (map:tileAt(self.x + w, self.y).x - 1) * TILE_WIDTH - w
        if abs(x_move - self.x) <= 3 then
            self.x = x_move
        end
    end
end

-- Update rendered frame of animation
function Sprite:updateAnimation(dt)
    self.current_animation:update(dt)
    self.on_frame = self.current_animation:getCurrentFrame()
end

-- Update sprite's position from dt
function Sprite:updatePosition(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

-- Per-frame updates to a sprite's state
function Sprite:update(dt)

    -- Update velocity, direction, behavior,
    -- and animation based on current behavior
    self.behaviors[self.current_behavior](dt)

    -- Update frame of animation
    self:updateAnimation(dt)

    -- Update position based on velocity
    self:updatePosition(dt)

    -- Handle collisions with walls or other sprites
    if self.blocking then
        self:checkCollisions()
    end
end

-- Render a sprite to the screen
function Sprite:render(cam_x, cam_y)

    -- Draw sprite's current animation frame, at its current position,
    -- in its current direction
    love.graphics.draw(
        self.sheet,
        self.on_frame,
        self.x + self.w / 2,
        self.y + self.h / 2,
        0,
        self.dir,
        1,
        self.w / 2,
        self.h / 2
    )
end
