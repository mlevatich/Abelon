require 'src.Util'
require 'src.Constants'

Animation = class('Animation')

-- Initialize a new set of frames
function Animation:initialize(id, frames, anim_sfx, speed)

    self.id = id

    -- Time per frame and total time elapsed
    self.interval = 1 / speed
    self.timer = 0

    -- Images corresponding to each frame, index into frames
    self.frames = frames
    self.current_frame = 1

    -- Optional audio effect
    self.anim_sfx = anim_sfx
    self.playedSfx = false

    self.doneAction = nil
    self.firedDoneAction = false
end

-- Return the current quad to render
function Animation:getCurrentFrame()
    return self.frames[self.current_frame]
end

-- Start over the animation
function Animation:restart()
    self.timer = 0
    self.current_frame = 1
    self.doneAction = nil
    self.firedDoneAction = false
    self.playedSfx = false
end

-- Sync this animation with a different animation
function Animation:syncWith(previous)
    self.timer = previous.timer
    self.current_frame = previous.current_frame
end

-- Increment time and move to the appropriate frame
function Animation:update(dt, src_sp, g)

    -- Freeze if doneAction was fired
    if self.firedDoneAction then return end

    -- Update time passed
    self.timer = self.timer + dt

    -- Play sfx if it exists and hasn't been played
    if self.anim_sfx and not self.playedSfx then
        local mod = nil
        if src_sp and g then
            local hearing = 300
            local center_x = g.camera_x + (VIRTUAL_WIDTH / ZOOM) / 2
            local center_y = g.camera_y + (VIRTUAL_HEIGHT / ZOOM) / 2
            local xd = center_x - (src_sp.x + src_sp.w / 2)
            local yd = center_y - (src_sp.y + src_sp.h / 2)
            local dist_sq = xd * xd + yd * yd
            mod = math.max(0, math.min(1, (hearing * hearing - dist_sq) / (hearing * hearing)))
        end
        self.anim_sfx:play(mod)
        self.playedSfx = true
    end

    -- Iteratively subtract interval from timer
    while self.timer > self.interval do
        self.timer = self.timer - self.interval
        self.current_frame = (self.current_frame + 1) % (#self.frames + 1)
        if self.current_frame == 0 then
            self.current_frame = 1
            if self.doneAction then
                self:fireDoneAction()
                return
            end
            self.playedSfx = false
        end
    end
end

function Animation:fireDoneAction()
    if self.doneAction and not self.firedDoneAction then
        self.current_frame = #self.frames
        local action = self.doneAction
        self.firedDoneAction = true
        action()
    end
end

function Animation:setDoneAction(doneAction)
    self.doneAction = doneAction
end
