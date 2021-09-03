require 'Util'
require 'Constants'

Animation = Class{}

-- Class constants
local ANIMATION_SPEED = 6.5

-- Initialize a new set of frames
function Animation:init(frames)

    -- Time per frame and total time elapsed
    self.interval = 1 / ANIMATION_SPEED
    self.timer = 0

    -- Images corresponding to each frame, index into frames
    self.frames = frames
    self.current_frame = 1

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
end

-- Sync this animation with a different animation
function Animation:syncWith(previous)
    self.timer = previous.timer
    self.current_frame = previous.current_frame
end

-- Increment time and move to the appropriate frame
function Animation:update(dt)

    -- Freeze if doneAction was fired
    if self.firedDoneAction then return end

    -- Update time passed
    self.timer = self.timer + dt

    -- Iteratively subtract interval from timer
    while self.timer > self.interval do
        self.timer = self.timer - self.interval
        self.current_frame = (self.current_frame + 1) % (#self.frames + 1)
        if self.current_frame == 0 then
            self.current_frame = 1
            if self.doneAction then
                self.current_frame = #self.frames
                local action = self.doneAction
                self.firedDoneAction = true
                action()
                return
            end
        end
    end
end

function Animation:setDoneAction(doneAction)
    self.doneAction = doneAction
end
