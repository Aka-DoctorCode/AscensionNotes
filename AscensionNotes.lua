-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode 
-- File: AscensionNotes.lua
-- Version: 12.0.0
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in 
-- derivative works without express written permission.
-------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- NAMESPACE & CONSTANTS
-- ----------------------------------------------------------------------------
local addonName, NS = ...
local AN = {} 

-- ----------------------------------------------------------------------------
-- VISUAL CONFIGURATION
-- ----------------------------------------------------------------------------

-- Layout Constants (LIST VIEW)
local PADDING = 5
local SIDEBAR_WIDTH = 180 
local CARD_HEIGHT = 40      
local CARD_WIDTH = 530      
local MAX_COLUMNS = 1       

-- CENTRALIZED COLOR PALETTE
local COLORS = {
    -- Window & Backgrounds
    bg              = {0.15, 0.15, 0.15, 0.95},   
    window_border   = {0.00, 0.00, 0.00, 1}, 
    
    -- Sidebar
    sidebar_bg      = {0.10, 0.10, 0.10, 0.95},   
    sidebar_hover   = {0.20, 0.20, 0.20, 0.5}, 
    sidebar_accent  = {0.00, 0.48, 1.00, 0.95},   
    sidebar_active  = {0.00, 0.40, 1.00, 0.2}, 
    
    -- Inputs (Text Boxes)
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
    
    -- Text Colors
    text_title      = {1.00, 1.00, 1.00, 1},   
    text_normal     = {1.00, 1.00, 1.00, 1},   
    text_body       = {0.95, 0.95, 0.95, 1},   
    text_dim        = {0.80, 0.80, 0.80, 1},   
    text_tag        = {0.40, 0.90, 1.00, 1},   
    text_highlight  = {1.00, 1.00, 0.00, 1},   
}

local TEMPLATES = {
    { name = "To-Do List", body = "- [ ] \n- [ ] \n- [ ] " },
    { name = "M+ Strategy", body = "Dungeon: \nKeys: \n\n[ ] Tank Route\n[ ] Lust on Boss:" },
    { name = "Raid Notes", body = "Boss: \n\nPhase 1 Position:\nPhase 2 Position:\nCooldowns:" },
}

local defaultDB = {
    notes = {}, 
    categories = { "Work", "Personal", "Dungeon", "Raids", "AH/Gold" },
    bindings = {
        toggle = "NONE",
        newNote = "NONE"
    }
}

AN.currentFilter = nil 
AN.searchQuery = ""

-- ----------------------------------------------------------------------------
-- UI HELPERS
-- ----------------------------------------------------------------------------

local function CopyTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then dest[k] = CopyTable(v, dest[k]) else dest[k] = v end
        end
    end
    return dest
end

local function GenerateID()
    return GetTime() .. "-" .. random(1000, 9999)
end

function AN:CreateStyledButton(parent, text, colorType)
    if not parent then return nil end

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2 
    })
    
    local normalColor = COLORS.btn_normal
    if colorType == "primary" then normalColor = COLORS.btn_primary end
    if colorType == "danger" then normalColor = COLORS.btn_danger end
    
    btn:SetBackdropColor(unpack(normalColor))
    btn:SetBackdropBorderColor(unpack(COLORS.btn_border)) 
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    
    btn:SetScript("OnEnter", function(self)
        local r, g, b = unpack(normalColor)
        self:SetBackdropColor(r + 0.15, g + 0.15, b + 0.15, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(normalColor))
    end)
    
    return btn
end

