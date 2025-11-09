-- Constants.lua
-- P2-4: Centralized constants file to eliminate magic numbers
-- Single source of truth for all game constants

local Constants = {}

-- ========================================
-- SHOP LIMITS
-- ========================================
Constants.SHOP = {
    MAX_PURCHASE_QUANTITY = 999,
    MAX_SALE_QUANTITY = 999,
    MIN_PURCHASE_QUANTITY = 1,
    CLIENT_MAX_QUANTITY_DISPLAY = 99, -- UI limit (different from server limit)
}

-- ========================================
-- INVENTORY LIMITS
-- ========================================
Constants.INVENTORY = {
    MAX_INVENTORY_SIZE = 200,
    MAX_STACK_SIZE = 999,
}

-- ========================================
-- PLOT SYSTEM
-- ========================================
Constants.PLOT = {
    INTERACTION_DISTANCE = 25, -- studs
    INTERACTION_COOLDOWN = 0.5, -- seconds
    CLIENT_CLICK_DISTANCE = 15, -- studs (for ClickDetector)
    CLIENT_COOLDOWN = 0.5, -- seconds (client-side)
    PROGRESS_BAR_HEIGHT_OFFSET = 3, -- studs above plot
}

-- ========================================
-- UI POSITIONING
-- ========================================
Constants.UI = {
    TOOLTIP_Y_OFFSET = 120, -- pixels
    NOTIFICATION_DURATION = 3, -- seconds
    NOTIFICATION_Y_POSITION = -70, -- pixels from top
    NOTIFICATION_ANIMATION_Y = 20, -- pixels (slide distance)
}

-- ========================================
-- ANIMATION
-- ========================================
Constants.ANIMATION = {
    DEFAULT_TWEEN_DURATION = 0.3, -- seconds
    FAST_TWEEN_DURATION = 0.15, -- seconds
    SLOW_TWEEN_DURATION = 0.5, -- seconds
    CURRENCY_UPDATE_DURATION = 0.5, -- seconds
    PULSE_DURATION = 0.15, -- seconds
    HARVEST_DELAY = 0.5, -- seconds
}

-- ========================================
-- RATE LIMITING
-- ========================================
Constants.RATE_LIMIT = {
    REQUESTS_PER_SECOND = 5,
}

-- ========================================
-- SPIRIT SYSTEM
-- ========================================
Constants.SPIRIT = {
    COLLECT_COOLDOWN = 1.0, -- seconds
    MAX_ACTIVE = 8,
    MIN_SPAWN_DISTANCE = 15, -- studs (anti-clustering)
    SPAWN_ATTEMPTS = 5, -- max retries for finding spawn position
}

-- ========================================
-- ANTI-CHEAT
-- ========================================
Constants.ANTICHEAT = {
    MAX_LOG_BUFFER = 1000, -- in-memory log entries
    LARGE_PURCHASE_THRESHOLD = 100, -- quantity threshold for logging
}

-- ========================================
-- COLORS (Common UI Colors)
-- ========================================
Constants.COLORS = {
    -- Currency
    COINS = Color3.fromRGB(255, 220, 100),
    DREAM_SEEDS = Color3.fromRGB(150, 180, 255),
    
    -- Day/Night
    DAY = Color3.fromRGB(255, 200, 50),
    NIGHT = Color3.fromRGB(100, 150, 255),
    
    -- Notifications
    SUCCESS = Color3.fromRGB(80, 200, 120),
    ERROR = Color3.fromRGB(255, 100, 100),
    INFO = Color3.fromRGB(100, 150, 255),
    WARNING = Color3.fromRGB(255, 180, 50),
    SPIRIT = Color3.fromRGB(180, 120, 255),
    
    -- UI Elements
    WHITE = Color3.fromRGB(255, 255, 255),
    GRAY = Color3.fromRGB(150, 150, 150),
    DARK_GRAY = Color3.fromRGB(50, 50, 60),
    LIGHT_GRAY = Color3.fromRGB(200, 200, 200),
    TOOLTIP_BG = Color3.fromRGB(25, 25, 35),
}

-- ========================================
-- PLOT VISUALIZER
-- ========================================
Constants.PLOT_VISUALIZER = {
    PROGRESS_BAR_SIZE = UDim2.new(3, 0, 0.3, 0),
    PROGRESS_BAR_BG_COLOR = Color3.fromRGB(30, 30, 30),
    PROGRESS_BAR_FILL_COLOR = Color3.fromRGB(80, 200, 120),
    PROGRESS_BAR_FONT = Enum.Font.GothamBold,
    PROGRESS_BAR_TEXT_SIZE = 18,
    
    -- Particle effects
    WATER_PARTICLE_COLOR = Color3.fromRGB(100, 150, 255),
    HARVEST_PARTICLE_COLOR = Color3.fromRGB(255, 215, 0),
    HARVEST_PARTICLE_SIZE = 0.5,
    HARVEST_PARTICLE_LIFETIME = {0.5, 1.5},
}

-- ========================================
-- DEBUG
-- ========================================
Constants.DEBUG = {
    MODE = false,
    VERBOSE_LOGGING = false,
}

return Constants

