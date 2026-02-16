-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode 
-- File: Main.lua
-- Version: 11
-------------------------------------------------------------------------------
-- Copyright (c) 2025–2026 Aka-DoctorCode. All Rights Reserved.
--
-- This software and its source code are the exclusive property of the author.
-- No part of this file may be copied, modified, redistributed, or used in 
-- derivative works without express written permission.
-------------------------------------------------------------------------------
local addonName, NS = ...
local AN = NS.AN

AN.currentFilter = nil 
AN.searchQuery = ""

-- ----------------------------------------------------------------------------
-- MAIN WINDOW
-- ----------------------------------------------------------------------------

function AN:CreateMainFrame()
    if self.mainFrame then return end

    local f = CreateFrame("Frame", "AscensionNotesFrame", UIParent, "BackdropTemplate")
    f:SetSize(750, 450)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetResizeBounds(450, 100)
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
    f:SetBackdropColor(unpack(AN.COLORS.bg))
    f:SetBackdropBorderColor(unpack(AN.COLORS.window_border)) 

    -- RESIZE GRIP (Bottom Right)
    local resizeBtn = CreateFrame("Button", nil, f)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -6, 6)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
            self:GetHighlightTexture():Hide()
        end
    end)
    resizeBtn:SetScript("OnMouseUp", function(self, button)
        f:StopMovingOrSizing()
        self:GetHighlightTexture():Show()
        -- Force grid refresh on stop
        AN:RefreshNoteGrid()
    end)

    -- Header
    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    header:SetPoint("TOPLEFT", 20, -15)
    header:SetText("Ascension Notes")
    header:SetTextColor(unpack(AN.COLORS.text_title))

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
    sidebarFrame:SetWidth(AN.CONSTANTS.SIDEBAR_WIDTH)
    sidebarFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    
    if AN.COLORS.sidebar_bg then
        sidebarFrame:SetBackdropColor(unpack(AN.COLORS.sidebar_bg)) 
    end

    -- Add Category Button
    local addCatBtn = self:CreateStyledButton(sidebarFrame, "+ Category", "normal")
    if addCatBtn then
        addCatBtn:SetSize(AN.CONSTANTS.SIDEBAR_WIDTH - 10, 24)
        addCatBtn:SetPoint("BOTTOM", 0, 5)
        addCatBtn:SetScript("OnClick", function()
            AN:ShowCustomPopup("INPUT", "New Category", "", function(text)
                if text and text ~= "" then
                    local exists = false
                    if AscensionNotesDB.categories then
                        for _, cat in ipairs(AscensionNotesDB.categories) do
                            if cat == text then exists = true; break end
                        end
                    end
                    if not exists then
                        if not AscensionNotesDB.categories then AscensionNotesDB.categories = {} end
                        table.insert(AscensionNotesDB.categories, text)
                        AN:UpdateSidebar()
                    else
                        print("|cffff0000Ascension Notes:|r Category already exists.")
                    end
                end
            end)
        end)
    end

    -- Sidebar Scroll Frame
    local sbScroll = CreateFrame("ScrollFrame", nil, sidebarFrame)
    sbScroll:SetPoint("TOPLEFT", 0, 0)
    sbScroll:SetPoint("TOPRIGHT", 0, 0)
    sbScroll:SetPoint("BOTTOM", addCatBtn, "TOP", 0, 5)
    
    local sbContent = CreateFrame("Frame", nil, sbScroll)
    sbContent:SetSize(AN.CONSTANTS.SIDEBAR_WIDTH, 500)
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

    -- Handle Resize Dynamic Layout
    f:SetScript("OnSizeChanged", function(self, width, height)
        -- Update the content frame width to match the scroll area width
        if AN.contentFrame then
            local scrollWidth = scrollFrame:GetWidth()
            AN.contentFrame:SetWidth(scrollWidth)
            AN:RefreshNoteGrid()
        end
    end)

    self:UpdateSidebar()
    self:RefreshNoteGrid()
end