function AN:StyleInputBox(editBox)
    if not editBox then return end
    
    -- FIX: Removed quotes around GameFontHighlightHuge to pass the object, not the string name
    if GameFontHighlightHuge then
        editBox:SetFontObject(GameFontHighlightHuge)
    else
        -- Fallback if specific font is missing
        editBox:SetFontObject(GameFontHighlight)
    end
    
    editBox:SetTextColor(unpack(COLORS.text_normal)) 
    editBox:SetTextInsets(8, 8, 2, 2) 
    
    if not editBox.bg then
        local bg = CreateFrame("Frame", nil, editBox, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", -2, 2)
        bg:SetPoint("BOTTOMRIGHT", 2, -2)
        
        bg:SetFrameLevel(math.max(1, editBox:GetFrameLevel() - 1))
        
        bg:SetBackdrop({ 
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            edgeFile = "Interface\\Buttons\\WHITE8x8", 
            edgeSize = 2
        })
        
        bg:SetBackdropColor(unpack(COLORS.input_bg))       
        bg:SetBackdropBorderColor(unpack(COLORS.input_border)) 
        editBox.bg = bg

        editBox:SetScript("OnEditFocusGained", function(self) 
            self.bg:SetBackdropBorderColor(unpack(COLORS.input_focus)) 
        end)
        editBox:SetScript("OnEditFocusLost", function(self) 
            self.bg:SetBackdropBorderColor(unpack(COLORS.input_border)) 
        end)
    end
end

-- ----------------------------------------------------------------------------
-- BINDING SETUP (INVISIBLE BUTTONS)
-- ----------------------------------------------------------------------------
local function SetupBindings()
    -- Invisible button for Toggling Main Window
    local btnToggle = CreateFrame("Button", "ASCENSIONNOTES_TOGGLE_BUTTON", UIParent)
    btnToggle:SetScript("OnClick", function()
        if not AN.mainFrame then AN:CreateMainFrame() end
        if AN.mainFrame then
             if AN.mainFrame:IsShown() then AN.mainFrame:Hide() else AN.mainFrame:Show() end
        end
    end)

    -- Invisible button for New Note
    local btnNew = CreateFrame("Button", "ASCENSIONNOTES_NEW_BUTTON", UIParent)
    btnNew:SetScript("OnClick", function()
        AN:OpenEditor(nil)
    end)
end

-- ----------------------------------------------------------------------------
-- SETTINGS PANEL (CUSTOM KEYBINDING UI)
-- ----------------------------------------------------------------------------
local function SetupSettingsPanel()
    if not Settings then return end 

    -- 1. Create the Frame for the settings panel first
    local panel = CreateFrame("Frame")
    
    -- 2. Populate the Frame
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText(addonName)

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    desc:SetWidth(600)
    desc:SetJustifyH("LEFT")
    desc:SetText("Manage your preferences and keybindings for Ascension Notes.")

    local bindHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    bindHeader:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -25)
    bindHeader:SetText("Keybindings")

    local function CreateBindRow(labelText, dbKey, targetButtonName, relativeTo)
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(600, 40)
        
        if relativeTo then
            row:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, -10)
        else
            row:SetPoint("TOPLEFT", bindHeader, "BOTTOMLEFT", 0, -15)
        end

        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", 0, 0)
        label:SetText(labelText)
        label:SetWidth(200)
        label:SetJustifyH("LEFT")

        local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        btn:SetSize(200, 30)
        btn:SetPoint("LEFT", label, "RIGHT", 10, 0)
        
        local function UpdateText()
            if not AscensionNotesDB then return end
            if not AscensionNotesDB.bindings then AscensionNotesDB.bindings = {} end

            local key = AscensionNotesDB.bindings[dbKey]
            if key and key ~= "NONE" then
                btn:SetText(key)
            else
                btn:SetText("Click to Bind")
            end
        end
        UpdateText()

        btn:SetScript("OnClick", function(self)
            if InCombatLockdown() then
                print("|cffff0000Ascension Notes:|r Cannot change bindings in combat.")
                return
            end
            
            self:SetText("Press a key...")
            self:EnableKeyboard(true)
            
            self:SetScript("OnKeyDown", function(keyBtn, key)
                if key == "ESCAPE" then
                    self:EnableKeyboard(false)
                    self:SetScript("OnKeyDown", nil)
                    UpdateText()
                    return
                end
                
                if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                    return
                end

                local fullKey = key
                if IsShiftKeyDown() then fullKey = "SHIFT-" .. fullKey end
                if IsControlKeyDown() then fullKey = "CTRL-" .. fullKey end
                if IsAltKeyDown() then fullKey = "ALT-" .. fullKey end
                
                if not AscensionNotesDB.bindings then AscensionNotesDB.bindings = {} end
                AscensionNotesDB.bindings[dbKey] = fullKey
                
                SetBindingClick(fullKey, targetButtonName)
                
                if SaveBindings then
                    SaveBindings(GetCurrentBindingSet()) 
                end
                
                print("|cff00ccffAscension Notes:|r Bound [" .. labelText .. "] to " .. fullKey)

                self:EnableKeyboard(false)
                self:SetScript("OnKeyDown", nil)
                UpdateText()
            end)
            
            self:SetScript("OnHide", function(s)
                s:EnableKeyboard(false)
                s:SetScript("OnKeyDown", nil)
            end)
        end)
        
        return row
    end

    local row1 = CreateBindRow("Toggle Window", "toggle", "ASCENSIONNOTES_TOGGLE_BUTTON", nil)
    local row2 = CreateBindRow("Quick New Note", "newNote", "ASCENSIONNOTES_NEW_BUTTON", row1)

    local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
    Settings.RegisterAddOnCategory(category)
