require 'src.Util'
require 'src.Constants'

require 'src.Chapter'

Game = class('Game')

-- Initialize game context
function Game:initialize(chapter)
    self.chapter = chapter
end
