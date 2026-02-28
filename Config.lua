-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode 
-- File: Config.lua
-- Version: 11
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in 
-- derivative works without express written permission.
-------------------------------------------------------------------------------
local addonName, NS = ...

-- Initialize the shared AddOn table
NS.AN = {}
local AN = NS.AN

-- ----------------------------------------------------------------------------
-- CONSTANTS & DEFAULTS
-- ----------------------------------------------------------------------------

AN.CONSTANTS = {
    PADDING = 5,
    SIDEBAR_WIDTH = 180,
    CARD_HEIGHT = 40,
    CARD_WIDTH = 530,
    MAX_COLUMNS = 1,
}

AN.COLORS = {
    -- Window & Backgrounds
    bg              = {0.15, 0.15, 0.15, 0.95},
    window_border   = {0.00, 0.00, 0.00, 1},
    
    -- Sidebar
    sidebar_bg      = {0.10, 0.10, 0.10, 0.95},
    sidebar_hover   = {0.20, 0.20, 0.20, 0.5},
    sidebar_accent  = {0.00, 0.48, 1.00, 0.95},
    sidebar_active  = {0.00, 0.40, 1.00, 0.2},
    
    -- Inputs
    input_bg        = {0.00, 0.00, 0.00, 0.95},
    input_border    = {0.50, 0.50, 0.50, 1},
    input_focus     = {0.00, 0.80, 1.00, 1},
    
    -- Cards
    card_bg         = {0.22, 0.22, 0.22, 0.95},
    card_border     = {0.10, 0.10, 0.10, 0.95},
    card_hover      = {1.00, 1.00, 1.00, 0.95},
    
    -- Buttons
    btn_normal      = {0.20, 0.20, 0.20, 1},
    btn_primary     = {0.00, 0.45, 0.90, 1},
    btn_danger      = {0.80, 0.10, 0.10, 1},
    btn_border      = {0.00, 0.00, 0.00, 1},
    
    -- Menus
    menu_bg         = {0.20, 0.20, 0.20, 0.95},
    
    -- Text
    text_title      = {1.00, 1.00, 1.00, 1},
    text_normal     = {1.00, 1.00, 1.00, 1},
    text_body       = {0.95, 0.95, 0.95, 1},
    text_dim        = {0.80, 0.80, 0.80, 1},
    text_tag        = {0.40, 0.90, 1.00, 1},
    text_highlight  = {1.00, 1.00, 0.00, 1},
}

AN.TEMPLATES = {
    { name = "To-Do List", body = "- [ ] \n- [ ] \n- [ ] " },
    { name = "M+ Strategy", body = "Dungeon: \nKeys: \n\n[ ] Tank Route\n[ ] Lust on Boss:" },
    { name = "Raid Notes", body = "Boss: \n\nPhase 1 Position:\nPhase 2 Position:\nCooldowns:" },
}

AN.DefaultDB = {
    notes = {},
    categories = { "Personal", "Dungeon", "Raids", "AH/Gold" },
    bindings = {
        toggle = "NONE",
        newNote = "NONE"
    }
}