end

-- ----------------------------------------------------------------------------
-- MAIN UI
-- ----------------------------------------------------------------------------

function AN:CreateMainFrame()
    if self.mainFrame then return end

    local f = CreateFrame("Frame", "AscensionNotesFrame", UIParent, "BackdropTemplate")
    f:SetSize(750, 450)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    tinsert(UISpecialFrames, "AscensionNotesFrame") 
    
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(unpack(COLORS.bg))
    f:SetBackdropBorderColor(unpack(COLORS.window_border)) 

    -- Header
    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    header:SetPoint("TOPLEFT", 20, -15)
    header:SetText("Ascension Notes")
    header:SetTextColor(unpack(COLORS.text_title))

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Toolbar
    local toolbar = CreateFrame("Frame", nil, f)
    toolbar:SetSize(450, 40)
    toolbar:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -10, -5)

    local newBtn = self:CreateStyledButton(toolbar, "New Note", "primary")
    if newBtn then
        newBtn:SetSize(110, 26)
        newBtn:SetPoint("RIGHT", 0, 0)
        newBtn:SetScript("OnClick", function() AN:OpenEditor(nil) end)
    end

    local importBtn = self:CreateStyledButton(toolbar, "Import", "normal")
    if importBtn then
        importBtn:SetSize(90, 26)
        importBtn:SetPoint("RIGHT", newBtn, "LEFT", -5, 0)
        importBtn:SetScript("OnClick", function() AN:ShowImportWindow() end)
    end

    -- Search Bar
    local searchBox = CreateFrame("EditBox", nil, toolbar)
    searchBox:SetSize(180, 26)
    searchBox:SetPoint("RIGHT", importBtn, "LEFT", -15, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFrameLevel(f:GetFrameLevel() + 5)
    self:StyleInputBox(searchBox)
    searchBox:SetTextInsets(8, 5, 0, 0) 
    
    searchBox.placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableHuge")
    searchBox.placeholder:SetPoint("LEFT", 8, 0) 
    searchBox.placeholder:SetText("Search...")
    
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then self.placeholder:Hide() else self.placeholder:Show() end
        AN.searchQuery = string.lower(text or "")
        AN:RefreshNoteGrid()
    end)
    f.searchBox = searchBox

    -- Sidebar
    local sidebarFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    sidebarFrame:SetPoint("TOPLEFT", 8, -60)
    sidebarFrame:SetPoint("BOTTOMLEFT", 8, 8)
    sidebarFrame:SetWidth(SIDEBAR_WIDTH)
    sidebarFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    sidebarFrame:SetBackdropColor(unpack(COLORS.sidebar_bg)) 

    local sbScroll = CreateFrame("ScrollFrame", nil, sidebarFrame)
    sbScroll:SetAllPoints()
    local sbContent = CreateFrame("Frame", nil, sbScroll)
    sbContent:SetSize(SIDEBAR_WIDTH, 500)
    sbScroll:SetScrollChild(sbContent)
    self.sidebarScroll = sbScroll
    self.sidebarScroll.content = sbContent

    -- Content Area
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 15, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(530, 800) 
    scrollFrame:SetScrollChild(content)
    
    self.contentFrame = content
    self.mainFrame = f

    self:UpdateSidebar()
    self:RefreshNoteGrid()
end

-- ----------------------------------------------------------------------------
-- SIDEBAR
-- ----------------------------------------------------------------------------

