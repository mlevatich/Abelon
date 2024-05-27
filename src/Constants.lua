-- debug flag
debug = false

-- True false
T = true
F = false

-- Parsing variables
VAL = 1
ARR = 2

-- Dimensions of a tile
TILE_WIDTH  = 32
TILE_HEIGHT = 32

-- Width and height of game camera in pixels
ZOOM           = 1.4
VIRTUAL_WIDTH  = 864
VIRTUAL_HEIGHT = 486
ZOOM_WIDTH     = VIRTUAL_WIDTH  / ZOOM
ZOOM_HEIGHT    = VIRTUAL_HEIGHT / ZOOM

-- Video data
FPS_TARGET = 60
FRAME_DUR = 1 / FPS_TARGET

-- Saving and reloading constants
SAVE_DIRECTORY = 'data/savedata/'
AUTO_SAVE      = 'save.dat'
QUICK_SAVE     = 'quicksave.dat'
BATTLE_SAVE    = 'battle_save.dat'
CHAPTER_SAVE   = 'chapter_save.dat'
RELOAD_BATTLE  = 0
RELOAD_CHAPTER = 1
END_CHAPTER    = 2

-- Font variables
FONT            = 'VT323-Regular'
FONT_FILE       = 'graphics/fonts/' .. FONT .. '.ttf'
FONT_SIZE       = 16
TITLE_FONT_SIZE = 40
EXP_FONT_SIZE   = 14
SUBFONT_SIZE    = 18
EXP_FONT        = love.graphics.newFont(FONT_FILE, EXP_FONT_SIZE)

-- Text variables
PORTRAIT_SIZE   = 120
BOX_MARGIN      = 20
TEXT_MARGIN_X   = -7
TEXT_MARGIN_Y   = 5
LINES_PER_PAGE  = 3
TEXT_INTERVAL   = 0.03
MAX_MENU_ITEMS  = 6
SUB_MENU_ITEMS  = 5
RECT_ALPHA      = 0.6
OUTLINE_ALPHA   = 0.0
HBOX_WIDTH      = 540
MAX_WORD        = 14

-- Derived text variables
LINE_HEIGHT = FONT_SIZE + TEXT_MARGIN_Y
CHAR_WIDTH = FONT_SIZE + TEXT_MARGIN_X
HALF_MARGIN = BOX_MARGIN / 2
HBOX_HEIGHT = BOX_MARGIN + LINE_HEIGHT + PORTRAIT_SIZE
BOX_WIDTH = VIRTUAL_WIDTH - (BOX_MARGIN * 2)
CHARS_PER_LINE = math.floor(
    (BOX_WIDTH - BOX_MARGIN * 2 - PORTRAIT_SIZE) / CHAR_WIDTH
)
HBOX_CHARS_PER_LINE = math.floor(
    (HBOX_WIDTH - BOX_MARGIN * 2 - PORTRAIT_SIZE) / CHAR_WIDTH
)
CBOX_CHARS_PER_LINE = 27
BOX_HEIGHT = TEXT_MARGIN_Y * (LINES_PER_PAGE + 3)
           + FONT_SIZE * LINES_PER_PAGE
           + BOX_MARGIN

-- Text colors
DISABLE           = { 1,     1,   1, 0.5 }
HIGHLIGHT         = { 0.7,   1,   1,   1 }
RED               = { 1,   0.7, 0.7,   1 }
GREEN             = { 0.7,   1, 0.7,   1 }
WHITE             = {0.95,0.95,0.95, 1.0 }
AUTO_COLOR        = {
    ['Weapon']    = {   1,   1, 0.5,   1 }, -- Yellow
    ['Spell']     = { 0.8, 0.4,   1,   1 }, -- Purple
    ['Assist']    = { 0.7,   1, 0.7,   1 }, -- Light green
    ['Endurance'] = { 0.3, 0.3,   1,   1 }, -- Blue
    ['Focus']     = {   1, 0.2, 0.2,   1 }, -- Red
    ['Force']     = {   1, 0.6, 0.2,   1 }, -- Orange
    ['Affinity']  = { 0.6,   1, 0.2,   1 }, -- Yellow green
    ['Reaction']  = { 0.2, 0.7, 0.4,   1 }, -- Dark green
    ['Agility']   = { 0.2, 0.7,   1,   1 }, -- Light blue
}

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
ASSIST = 1
WEAPON = 2
SPELL  = 3
str_to_icon = {
    ['endurance'] = 4,
    ['focus'] = 5,
    ['force'] = 6,
    ['affinity'] = 7,
    ['reaction'] = 8,
    ['agility'] = 9,
    ['Enemy'] = 10,
    ['Demon'] = 11,
    ['Veteran'] = 12,
    ['Executioner'] = 13,
    ['Defender'] = 14,
    ['Hero'] = 15,
    ['Cleric'] = 16,
    ['Huntress'] = 17,
    ['Apprentice'] = 18,
    ['Sniper'] = 19,
    ['empty'] = 21
}

EFFECT_NAMES = {
    ['guardian_angel'] = "Resist Death",
    ['forbearance']    = "Kath's Shield",
    ['enrage']         = "Targeting Kath",
    ['stun']           = "Stunned",
    ['observe']        = "Observing",
    ['hidden']         = "Hidden",
    ['flight']         = "Flight",
    ['flanking']       = "Flanking"
}

