-- ----------------------------------------------------------------------------
-- Addon Initialization
-- ----------------------------------------------------------------------------
local addonName = "AscensionNotes"
local AscensionNotes = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Localized globals for binding headers (displayed in WoW Options)
_G["BINDING_HEADER_ASCENSIONNOTES_HEADER"] = "Ascension Notes"
_G["BINDING_NAME_ASCENSIONNOTES_TOGGLE"] = "Toggle Notes Window"

-- Default database profile
local defaults = {
    profile = {
        notes = {}, -- Structure: { ["Note Title"] = "Note Content" }
        windowState = { -- Saved window position/size
            width = 600,
            height = 400,
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

-- ----------------------------------------------------------------------------
-- Lifecycle Methods
-- ----------------------------------------------------------------------------

function AscensionNotes:OnInitialize()
    -- Initialize Database
    self.db = LibStub("AceDB-3.0"):New("AscensionNotesDB", defaults, true)
    
    -- Register chat command for manual opening
    self:RegisterChatCommand("anotes", "ToggleWindow")
    self:RegisterChatCommand("ascensionnotes", "ToggleWindow")
end

-- ----------------------------------------------------------------------------
-- Logic & Data Handling
-- ----------------------------------------------------------------------------

--- Saves the current text to the database
-- @param title: The title of the note (string)
-- @param text: The content of the note (string)
function AscensionNotes:SaveNote(title, text)
    if not title or title == "" then return end
    
    -- Safety check: Ensure DB exists
    if not self.db or not self.db.profile then return end

    self.db.profile.notes[title] = text or ""
end

--- Deletes a note
-- @param title: The title of the note to delete
function AscensionNotes:DeleteNote(title)
    if not title or not self.db then return end
    
    self.db.profile.notes[title] = nil
    
    -- Reset selection if we deleted the active note
    if currentNoteTitle == title then
        currentNoteTitle = nil
        if editorBox then editorBox:SetText("") end
    end
    
    self:RefreshNoteList()
end

--- Converts DB table to AceGUI Tree structure
-- @return table: formatted for AceGUI TreeGroup
function AscensionNotes:GetNoteListForTree()
    local treeData = {}
    
    if not self.db then return treeData end

    for title, _ in pairs(self.db.profile.notes) do
        table.insert(treeData, {
            value = title,
            text = title,
        })
    end
    
    -- Sort alphabetically for UX
    table.sort(treeData, function(a, b) return a.text < b.text end)
    
    return treeData
end

-- ----------------------------------------------------------------------------
-- UI Construction (AceGUI)
-- ----------------------------------------------------------------------------

--- Creates the main window frame if it doesn't exist
function AscensionNotes:CreateFrame()
    if mainFrame then return end

    -- 1. Main Window Container
    local frame = AceGUI:Create("Window")
    frame:SetTitle("Ascension Notes")
    frame:SetLayout("Fill")
    frame:EnableResize(true)
    
    -- Apply saved dimensions
    local ws = self.db.profile.windowState
    if ws then
        frame:SetWidth(ws.width or 600)
        frame:SetHeight(ws.height or 400)
        -- Note: Point restoration requires standard frame API manipulation if AceGUI doesn't auto-handle it fully,
        -- but AceGUI windows generally persist nicely if not manually reset.
    end

    -- Save position on close
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        mainFrame = nil
        treeGroup = nil
        editorBox = nil
    end)

    -- 2. Tree Group (Sidebar for List, Main area for Content)
    local tree = AceGUI:Create("TreeGroup")
    tree:SetLayout("Flow")
    tree:SetTreeWidth(150, false) -- 150px sidebar
    tree:EnableButtonTooltips(false)
    
    -- Callback: When a note is selected in the list
    tree:SetCallback("OnGroupSelected", function(widget, event, uniqueValue)
        currentNoteTitle = uniqueValue
        AscensionNotes:DrawEditor(tree)
    end)

    frame:AddChild(tree)
    treeGroup = tree
    mainFrame = frame

    -- Populate the list
    self:RefreshNoteList()
end

--- Refreshes the sidebar list data
function AscensionNotes:RefreshNoteList()
    if not treeGroup then return end
    
    local data = self:GetNoteListForTree()
    treeGroup:SetTree(data)
    
    -- Reselect current note if it still exists
    if currentNoteTitle and self.db.profile.notes[currentNoteTitle] then
        treeGroup:SelectByValue(currentNoteTitle)
    else
        currentNoteTitle = nil
    end
end

--- Draws the Editor view inside the TreeGroup content area
-- @param container: The AceGUI container to draw into
function AscensionNotes:DrawEditor(container)
    container:ReleaseChildren() -- Clear previous elements

    -- If no note is selected, show the "New Note" interface
    if not currentNoteTitle then
        self:DrawWelcomeScreen(container)
        return
    end

    -- 1. Toolbar (Title and Delete Button)
    local heading = AceGUI:Create("Heading")
    heading:SetText(currentNoteTitle)
    heading:SetFullWidth(true)
    container:AddChild(heading)

    -- 2. Multi-Line Text Editor
    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel("")
    editBox:SetFullWidth(true)
    editBox:SetNumLines(20) -- Starts with reasonable height, expands with window
    editBox:DisableButton(true) -- Hide the "Accept" button, we auto-save
    
    -- Load text (Nil Check: Ensure text is string)
    local noteText = self.db.profile.notes[currentNoteTitle] or ""
    editBox:SetText(noteText)

    -- Callback: Auto-save on text change
    editBox:SetCallback("OnTextChanged", function(widget, event, text)
        -- Nil check for text
        if currentNoteTitle then
            AscensionNotes:SaveNote(currentNoteTitle, text or "")
        end
    end)

    container:AddChild(editBox)
    editorBox = editBox

    -- 3. Delete Button (Bottom)
    local deleteBtn = AceGUI:Create("Button")
    deleteBtn:SetText("Delete Note")
    deleteBtn:SetWidth(120)
    deleteBtn:SetCallback("OnClick", function()
        AscensionNotes:DeleteNote(currentNoteTitle)
    end)
    container:AddChild(deleteBtn)
end

--- Draws the "Welcome / New Note" screen
function AscensionNotes:DrawWelcomeScreen(container)
    local info = AceGUI:Create("Label")
    info:SetText("\nSelect a note from the left or create a new one.\n")
    info:SetFullWidth(true)
    container:AddChild(info)

    -- New Note Input
    local nameBox = AceGUI:Create("EditBox")
    nameBox:SetLabel("New Note Title")
    nameBox:SetWidth(200)
    nameBox:DisableButton(false)
    
    nameBox:SetCallback("OnEnterPressed", function(widget, event, text)
        if text and text ~= "" then
            -- Create empty note
            AscensionNotes:SaveNote(text, "")
            -- Refresh list
            AscensionNotes:RefreshNoteList()
            -- Select the new note
            if treeGroup then
                treeGroup:SelectByValue(text)
            end
        end
    end)
    
    container:AddChild(nameBox)
end

-- ----------------------------------------------------------------------------
-- Public API / Keybind Handler
-- ----------------------------------------------------------------------------

function AscensionNotes:ToggleWindow()
    if mainFrame and mainFrame:IsShown() then
        mainFrame:Hide()
    else
        self:CreateFrame()
        mainFrame:Show()
    end
end