function AN:UpdateSidebar()
    if not self.sidebarScroll then return end
    local content = self.sidebarScroll.content
    local buttons = content.buttons or {}
    local items = { "All Notes" }
    
    if AscensionNotesDB and AscensionNotesDB.categories then
        for _, cat in ipairs(AscensionNotesDB.categories) do table.insert(items, cat) end
    end

    local lastBtn = nil

    for i, label in ipairs(items) do
        if not buttons[i] then
            local btn = CreateFrame("Button", nil, content, "BackdropTemplate")
            btn:SetSize(SIDEBAR_WIDTH, 40)
            
            btn.bar = btn:CreateTexture(nil, "OVERLAY")
            btn.bar:SetColorTexture(unpack(COLORS.sidebar_accent)) 
            btn.bar:SetPoint("LEFT", 0, 0)
            btn.bar:SetSize(6, 40)
            btn.bar:Hide()

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
            btn.text:SetPoint("LEFT", 15, 0)
            btn.text:SetJustifyH("LEFT")
            
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            btn:SetBackdropColor(0,0,0,0)

            btn:SetScript("OnEnter", function(s) 
                if not s.isActive then s:SetBackdropColor(unpack(COLORS.sidebar_hover)) end 
            end)
            btn:SetScript("OnLeave", function(s) 
                if not s.isActive then s:SetBackdropColor(0, 0, 0, 0) end 
            end)
            btn:SetScript("OnClick", function(s)
                AN.currentFilter = s.filterVal
                AN:RefreshNoteGrid()
                AN:UpdateSidebar()
            end)
            buttons[i] = btn
        end

        local btn = buttons[i]
        btn.text:SetText(label)
        if label == "All Notes" then btn.filterVal = nil else btn.filterVal = label end

        local isActive = (AN.currentFilter == btn.filterVal)
        btn.isActive = isActive

        if isActive then
            btn:SetBackdropColor(unpack(COLORS.sidebar_active)) 
            btn.bar:Show()
            btn.text:SetTextColor(unpack(COLORS.text_title))
        else
            btn:SetBackdropColor(0, 0, 0, 0)
            btn.bar:Hide()
            btn.text:SetTextColor(unpack(COLORS.text_dim)) 
        end

        btn:ClearAllPoints()
        if lastBtn then btn:SetPoint("TOP", lastBtn, "BOTTOM", 0, -2) else btn:SetPoint("TOP", 0, -5) end
        btn:Show()
        lastBtn = btn
    end

    for i = #items + 1, #buttons do buttons[i]:Hide() end
    content.buttons = buttons
end

-- ----------------------------------------------------------------------------
-- LIST VIEW
-- ----------------------------------------------------------------------------

function AN:RefreshNoteGrid()
    if not self.mainFrame then return end
    local kids = {self.contentFrame:GetChildren()}
    for _, child in ipairs(kids) do child:Hide() end

    local count = 0
    if not AscensionNotesDB or not AscensionNotesDB.notes then return end
    
    local notesList = AscensionNotesDB.notes
    local query = AN.searchQuery
    local filteredNotes = {}
    
    for _, note in ipairs(notesList) do
        local show = true
        if AN.currentFilter and note.category ~= AN.currentFilter then show = false end
        if show and query and query ~= "" then
            local title = string.lower(note.title or "")
            local body = string.lower(note.body or "")
            local foundInText = string.find(title, query, 1, true) or string.find(body, query, 1, true)
            local foundInTags = false
            if note.tags then
                for _, tag in ipairs(note.tags) do
                    if string.find(string.lower(tag), query, 1, true) then foundInTags = true; break end
                end
            end
            if not foundInText and not foundInTags then show = false end
        end
        if show then table.insert(filteredNotes, note) end
    end

    for i, note in ipairs(filteredNotes) do
        local name = "AscensionNoteCard_" .. i
        local card = _G[name] or CreateFrame("Button", name, self.contentFrame, "BackdropTemplate")
        card:SetSize(CARD_WIDTH, CARD_HEIGHT)
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        card:SetBackdropColor(unpack(COLORS.card_bg))
        card:SetBackdropBorderColor(unpack(COLORS.card_border))
        
        card:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(unpack(COLORS.card_hover)) end) 
        card:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(unpack(COLORS.card_border)) end)
        card:SetScript("OnClick", function() AN:OpenEditor(note) end)

        if not card.title then
            card.title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
            card.title:SetPoint("LEFT", 15, 0) 
            card.title:SetJustifyH("LEFT")
        end
        card.title:SetText(note.title or "Untitled")
        card.title:SetTextColor(unpack(COLORS.text_title)) 

        if card.preview then card.preview:Hide() end 

        local col = (i - 1) % MAX_COLUMNS
        local row = math.floor((i - 1) / MAX_COLUMNS)
        card:SetPoint("TOPLEFT", col * (CARD_WIDTH + PADDING), -(row * (CARD_HEIGHT + PADDING)))
        card:Show()
        count = i
    end

    local rows = math.ceil(count / MAX_COLUMNS)
    self.contentFrame:SetHeight(math.max(rows * (CARD_HEIGHT + PADDING) + 50, 400))
