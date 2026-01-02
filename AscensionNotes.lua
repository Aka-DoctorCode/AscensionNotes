-- ----------------------------------------------------------------------------
-- Addon Initialization
-- ----------------------------------------------------------------------------
local addonName = "AscensionNotes"
AscensionNotes = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Default database profile
local defaults = {
    profile = {
        notes = {}, 
        toggleKey = nil,
        windowState = {
            width = 700, -- Wider by default for better writing space
            height = 500,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
        },
    }
}

-- UI State Variables
local mainFrame = nil
local treeGroup = nil
local editorBox = nil
local currentNoteTitle = nil

-- Global invisible button for Keybinding
local toggleButton = CreateFrame("Button", "AscensionNotes_ToggleBtn", UIParent)
toggleButton:SetScript("OnClick", function() 
    if AscensionNotes then AscensionNotes:QuickNewNote() end 
end)

-- ----------------------------------------------------------------------------
-- Options Table (AceConfig)
-- ----------------------------------------------------------------------------
local options = {
    name = "Ascension Notes",
    handler = AscensionNotes,
    type = "group",
    args = {
        keybindHeader = {
            type = "header",
            name = "Shortcuts",
            order = 1,
        },
        toggleKey = {
            type = "keybinding",
            name = "Quick Note Keybind",
            desc = "Pressing this key creates a 'Quick Note' immediately and lets you write.",
            order = 2,
            get = function() return AscensionNotes.db.profile.toggleKey end,
            set = function(info, key)
                local oldKey = AscensionNotes.db.profile.toggleKey
                if oldKey then SetBinding(oldKey, nil) end
                AscensionNotes.db.profile.toggleKey = key
                if key then SetBindingClick(key, "AscensionNotes_ToggleBtn") end
            end,
        },
    },
}

-- ----------------------------------------------------------------------------
-- Lifecycle Methods
-- ----------------------------------------------------------------------------

function AscensionNotes:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AscensionNotesDB", defaults, true)
    AceConfig:RegisterOptionsTable("AscensionNotes", options)
    AceConfigDialog:AddToBlizOptions("AscensionNotes", "Ascension Notes")
    
    self:RegisterChatCommand("an", "OpenMenu")
    self:RegisterChatCommand("anotes", "OpenMenu")
    self:RegisterChatCommand("ascensionnotes", "OpenMenu")
    
    local savedKey = self.db.profile.toggleKey
    if savedKey and not InCombatLockdown() then
        SetBindingClick(savedKey, "AscensionNotes_ToggleBtn")
    end
end

-- ----------------------------------------------------------------------------
-- Logic & Data Handling
-- ----------------------------------------------------------------------------

function AscensionNotes:SaveNote(title, text)
    if not title or title == "" then return end
    if not self.db or not self.db.profile then return end
    self.db.profile.notes[title] = text or ""
end

function AscensionNotes:DeleteNote(title)
    if not title or not self.db then return end
    self.db.profile.notes[title] = nil
    if currentNoteTitle == title then
        currentNoteTitle = nil
        if editorBox then editorBox:SetText("") end
    end
    self:RefreshNoteList()
end

function AscensionNotes:GetNoteListForTree()
    local treeData = {}
    if not self.db then return treeData end
    for title, _ in pairs(self.db.profile.notes) do
        table.insert(treeData, { value = title, text = title })
    end
    table.sort(treeData, function(a, b) return a.text < b.text end)
    return treeData
end

-- ----------------------------------------------------------------------------
-- UI Construction (AceGUI)
-- ----------------------------------------------------------------------------

function AscensionNotes:CreateFrame()
    if mainFrame then return end
    
    -- Main Container
    local frame = AceGUI:Create("Window")
    frame:SetTitle("Ascension Notes")
    frame:SetLayout("Fill")
    frame:EnableResize(true)
    
    local ws = self.db.profile.windowState
    if ws then
        frame:SetWidth(ws.width or 700)
        frame:SetHeight(ws.height or 500)
    end

    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        mainFrame = nil
        treeGroup = nil
        editorBox = nil
    end)

    -- Split View (Sidebar | Content)
    local tree = AceGUI:Create("TreeGroup")
    tree:SetLayout("Flow")
    tree:SetTreeWidth(180, false) -- Slightly wider sidebar for readability
    tree:EnableButtonTooltips(false)
    
    tree:SetCallback("OnGroupSelected", function(widget, event, uniqueValue)
        currentNoteTitle = uniqueValue
        AscensionNotes:DrawEditor(tree)
    end)

    frame:AddChild(tree)
    treeGroup = tree
    mainFrame = frame

    self:RefreshNoteList()
end

function AscensionNotes:RefreshNoteList()
    if not treeGroup then return end
    local data = self:GetNoteListForTree()
    treeGroup:SetTree(data)
    
    if currentNoteTitle and self.db.profile.notes[currentNoteTitle] then
        treeGroup:SelectByValue(currentNoteTitle)
    else
        currentNoteTitle = nil
        self:DrawEditor(treeGroup)
    end
end