-- ----------------------------------------------------------------------------
-- SIDEBAR LOGIC (Preserving Context Menu Logic)
-- ----------------------------------------------------------------------------
function AN:CreateContextMenu()
    if self.contextMenu then return end
    local f = CreateFrame("Frame", "AscensionContextMenu", UIParent, "BackdropTemplate")
    f:SetSize(150, 140) 
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(unpack(AN.COLORS.menu_bg))
    f:SetBackdropBorderColor(unpack(AN.COLORS.window_border))
    f:Hide()

    local function CreateMenuBtn(text, parent, relativeTo, colorOverride)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(150, 35)
        if relativeTo then btn:SetPoint("TOP", relativeTo, "BOTTOM", 0, 0) else btn:SetPoint("TOP", 0, 0) end
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("LEFT", 10, 0)
        btn.text:SetText(text)
        if colorOverride then btn.text:SetTextColor(unpack(colorOverride)) end
        btn:SetScript("OnEnter", function(s) 
            if not colorOverride then s.text:SetTextColor(unpack(AN.COLORS.text_highlight)) end
            s.bg = s.bg or s:CreateTexture(nil, "BACKGROUND"); s.bg:SetAllPoints(); s.bg:SetColorTexture(1, 1, 1, 0.1)
        end)
        btn:SetScript("OnLeave", function(s) 
            if not colorOverride then s.text:SetTextColor(unpack(AN.COLORS.text_normal)) end
            if s.bg then s.bg:Hide() s.bg = nil end
        end)
        return btn
    end

    local btnUp = CreateMenuBtn("Move Up", f, nil)
    btnUp:SetScript("OnClick", function()
        local cat = f.targetCategory
        if cat and AscensionNotesDB.categories then
            for i, c in ipairs(AscensionNotesDB.categories) do
                if c == cat and i > 1 then
                    AscensionNotesDB.categories[i], AscensionNotesDB.categories[i-1] = AscensionNotesDB.categories[i-1], AscensionNotesDB.categories[i]
                    AN:UpdateSidebar()
                    break
                end
            end
        end
        f:Hide()
    end)

    local btnDown = CreateMenuBtn("Move Down", f, btnUp)
    btnDown:SetScript("OnClick", function()
        local cat = f.targetCategory
        if cat and AscensionNotesDB.categories then
            for i, c in ipairs(AscensionNotesDB.categories) do
                if c == cat and i < #AscensionNotesDB.categories then
                    AscensionNotesDB.categories[i], AscensionNotesDB.categories[i+1] = AscensionNotesDB.categories[i+1], AscensionNotesDB.categories[i]
                    AN:UpdateSidebar()
                    break
                end
            end
        end
        f:Hide()
    end)

    local btnColor = CreateMenuBtn("Set Color", f, btnDown)
    btnColor:SetScript("OnClick", function()
        local cat = f.targetCategory
        if cat then
            local r, g, b = unpack(AN.COLORS.sidebar_accent)
            if AscensionNotesDB.categoryColors and AscensionNotesDB.categoryColors[cat] then
                r, g, b = unpack(AscensionNotesDB.categoryColors[cat])
            end
            local info = {
                r = r, g = g, b = b, hasOpacity = false,
                swatchFunc = function()
                    local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    if not AscensionNotesDB.categoryColors then AscensionNotesDB.categoryColors = {} end
                    AscensionNotesDB.categoryColors[cat] = {newR, newG, newB, 1}
                    AN:UpdateSidebar()
                end,
                cancelFunc = function(restore)
                    if not AscensionNotesDB.categoryColors then AscensionNotesDB.categoryColors = {} end
                    AscensionNotesDB.categoryColors[cat] = {restore.r, restore.g, restore.b, 1}
                    AN:UpdateSidebar()
                end
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end
        f:Hide()
    end)

    local btnRename = CreateMenuBtn("Rename", f, btnColor)
    btnRename:SetScript("OnClick", function()
        if f.targetCategory then 
            AN:ShowCustomPopup("INPUT", "Rename Category", f.targetCategory, function(newName)
                if newName and newName ~= "" then
                    local oldName = f.targetCategory
                    if AscensionNotesDB.categories then
                        for i, cat in ipairs(AscensionNotesDB.categories) do
                            if cat == oldName then AscensionNotesDB.categories[i] = newName; break end
                        end
                    end
                    if AscensionNotesDB.categoryColors and AscensionNotesDB.categoryColors[oldName] then
                        AscensionNotesDB.categoryColors[newName] = AscensionNotesDB.categoryColors[oldName]
                        AscensionNotesDB.categoryColors[oldName] = nil
                    end
                    if AscensionNotesDB.notes then
                        for _, note in ipairs(AscensionNotesDB.notes) do
                            if note.category == oldName then note.category = newName end
                        end
                    end
                    AN:UpdateSidebar()
                    AN:RefreshNoteGrid()
                end
            end)
        end
        f:Hide()
    end)

    local btnDelete = CreateMenuBtn("Delete", f, btnRename, {1, 0.3, 0.3})
    btnDelete:SetScript("OnClick", function()
        if f.targetCategory then 
            AN:ShowCustomPopup("CONFIRM", "Delete " .. f.targetCategory .. "?", "", function()
                local target = f.targetCategory
                if AscensionNotesDB.categories then
                    for i, cat in ipairs(AscensionNotesDB.categories) do
                        if cat == target then table.remove(AscensionNotesDB.categories, i); break end
                    end
                end
                if AscensionNotesDB.categoryColors then AscensionNotesDB.categoryColors[target] = nil end
                if AscensionNotesDB.notes then
                    for _, note in ipairs(AscensionNotesDB.notes) do
                        if note.category == target then note.category = nil end
                    end
                end
                if AN.currentFilter == target then AN.currentFilter = nil end
                AN:UpdateSidebar()
                AN:RefreshNoteGrid()
            end)
        end
        f:Hide()
    end)
    
    local closer = CreateFrame("Button", nil, f)
    closer:SetFrameStrata("DIALOG")
    closer:SetFrameLevel(f:GetFrameLevel() - 1)
    closer:SetAllPoints(UIParent)
    closer:SetScript("OnClick", function() f:Hide() end)
    f:SetScript("OnShow", function() closer:Show() end)
    f:SetScript("OnHide", function() closer:Hide() end)

    f:SetHeight(35 * 5)
    self.contextMenu = f
end

-- ----------------------------------------------------------------------------
-- NOTE CONTEXT MENU
-- ----------------------------------------------------------------------------

function AN:CreateNoteContextMenu()
    if self.noteContextMenu then return end
    
    local f = CreateFrame("Frame", "AscensionNoteContextMenu", UIParent, "BackdropTemplate")
    f:SetSize(150, 210) 
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(unpack(AN.COLORS.menu_bg))
    f:SetBackdropBorderColor(unpack(AN.COLORS.window_border))
    f:Hide()

    local function CreateMenuBtn(text, parent, relativeTo, colorOverride)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(150, 35)
        if relativeTo then 
            btn:SetPoint("TOP", relativeTo, "BOTTOM", 0, 0) 
        else 
            btn:SetPoint("TOP", 0, 0) 
        end
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("LEFT", 10, 0)
        btn.text:SetText(text)
        if colorOverride then btn.text:SetTextColor(unpack(colorOverride)) end
        
        btn:SetScript("OnEnter", function(s) 
            if not colorOverride then s.text:SetTextColor(unpack(AN.COLORS.text_highlight)) end
            s.bg = s.bg or s:CreateTexture(nil, "BACKGROUND"); s.bg:SetAllPoints(); s.bg:SetColorTexture(1, 1, 1, 0.1)
        end)
        btn:SetScript("OnLeave", function(s) 
            if not colorOverride then s.text:SetTextColor(unpack(AN.COLORS.text_normal)) end
            if s.bg then s.bg:Hide() s.bg = nil end
        end)
        return btn
    end

    -- 1. Rename
    local btnRename = CreateMenuBtn("Rename", f, nil)
    btnRename:SetScript("OnClick", function()
        if f.targetNote then AN:OpenEditor(f.targetNote) end
        f:Hide()
    end)

    -- 2. Move to Category
    local btnMove = CreateMenuBtn("Move to Category", f, btnRename)
    btnMove:SetScript("OnClick", function()
        if f.targetNote then AN:OpenCategorySelector(f.targetNote) end
        f:Hide()
    end)
    
    -- 3. Move Up
    local btnMoveUp = CreateMenuBtn("Move Up", f, btnMove)
    btnMoveUp:SetScript("OnClick", function()
        if f.targetNote then AN:MoveNoteUp(f.targetNote) end
        f:Hide()
    end)
    
    -- 4. Move Down
    local btnMoveDown = CreateMenuBtn("Move Down", f, btnMoveUp)
    btnMoveDown:SetScript("OnClick", function()
        if f.targetNote then AN:MoveNoteDown(f.targetNote) end
        f:Hide()
    end)

    -- 5. Export
    local btnExport = CreateMenuBtn("Export", f, btnMoveDown)
    btnExport:SetScript("OnClick", function()
        if f.targetNote then
            local fullText = (f.targetNote.title or "") .. "\n" .. (f.targetNote.body or "")
            if AN.ShowCopyPasteWindow then AN:ShowCopyPasteWindow("Export Note", fullText, false) end
        end
        f:Hide()
    end)

    -- 6. Delete
    local btnDelete = CreateMenuBtn("Delete", f, btnExport, {1, 0.3, 0.3})
    btnDelete:SetScript("OnClick", function()
        if f.targetNote then
            local noteTitle = f.targetNote.title or "Untitled"
            AN:ShowCustomPopup("CONFIRM", "Delete Note?", noteTitle, function()
                if AscensionNotesDB.notes then
                    for i, note in ipairs(AscensionNotesDB.notes) do
                        if note.id == f.targetNote.id then
                            table.remove(AscensionNotesDB.notes, i)
                            break
                        end
                    end
                    AN:RefreshNoteGrid()
                end
            end)
        end
        f:Hide()
    end)
    
    -- Closer (Click outside to close)
    local closer = CreateFrame("Button", nil, f)
    closer:SetFrameStrata("DIALOG")
    closer:SetFrameLevel(f:GetFrameLevel() - 1)
    closer:SetAllPoints(UIParent)
    closer:SetScript("OnClick", function() f:Hide() end)
    f:SetScript("OnShow", function() closer:Show() end)
    f:SetScript("OnHide", function() closer:Hide() end)

    self.noteContextMenu = f
end

-- ----------------------------------------------------------------------------
-- SIDEBAR
-- ----------------------------------------------------------------------------

function AN:UpdateSidebar()
    if not self.sidebarScroll then return end
    if not self.contextMenu then self:CreateContextMenu() end

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
            btn:SetSize(AN.CONSTANTS.SIDEBAR_WIDTH, 40)
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            
            btn.bar = btn:CreateTexture(nil, "OVERLAY")
            btn.bar:SetPoint("LEFT", 0, 0)
            btn.bar:SetSize(6, 40)
            btn.bar:Hide()

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
            btn.text:SetPoint("LEFT", 15, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetWidth(150)
            btn.text:SetWordWrap(false)
            
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            btn:SetBackdropColor(0,0,0,0)

            btn:SetScript("OnEnter", function(s) 
                if not s.isActive then s:SetBackdropColor(unpack(AN.COLORS.sidebar_hover)) end 
            end)
            btn:SetScript("OnLeave", function(s) 
                if not s.isActive then s:SetBackdropColor(0, 0, 0, 0) end 
            end)
            
            btn:SetScript("OnClick", function(s, button)
                if button == "RightButton" and s.filterVal ~= nil then
                    if AN.contextMenu then
                        AN.contextMenu.targetCategory = s.filterVal
                        local x, y = GetCursorPosition()
                        local scale = UIParent:GetEffectiveScale()
                        AN.contextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
                        AN.contextMenu:Show()
                    end
                else
                    AN.currentFilter = s.filterVal
                    AN:RefreshNoteGrid()
                    AN:UpdateSidebar()
                    if AN.contextMenu then AN.contextMenu:Hide() end
                end
            end)
            buttons[i] = btn
        end

        local btn = buttons[i]
        btn.text:SetText(label)
        if label == "All Notes" then btn.filterVal = nil else btn.filterVal = label end
        local isActive = (AN.currentFilter == btn.filterVal)
        btn.isActive = isActive

        local customColor = nil
        if label ~= "All Notes" and AscensionNotesDB.categoryColors and AscensionNotesDB.categoryColors[label] then
            customColor = AscensionNotesDB.categoryColors[label]
        end

        if customColor then btn.bar:SetColorTexture(unpack(customColor))
        else btn.bar:SetColorTexture(unpack(AN.COLORS.sidebar_accent)) end

        if isActive then
            btn:SetBackdropColor(unpack(AN.COLORS.sidebar_active)) 
            btn.bar:Show()
        else
            btn:SetBackdropColor(0, 0, 0, 0)
            btn.bar:Hide()
        end
        
        if customColor then btn.text:SetTextColor(unpack(customColor))
        else
            if isActive then btn.text:SetTextColor(unpack(AN.COLORS.text_title))
            else btn.text:SetTextColor(unpack(AN.COLORS.text_dim)) end
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
-- GRID/LIST VIEW
-- ----------------------------------------------------------------------------
function AN:RefreshNoteGrid()
    if not self.mainFrame then return end
    local kids = {self.contentFrame:GetChildren()}
    for _, child in ipairs(kids) do child:Hide() end
    if not self.noteContextMenu then self:CreateNoteContextMenu() end

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

    local availableWidth = self.contentFrame:GetWidth() or 500
    local dynamicCardWidth = availableWidth - 10 -- Small padding
    if dynamicCardWidth < 200 then dynamicCardWidth = 200 end

    for i, note in ipairs(filteredNotes) do
        local name = "AscensionNoteCard_" .. i
        local card = _G[name] or CreateFrame("Button", name, self.contentFrame, "BackdropTemplate")
        
        card:SetSize(dynamicCardWidth, AN.CONSTANTS.CARD_HEIGHT)
        card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        card:SetBackdropColor(unpack(AN.COLORS.card_bg))
        card:SetBackdropBorderColor(unpack(AN.COLORS.card_border))
        card:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(unpack(AN.COLORS.card_hover)) end) 
        card:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(unpack(AN.COLORS.card_border)) end)
        card:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                if AN.noteContextMenu then
                    AN.noteContextMenu.targetNote = note
                    local x, y = GetCursorPosition()
                    local scale = UIParent:GetEffectiveScale()
                    AN.noteContextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
                    AN.noteContextMenu:Show()
                end
            else
                AN:OpenEditor(note)
            end
        end)

        if not card.title then
            card.title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
            card.title:SetPoint("LEFT", 15, 0) 
            card.title:SetJustifyH("LEFT")
        end
        card.title:SetText(note.title or "Untitled")
        card.title:SetTextColor(unpack(AN.COLORS.text_title)) 

        if card.preview then card.preview:Hide() end 

        card:SetPoint("TOPLEFT", 5, -((i-1) * (AN.CONSTANTS.CARD_HEIGHT + AN.CONSTANTS.PADDING)))
        card:Show()
        count = i
    end

    self.contentFrame:SetHeight(math.max(count * (AN.CONSTANTS.CARD_HEIGHT + AN.CONSTANTS.PADDING) + 50, 400))