end

-- ----------------------------------------------------------------------------
-- EDITOR
-- ----------------------------------------------------------------------------

function AN:OpenEditor(noteData)
    if not self.editorFrame then
        local f = CreateFrame("Frame", "AscensionNotesEditor", UIParent, "BackdropTemplate")
        f:SetSize(400, 600) 
        f:SetPoint("RIGHT", -50, 0)
        f:SetFrameStrata("DIALOG")
        
        tinsert(UISpecialFrames, "AscensionNotesEditor")
        
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(s) s:StartMoving() end)
        f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(unpack(COLORS.bg))
        f:SetBackdropBorderColor(unpack(COLORS.window_border)) 
        f:EnableMouse(true)
        
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        lbl:SetPoint("TOPLEFT", 15, -15)
        lbl:SetText("Edit Note")
        lbl:SetTextColor(unpack(COLORS.text_title))

        local tmplBtn = self:CreateStyledButton(f, "Templates", "normal")
        tmplBtn:SetSize(100, 24)
        tmplBtn:SetPoint("TOPRIGHT", -30, -12)
        tmplBtn:SetScript("OnClick", function() AN:ToggleTemplateMenu() end)
        f.tmplBtn = tmplBtn

        -- 1. TITLE INPUT
        local titleBox = CreateFrame("EditBox", nil, f)
        titleBox:SetPoint("TOPLEFT", 20, -45)
        titleBox:SetPoint("TOPRIGHT", -20, -45)
        titleBox:SetHeight(35)
        titleBox:SetAutoFocus(false)
        titleBox:SetMaxLetters(100)
        titleBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        
        titleBox:SetFrameLevel(f:GetFrameLevel() + 5)
        
        self:StyleInputBox(titleBox)
        f.titleBox = titleBox

        -- 2. BODY INPUT
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", titleBox, "BOTTOMLEFT", 0, -15)
        scroll:SetPoint("BOTTOMRIGHT", -35, 100) 
        
        scroll:SetFrameLevel(f:GetFrameLevel() + 5)
        
        local bodyBox = CreateFrame("EditBox", nil, scroll)
        bodyBox:SetSize(300, 800)
        bodyBox:SetMultiLine(true)
        bodyBox:SetAutoFocus(false)
        
        local bodyBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
        bodyBg:SetPoint("TOPLEFT", scroll, -5, 5)
        bodyBg:SetPoint("BOTTOMRIGHT", scroll, 25, -5)
        
        bodyBg:SetFrameLevel(scroll:GetFrameLevel() - 1)
        bodyBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=2})
        
        bodyBg:SetBackdropColor(unpack(COLORS.input_bg))       
        bodyBg:SetBackdropBorderColor(unpack(COLORS.input_border)) 
        
        bodyBox:SetScript("OnEditFocusGained", function(self)
            bodyBg:SetBackdropBorderColor(unpack(COLORS.input_focus))
        end)
        bodyBox:SetScript("OnEditFocusLost", function(self)
            bodyBg:SetBackdropBorderColor(unpack(COLORS.input_border))
        end)
        
        -- FIX: Removed quotes for font object
        if GameFontHighlightHuge then
            bodyBox:SetFontObject(GameFontHighlightHuge)
        else
            bodyBox:SetFontObject(GameFontHighlight)
        end
        
        bodyBox:SetTextInsets(8, 8, 8, 8) 
        bodyBox:SetTextColor(unpack(COLORS.text_normal)) 
        scroll:SetScrollChild(bodyBox)
        
        f.bodyBox = bodyBox

        -- Category Selector
        local catBtn = self:CreateStyledButton(f, "Uncategorized", "normal")
        catBtn:SetSize(140, 26)
        catBtn:SetPoint("BOTTOMRIGHT", -20, 60)
        catBtn:SetFrameLevel(f:GetFrameLevel() + 5) 
        catBtn:SetScript("OnClick", function(self)
            local cats = AscensionNotesDB.categories or {}
            local current = self.selectedCat
            local nextCat, found = nil, false
            for i, c in ipairs(cats) do
                if c == current then
                    nextCat = cats[i+1]
                    found = true; break
                end
            end
            if not found and #cats > 0 then nextCat = cats[1] end
            self.selectedCat = nextCat
            self.text:SetText(nextCat or "Uncategorized")
        end)
        f.categoryBtn = catBtn

        -- Tag Input
        local tagInput = CreateFrame("EditBox", nil, f)
        tagInput:SetSize(160, 26)
        tagInput:SetPoint("BOTTOMLEFT", 20, 60) 
        tagInput:SetAutoFocus(false)
        tagInput:SetFrameLevel(f:GetFrameLevel() + 5) 
        self:StyleInputBox(tagInput)
        tagInput:SetTextInsets(8, 5, 0, 0) 
        
        tagInput.ph = tagInput:CreateFontString(nil, "OVERLAY", "GameFontDisableHuge")
        tagInput.ph:SetPoint("LEFT", 8, 0) 
        tagInput.ph:SetText("Add tag...")
        
        tagInput:SetScript("OnTextChanged", function(s) if s:GetText()~="" then s.ph:Hide() else s.ph:Show() end end)
        tagInput:SetScript("OnEnterPressed", function(self)
            local text = self:GetText()
            if text and text ~= "" then
                AN:AddTagToCurrentNote(text)
                self:SetText("")
            end
            self:ClearFocus()
        end)
        f.tagInput = tagInput

        f.tagDisplay = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.tagDisplay:SetPoint("LEFT", tagInput, "RIGHT", 5, 0)
        f.tagDisplay:SetTextColor(unpack(COLORS.text_tag))

        -- BOTTOM BUTTON ROW
        local saveBtn = self:CreateStyledButton(f, "Save", "primary")
        saveBtn:SetSize(100, 28)
        saveBtn:SetPoint("BOTTOMRIGHT", -20, 15)
        saveBtn:SetFrameLevel(f:GetFrameLevel() + 5) 
        saveBtn:SetScript("OnClick", function() AN:SaveNote() end)

        local delBtn = self:CreateStyledButton(f, "Delete", "danger")
        delBtn:SetSize(80, 28)
        delBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
        delBtn:SetFrameLevel(f:GetFrameLevel() + 5) 
        delBtn:SetScript("OnClick", function() AN:DeleteCurrentNote() end)

        local exportBtn = self:CreateStyledButton(f, "Export", "normal")
        exportBtn:SetSize(80, 28)
        exportBtn:SetPoint("BOTTOMLEFT", 20, 15)
        exportBtn:SetFrameLevel(f:GetFrameLevel() + 5) 
        exportBtn:SetScript("OnClick", function() AN:ExportCurrentNote() end)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", 0, 0)

        self.editorFrame = f
    end

    self.currentNote = noteData 
    if noteData then
        self.editorFrame.titleBox:SetText(noteData.title or "")
        self.editorFrame.bodyBox:SetText(noteData.body or "")
        self.editorFrame.categoryBtn.selectedCat = noteData.category
        self.editorFrame.categoryBtn.text:SetText(noteData.category or "Uncategorized")
        self.currentTags = CopyTable(noteData.tags or {})
    else
        self.editorFrame.titleBox:SetText("")
        self.editorFrame.bodyBox:SetText("")
        self.editorFrame.categoryBtn.selectedCat = nil
        self.editorFrame.categoryBtn.text:SetText("Uncategorized")
        self.currentTags = {}
    end
    AN:UpdateEditorTags()
    self.editorFrame:Show()
    
    if not noteData then self.editorFrame.titleBox:SetFocus() end