-- Applies UI/UX Principles: Hierarchy, Space, Minimalism
function AscensionNotes:DrawEditor(container)
    container:ReleaseChildren()
    
    if not currentNoteTitle then
        self:DrawWelcomeScreen(container)
        return
    end

    -- 1. HEADER GROUP (Horizontal Layout)
    -- Creates a clear visual hierarchy for the Title and the Actions
    local headerGroup = AceGUI:Create("SimpleGroup")
    headerGroup:SetFullWidth(true)
    headerGroup:SetLayout("Flow")
    container:AddChild(headerGroup)

    -- 1a. Title (Dominant Visual Element)
    local titleLabel = AceGUI:Create("Label")
    titleLabel:SetText(currentNoteTitle)
    titleLabel:SetFontObject(GameFontNormalHuge) -- Large font for Hierarchy
    titleLabel:SetColor(1, 1, 1) -- White for contrast
    titleLabel:SetRelativeWidth(0.75) -- Takes up 75% of width
    headerGroup:AddChild(titleLabel)

    -- 1b. Delete Action (Minimalist, Accent Color)
    -- Replaces the large button at the bottom. 
    -- Placed top-right to be accessible but not intrusive.
    local deleteBtn = AceGUI:Create("Button")
    deleteBtn:SetText("Delete")
    deleteBtn:SetRelativeWidth(0.24)
    -- We can't easily style Ace3 buttons to be flat, but we can keep it small.
    deleteBtn:SetCallback("OnClick", function()
        AscensionNotes:DeleteNote(currentNoteTitle)
    end)
    headerGroup:AddChild(deleteBtn)

    -- 2. EDITOR AREA (Focus)
    -- Simple scrolling text box that dominates the screen.
    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel("") -- No label, cleaner look
    editBox:SetFullWidth(true)
    editBox:SetNumLines(25) -- Fills the vertical space
    editBox:DisableButton(true) -- Removes "Accept" button for minimalism
    
    local noteText = self.db.profile.notes[currentNoteTitle] or ""
    editBox:SetText(noteText)

    editBox:SetCallback("OnTextChanged", function(widget, event, text)
        if currentNoteTitle then
            AscensionNotes:SaveNote(currentNoteTitle, text or "")
        end
    end)

    container:AddChild(editBox)
    editorBox = editBox
end

-- Applies UI/UX Principles: deliberate whitespace, clear single action
function AscensionNotes:DrawWelcomeScreen(container)
    -- Spacer for vertical centering (Visual Breathing Room)
    local spacerTop = AceGUI:Create("Label")
    spacerTop:SetText("\n\n\n\n") 
    container:AddChild(spacerTop)

    -- Instruction (Subtle Hierarchy)
    local info = AceGUI:Create("Label")
    info:SetText("Create a new note")
    info:SetFontObject(GameFontNormalLarge)
    info:SetJustifyH("CENTER")
    info:SetFullWidth(true)
    info:SetColor(0.7, 0.7, 0.7) -- Soft gray
    container:AddChild(info)

    -- Input (The Primary Action)
    local nameBox = AceGUI:Create("EditBox")
    nameBox:SetLabel("") -- Clean, no label needed if context is clear
    nameBox:SetWidth(250) -- Limited width for focus
    nameBox:DisableButton(false)
    
    -- Center the editbox roughly by wrapping it in a group with padding (Logic)
    -- AceGUI flow is tricky for centering, so we rely on the container flow.
    
    nameBox:SetCallback("OnEnterPressed", function(widget, event, text)
        if text and text ~= "" then
            AscensionNotes:SaveNote(text, "")
            AscensionNotes:RefreshNoteList()
            
            currentNoteTitle = text
            if treeGroup then
                treeGroup:SelectByValue(text)
                AscensionNotes:DrawEditor(treeGroup)
            end
        end
    end)
    
    container:AddChild(nameBox)
    nameBox:SetFocus()
end

-- ----------------------------------------------------------------------------
-- Public API & Shortcuts
-- ----------------------------------------------------------------------------

function AscensionNotes:QuickNewNote()
    if not mainFrame then self:CreateFrame() end
    mainFrame:Show()
    
    -- Timestamped title for instant utility
    local timestamp = date("%I:%M %p") -- Simplified Time Format (12h)
    local newTitle = "Quick Note " .. timestamp
    
    -- Handle duplicate names in the same minute
    if self.db.profile.notes[newTitle] then
        newTitle = newTitle .. " (" .. date("%S") .. ")"
    end
    
    self:SaveNote(newTitle, "")
    currentNoteTitle = newTitle
    self:RefreshNoteList() 
    
    if treeGroup then
        treeGroup:SelectByValue(newTitle)
        self:DrawEditor(treeGroup) 
    end
    
    if editorBox and editorBox.editBox then
        editorBox.editBox:SetFocus()
    end
end

function AscensionNotes:OpenMenu()
    if not mainFrame then self:CreateFrame() end
    
    if mainFrame:IsShown() and currentNoteTitle == nil then
        mainFrame:Hide()
    else
        mainFrame:Show()
        currentNoteTitle = nil
        if treeGroup then
            treeGroup:SelectByValue(nil)
            self:DrawEditor(treeGroup)
        end
    end
end