end

-- ----------------------------------------------------------------------------
-- NOTE LOGIC HELPERS
-- ----------------------------------------------------------------------------

function AN:MoveNoteUp(note)
    if not note or not AscensionNotesDB.notes then return end
    for i, n in ipairs(AscensionNotesDB.notes) do
        if n.id == note.id and i > 1 then
            -- Intercambiar posición con la nota anterior
            AscensionNotesDB.notes[i], AscensionNotesDB.notes[i-1] = AscensionNotesDB.notes[i-1], AscensionNotesDB.notes[i]
            AN:RefreshNoteGrid()
            return
        end
    end
end

function AN:MoveNoteDown(note)
    if not note or not AscensionNotesDB.notes then return end
    for i, n in ipairs(AscensionNotesDB.notes) do
        if n.id == note.id and i < #AscensionNotesDB.notes then
            -- Intercambiar posición con la nota siguiente
            AscensionNotesDB.notes[i], AscensionNotesDB.notes[i+1] = AscensionNotesDB.notes[i+1], AscensionNotesDB.notes[i]
            AN:RefreshNoteGrid()
            return
        end
    end
end

function AN:OpenCategorySelector(note)
    -- Create the selector frame if it doesn't exist
    if not self.catSelectorFrame then
        local f = CreateFrame("Frame", "AscensionCategorySelector", UIParent, "BackdropTemplate")
        f:SetWidth(180) -- Increased width slightly to accommodate scrollbar
        f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true)
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        f:SetBackdropColor(unpack(AN.COLORS.menu_bg))
        f:SetBackdropBorderColor(unpack(AN.COLORS.window_border))
        f:Hide()
        
        -- 1. SCROLL FRAME SETUP
        local scroll = CreateFrame("ScrollFrame", "AscensionCategorySelectorScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 5, -5)
        scroll:SetPoint("BOTTOMRIGHT", -28, 5) -- Space for scrollbar
        
        -- 2. CONTENT FRAME (Holds the buttons)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(145, 100) 
        scroll:SetScrollChild(content)
        
        f.scroll = scroll
        f.content = content
        
        -- Closer invisible (Click outside to close)
        local closer = CreateFrame("Button", nil, f)
        closer:SetFrameStrata("DIALOG")
        closer:SetFrameLevel(f:GetFrameLevel() - 1)
        closer:SetAllPoints(UIParent)
        closer:SetScript("OnClick", function() f:Hide() end)
        f:SetScript("OnShow", function() closer:Show() end)
        f:SetScript("OnHide", function() closer:Hide() end)
        
        -- 3. LINK TO MAIN FRAME (Close this if Main Frame closes)
        if AN.mainFrame then
            AN.mainFrame:HookScript("OnHide", function() 
                f:Hide() 
            end)
        end
        
        self.catSelectorFrame = f
    end

    local f = self.catSelectorFrame
    f.targetNote = note
    local content = f.content
    
    -- Clear old buttons
    if f.buttons then
        for _, btn in ipairs(f.buttons) do btn:Hide() end
    end
    f.buttons = {}

    -- Get Category List
    local cats = { "Uncategorized" }
    if AscensionNotesDB.categories then
        for _, c in ipairs(AscensionNotesDB.categories) do table.insert(cats, c) end
    end

    -- Create buttons dynamically
    local BUTTON_HEIGHT = 30
    local totalHeight = 0
    
    for i, catName in ipairs(cats) do
        -- Recycle or create button
        local btn = f.buttons[i] or CreateFrame("Button", nil, content)
        if not f.buttons[i] then
            btn:SetSize(145, BUTTON_HEIGHT)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 10, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetWidth(125)
            
            -- Hover Effect
            btn:SetScript("OnEnter", function(s) 
                s.text:SetTextColor(unpack(AN.COLORS.text_highlight))
                s.bg = s.bg or s:CreateTexture(nil, "BACKGROUND"); s.bg:SetAllPoints(); s.bg:SetColorTexture(1, 1, 1, 0.1)
            end)
            btn:SetScript("OnLeave", function(s) 
                s.text:SetTextColor(unpack(AN.COLORS.text_normal))
                if s.bg then s.bg:Hide() s.bg = nil end
            end)
            
            -- Logic: Move Note to Category
            btn:SetScript("OnClick", function(s)
                if f.targetNote then
                    f.targetNote.category = (s.catValue ~= "Uncategorized") and s.catValue or nil
                    f.targetNote.updated = date("%Y-%m-%d %H:%M")
                    AN:RefreshNoteGrid()
                end
                f:Hide()
            end)
        end
        
        -- Update button data
        btn.catValue = catName
        btn.text:SetText(catName)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 0, -((i-1) * BUTTON_HEIGHT))
        btn:Show()
        
        -- Store button
        f.buttons[i] = btn
        totalHeight = totalHeight + BUTTON_HEIGHT
    end
    
    -- Set Content Height for scrolling
    content:SetHeight(totalHeight)
    
    -- Calculate Window Height (Max 200px)
    local displayHeight = math.min(totalHeight + 10, 200)
    f:SetHeight(displayHeight)
    
    -- Position at cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    f:Show()
end