end

function AN:AddTagToCurrentNote(tagText)
    if not self.currentTags then self.currentTags = {} end
    for _, t in ipairs(self.currentTags) do
        if string.lower(t) == string.lower(tagText) then return end
    end
    table.insert(self.currentTags, tagText)
    self:UpdateEditorTags()
end

function AN:UpdateEditorTags()
    if not self.editorFrame or not self.editorFrame.tagDisplay then return end
    local text = ""
    if self.currentTags then
        for i, tag in ipairs(self.currentTags) do
            if i == 1 then text = "#" .. tag else text = text .. ", #" .. tag end
        end
    end
    self.editorFrame.tagDisplay:SetText(text)
end

function AN:SaveNote()
    local title = self.editorFrame.titleBox:GetText()
    local body = self.editorFrame.bodyBox:GetText()
    local category = self.editorFrame.categoryBtn.selectedCat
    local timestamp = date("%Y-%m-%d %H:%M")
    local tagsToSave = CopyTable(self.currentTags or {})

    if title == "" and body == "" then return end

    if self.currentNote then
        self.currentNote.title = title
        self.currentNote.body = body
        self.currentNote.category = category
        self.currentNote.tags = tagsToSave
        self.currentNote.updated = timestamp
    else
        local newNote = {
            id = GenerateID(),
            title = (title ~= "" and title) or "Untitled",
            body = body,
            category = category,
            tags = tagsToSave,
            created = timestamp,
        }
        if not AscensionNotesDB.notes then AscensionNotesDB.notes = {} end
        table.insert(AscensionNotesDB.notes, newNote)
    end

    self.editorFrame:Hide()
    self:RefreshNoteGrid()
