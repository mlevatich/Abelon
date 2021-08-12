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
FONT_SIZE      = 20
PORTRAIT_SIZE  = 120
BOX_MARGIN     = 20
TEXT_MARGIN_X  = -5
TEXT_MARGIN_Y  = 10
LINES_PER_PAGE = 4
TEXT_INTERVAL  = 0.03

-- Derived text variables
BOX_WIDTH = VIRTUAL_WIDTH - (BOX_MARGIN * 2)
CHARS_PER_LINE = math.floor(
    (BOX_WIDTH - BOX_MARGIN * 2 - PORTRAIT_SIZE) / (TEXT_MARGIN_X + FONT_SIZE)
)
BOX_HEIGHT = TEXT_MARGIN_Y * (LINES_PER_PAGE + 2)
           + FONT_SIZE * LINES_PER_PAGE
           + BOX_MARGIN

-- Direction enum
LEFT  = -1
RIGHT = 1
UP    = 3
DOWN  = 4