ATTRIBUTE_DESC = {
    {
        ['id'] = 'endurance', ['name'] = 'Endurance',
        ['desc'] = "Withstand anything and everything. Every point of \z
        Endurance raises the character's maximum health by two."
    },
    {
        ['id'] = 'focus', ['name'] = 'Focus',
        ['desc'] = "Intense concentration is the core of ignaeic aptitude. \z
        Every point of Focus raises the character's maximum ignea by one."
    },
    {
        ['id'] = 'force', ['name'] = 'Force',
        ['desc'] = "Channel destructive intent. High Force improves many \z
        offensive Weapon and Spell skills."
    },
    {
        ['id'] = 'affinity', ['name'] = 'Affinity',
        ['desc'] = "Connect to and synergize with allies. High Affinity \z
        amplifies the effects of many Assist skills."
    },
    {
        ['id'] = 'reaction', ['name'] = 'Reaction',
        ['desc'] = "Stay alert. Turn deadly strikes into glancing blows. \z
        Each point of Reaction reduces received Weapon damage by one."
    },
    {
        ['id'] = 'agility', ['name'] = 'Agility',
        ['desc'] = "Adapt fast and move faster. Every four points of \z
        Agility grants the character one space of movement in battle."
    }
}

TUTORIALS = {
    ['Navigating the world'] = {
        "Move around the world using the arrow keys. Press F to interact with nearby objects or people, and advance dialogue. Press D to cancel.",
        "Press E to open your inventory, where you can use items, inspect your party, change settings, and read tutorials."
    },
    ['Battle: The basics'] = {
        "Use the arrow keys to navigate the grid and menus. Press F to select, and D to go back.",
        "Select an enemy to view its information. Select an ally to move them, use a skill, finish moving, and confirm.",
        "Aim a Weapon or Spell at an enemy to damage it."
    },
    ['Battle: Turns'] = {
        "Each ally may act once during the ally phase. Once all allies have acted, the enemies will move and attack you. Then the next turn begins.",
        "A unit dies when their health reaches zero. Keep your allies alive and defeat all enemies to win the battle."
    },
    ['Battle: Assists'] = {
        "After moving and using a Weapon or Spell, an ally may use an Assist on some tiles.",
        "Until the next ally phase, any ally on an assisted tile benefits from the Assist effects, calculated from the caster's attributes. A tile may have multiple assists."
    },
    ['Battle: Ignea'] = {
        "Many powerful skills consume Ignea, shown as their 'Cost'. Ignea is a precious stone, and each unit has a limited supply.",
        "To recover Ignea, you will have to find it on your journey. On %s difficulty, %s is restored after battle."
    },
    ['Battle: Attributes'] = {
        "Units have six Attributes. Endurance determines maximum health, and Focus determines maximum Ignea.",
        "Force empowers attacks, and Affinity empowers assists.",
        "A point of Reaction reduces Weapon damage by one. Four points of Agility confers one tile of movement."
    },
    ['Battle: Reminder'] = {
        "All battle tutorials are available for review under 'Tutorials' in the settings menu.",
        "To access the settings and other information during battle, select any empty tile."
    },
    ['Experience and skill learning'] = {
        "By battling, units gain experience and level up, granting attributes and a skill point.",
        "Spend your skill points in the party menu to learn new skills, if you meet their requirements."
    },
    ['Using and presenting items'] = {
        "In some situations, it may be appropriate to use an item or cast a spell on a particular location or target.",
        "Move close to the target and open your inventory. Navigate to the spell or item and 'Use' it.",
        "To show an item to someone, select 'Present'."
    }
}

-- Battle enums
DIRECTIONAL = 1
SELF_CAST   = 2
FREE        = 3
ALL         = 4
ALLY        = 5
ENEMY       = 6
SELECT      = 7
END_ACTION  = 8
DIRECTIONAL_AIM = { ['type'] = DIRECTIONAL }
SELF_CAST_AIM   = { ['type'] = SELF_CAST }
FREE_AIM        = function(s) return { ['type'] = FREE, ['scale'] = s } end

-- Buff or debuff?
BUFF   = 1
DEBUFF = 2

-- Skill targeting algorithms (for enemies)
CLOSEST   = 1
KILL      = 2 -- Invert when targeting allies (heal closest to death)
DAMAGE    = 3 -- Invert when targeting allies (biggest heal)
STRONGEST = 4 -- Invert when targeting allies (heal strongest ally)
MANUAL    = 5 -- For the player team
FORCED    = 6

-- Skill animation enum
SKILL_ANIM_GRID     = 1
SKILL_ANIM_RELATIVE = 2
SKILL_ANIM_NONE     = 3

-- Experience
EXP_STATUS_MAX  = 20
EXP_ON_SPECIAL  = 10
EXP_ON_ATTACKED = 6
EXP_ON_KILL     = 10
EXP_FOR_ASSIST  = 5
EXP_HEAL_RATIO  = 0.5
EXP_DMG_RATIO   = 0.75

EXP_TAG_ATTACK  = 1
EXP_TAG_ASSIST  = 2
EXP_TAG_RECV    = 3
EXP_TAG_MOVE    = 4

-- Battle stages
STAGE_FREE    = 1
STAGE_MOVE    = 2
STAGE_MENU    = 3
STAGE_TARGET  = 4
STAGE_WATCH   = 5
STAGE_LEVELUP = 6
STAGE_BUBBLE  = 7

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
PRESENT_DISTANCE = 2
GROUND_DEPTH = 6
T_BYLINE = 4.5
M_GAME = 0
M_DIFF = 1
M_CONF = 2

-- Trigger vars
DELETE = '__del__'