end

function AN:DeleteCurrentNote()
    if not self.currentNote then return end
    for i, note in ipairs(AscensionNotesDB.notes) do
        if note.id == self.currentNote.id then
            table.remove(AscensionNotesDB.notes, i)
            break
        end
    end
    self.editorFrame:Hide()
    self:RefreshNoteGrid()
end

-- ----------------------------------------------------------------------------
-- FEATURE: TEMPLATES & IMPORT
-- ----------------------------------------------------------------------------

function AN:ToggleTemplateMenu()
    if not self.tmplFrame then
        local f = CreateFrame("Frame", nil, self.editorFrame, "BackdropTemplate")
        f:SetSize(180, 100)
        f:SetPoint("TOPRIGHT", self.editorFrame.tmplBtn, "BOTTOMRIGHT", 0, -2)
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        f:SetBackdropColor(unpack(COLORS.menu_bg)) 
        f:SetBackdropBorderColor(unpack(COLORS.window_border)) 
        f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(self.editorFrame:GetFrameLevel() + 5)
        
        local lastBtn = nil
        for i, tmpl in ipairs(TEMPLATES) do
            local btn = CreateFrame("Button", nil, f)
            btn:SetSize(180, 30)
            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
            txt:SetPoint("LEFT", 10, 0)
            txt:SetText(tmpl.name)
            txt:SetTextColor(unpack(COLORS.text_normal)) 
            
            btn:SetScript("OnEnter", function(s) txt:SetTextColor(unpack(COLORS.text_highlight)) end) 
            btn:SetScript("OnLeave", function(s) txt:SetTextColor(unpack(COLORS.text_normal)) end) 
            btn:SetScript("OnClick", function()
                AN.editorFrame.bodyBox:Insert(tmpl.body)
                f:Hide()
            end)
            
            if lastBtn then btn:SetPoint("TOP", lastBtn, "BOTTOM", 0, 0) else btn:SetPoint("TOP", 0, 0) end
            btn:SetPoint("LEFT", 0, 0)
            lastBtn = btn
        end
        f:SetHeight(#TEMPLATES * 30)
        self.tmplFrame = f
    end
    if self.tmplFrame:IsShown() then self.tmplFrame:Hide() else self.tmplFrame:Show() end
end

function AN:ShowCopyPasteWindow(title, text, isImport)
    if not self.cpFrame then
        local f = CreateFrame("Frame", "AscensionCopyFrame", UIParent, "BackdropTemplate")
        f:SetSize(450, 400)
        f:SetPoint("CENTER", 0, 0)
        f:SetFrameStrata("TOOLTIP")
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
        f:SetBackdropColor(unpack(COLORS.bg))
        f:SetBackdropBorderColor(unpack(COLORS.window_border))
        
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -30)
        scroll:SetPoint("BOTTOMRIGHT", -30, 45)
        
        scroll:SetFrameLevel(f:GetFrameLevel() + 5)
        
        local editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetSize(400, 400)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(true)
        scroll:SetScrollChild(editBox)
        
        local bg = CreateFrame("Frame", nil, f, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", scroll, -5, 5)
        bg:SetPoint("BOTTOMRIGHT", scroll, 25, -5)
        
        bg:SetFrameLevel(scroll:GetFrameLevel() - 1)
        bg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=2})
        bg:SetBackdropColor(unpack(COLORS.input_bg))       
        bg:SetBackdropBorderColor(unpack(COLORS.input_border)) 
        
        -- FIX: Removed quotes for font object
        if GameFontHighlightHuge then
            editBox:SetFontObject(GameFontHighlightHuge)
        else
            editBox:SetFontObject(GameFontHighlight)
        end
        
        editBox:SetTextInsets(10,10,10,10)
        editBox:SetTextColor(unpack(COLORS.text_normal)) 
        
        f.editBox = editBox

        local btn = self:CreateStyledButton(f, "Action", "primary")
        btn:SetSize(120, 30)
        btn:SetPoint("BOTTOM", 0, 10)
        f.actionBtn = btn

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 0, 0)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.title:SetPoint("TOP", 0, -20) 
        f.title:SetTextColor(unpack(COLORS.text_title))
        self.cpFrame = f
    end

    self.cpFrame.title:SetText(title)
    self.cpFrame.editBox:SetText(text or "")
    if not isImport then self.cpFrame.editBox:HighlightText() end
    
    if isImport then
        self.cpFrame.actionBtn.text:SetText("Import")
        self.cpFrame.actionBtn:SetScript("OnClick", function()
            local raw = AN.cpFrame.editBox:GetText()
            local s, e = string.find(raw, "\n")
            local newTitle, newBody = "Imported Note", raw
            if s then
                newTitle = string.sub(raw, 1, s-1)
                newBody = string.sub(raw, e+1)
            end
            local newNote = {
                id = GenerateID(), title = newTitle, body = newBody,
                created = date("%Y-%m-%d %H:%M"), tags = {}
            }
            if not AscensionNotesDB.notes then AscensionNotesDB.notes = {} end
            table.insert(AscensionNotesDB.notes, newNote)
            AN:RefreshNoteGrid()
            AN.cpFrame:Hide()
        end)
    else
        self.cpFrame.actionBtn.text:SetText("Done")
        self.cpFrame.actionBtn:SetScript("OnClick", function() AN.cpFrame:Hide() end)
    end
    self.cpFrame:Show()
