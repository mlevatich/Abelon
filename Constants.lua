-- True false
T = true
F = false

-- Parsing variables
VAL = 1
ARR = 2

-- Dimensions of a tile
TILE_WIDTH     = 32
TILE_HEIGHT    = 32

-- Actual window resolution
WINDOW_WIDTH   = 1280
WINDOW_HEIGHT  = 720

-- Apparent game resolution
VIRTUAL_WIDTH  = 864
VIRTUAL_HEIGHT = 486

-- Text variables
FONT           = 'VT323-Regular'
FONT_SIZE      = 16
PORTRAIT_SIZE  = 120
BOX_MARGIN     = 20
TEXT_MARGIN_X  = -7
TEXT_MARGIN_Y  = 5
LINES_PER_PAGE = 3
TEXT_INTERVAL  = 0.03
MAX_MENU_ITEMS = 5
RECT_ALPHA     = 0.4
HBOX_WIDTH     = 540
DISABLE        = { 1, 1, 1, 0.5 }
HIGHLIGHT      = { 0.7, 1, 1, 1 }

-- Derived text variables
LINE_HEIGHT = FONT_SIZE + TEXT_MARGIN_Y
CHAR_WIDTH = FONT_SIZE + TEXT_MARGIN_X
HALF_MARGIN = BOX_MARGIN / 2
HBOX_HEIGHT = BOX_MARGIN + LINE_HEIGHT + PORTRAIT_SIZE
BOX_WIDTH = VIRTUAL_WIDTH - (BOX_MARGIN * 2)
CHARS_PER_LINE = math.floor(
    (BOX_WIDTH - BOX_MARGIN - PORTRAIT_SIZE) / CHAR_WIDTH
)
HBOX_CHARS_PER_LINE = math.floor(
    (HBOX_WIDTH - BOX_MARGIN * 2 - PORTRAIT_SIZE) / CHAR_WIDTH
)
CBOX_CHARS_PER_LINE = 30
BOX_HEIGHT = TEXT_MARGIN_Y * (LINES_PER_PAGE + 3)
           + FONT_SIZE * LINES_PER_PAGE
           + BOX_MARGIN


-- Direction enum
LEFT  = -1
RIGHT = 1
UP    = 3
DOWN  = 4

-- Difficulty
NORMAL = 1
ADEPT  = 2
MASTER = 3

-- Skill types
ASSIST = 7
WEAPON = 8
SPELL  = 9

str_to_icon = {
    ['Demon'] = 1,
    ['Champion'] = 2,
    ['Executioner'] = 3,
    ['Defender'] = 4,
    ['Hero'] = 5,
    ['Cleric'] = 6,
    ['endurance'] = 10,
    ['focus'] = 11,
    ['force'] = 12,
    ['affinity'] = 13,
    ['reaction'] = 14,
    ['agility'] = 15,
    ['Enemy'] = 16,
    ['empty'] = 18
}

-- Aim types/targets
DIRECTIONAL = 1
SELF_CAST   = 2
FREE        = 3
DIRECTIONAL_AIM = { ['type'] = DIRECTIONAL }
SELF_CAST_AIM   = { ['type'] = SELF_CAST }
FREE_AIM        = function(s, t)
                      return { ['type'] = FREE, ['scale'] = s, ['target'] = t }
                  end
ALL   = 4
ALLY  = 5
ENEMY = 6
BEGIN = 7

-- Win/lose conditions
ROUT = function(b) return true end

-- Battle stages
STAGE_FREE   = 1
STAGE_MOVE   = 2
STAGE_MENU   = 3
STAGE_TARGET = 4
STAGE_WATCH  = 5
STAGE_BUBBLE = 6

-- View options
BEFORE  = 1
AFTER   = 2
PERSIST = 1
TEMP    = 2

-- Volume Levels
OFF  = 0
LOW  = 0.33
MED  = 0.66
HIGH = 1

-- Misc
PRESENT_DISTANCE = 4

-- Trigger vars
DELETE = '__del__'