end

function AN:ExportCurrentNote()
    local title = self.editorFrame.titleBox:GetText()
    local body = self.editorFrame.bodyBox:GetText()
    local fullText = title .. "\n" .. body
    self:ShowCopyPasteWindow("Export Note (Ctrl+C)", fullText, false)
end

function AN:ShowImportWindow()
    self:ShowCopyPasteWindow("Import Note", "", true)
end

-- ----------------------------------------------------------------------------
-- INITIALIZATION
-- ----------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if AscensionNotesDB == nil then AscensionNotesDB = CopyTable(defaultDB) end
        if AscensionNotesDB.notes == nil then AscensionNotesDB.notes = {} end
        if AscensionNotesDB.bindings == nil then AscensionNotesDB.bindings = { toggle = "NONE", newNote = "NONE" } end
        
        SetupBindings()
        SetupSettingsPanel()
        
        print("|cff00ccffAscensionNotes:|r Loaded. Type /an to toggle.")
        
    elseif event == "PLAYER_LOGIN" then
        -- Restore saved bindings on login
        if AscensionNotesDB and AscensionNotesDB.bindings then
            if AscensionNotesDB.bindings.toggle and AscensionNotesDB.bindings.toggle ~= "NONE" then
                SetBindingClick(AscensionNotesDB.bindings.toggle, "ASCENSIONNOTES_TOGGLE_BUTTON")
            end
            if AscensionNotesDB.bindings.newNote and AscensionNotesDB.bindings.newNote ~= "NONE" then
                SetBindingClick(AscensionNotesDB.bindings.newNote, "ASCENSIONNOTES_NEW_BUTTON")
            end
        end
    end
end)

SLASH_ASCENSIONNOTES1 = "/an"
SlashCmdList["ASCENSIONNOTES"] = function(msg)
    if not AN.mainFrame then AN:CreateMainFrame() end
    if AN.mainFrame then
        if AN.mainFrame:IsShown() then AN.mainFrame:Hide() else AN.mainFrame:Show() end
    end
end
