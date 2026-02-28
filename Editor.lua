-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode 
-- File: Editor.lua
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

-- ----------------------------------------------------------------------------
-- EDITOR LOGIC
-- ----------------------------------------------------------------------------

function AN:OpenEditor(noteData)
    if not self.editorFrame then
        local f = CreateFrame("Frame", "AscensionNotesEditor", UIParent, "BackdropTemplate")
        f:SetSize(400, 600) 
        f:SetPoint("RIGHT", -50, 0)
        f:SetFrameStrata("DIALOG")
        
        tinsert(UISpecialFrames, "AscensionNotesEditor")
        
        f:SetMovable(true)
        f:SetResizable(true)
        f:SetResizeBounds(350, 400) 
        
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(s) s:StartMoving() end)
        f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
        
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(unpack(AN.COLORS.bg))
        f:SetBackdropBorderColor(unpack(AN.COLORS.window_border)) 
        f:EnableMouse(true)
        
        -- AUTO-SAVE ON HIDE
        f:SetScript("OnHide", function(self)
            if self.isDirty then
                AN:SaveNote(true)
            end
            if AN.autoSaveTimer then AN.autoSaveTimer:Cancel() end
            if AN.catDropdown then
                AN.catDropdown:Hide()
            end
        end)

        -- RESIZE GRIP
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
        end)
        
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        lbl:SetPoint("TOPLEFT", 15, -15)
        lbl:SetText("Edit Note")
        lbl:SetTextColor(unpack(AN.COLORS.text_title))

        -- AUTO SAVE STATUS TEXT
        f.statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.statusText:SetPoint("TOP", 0, -15)
        f.statusText:SetText("")
        f.statusText:SetTextColor(0.5, 0.5, 0.5)

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
        titleBox:SetFrameLevel(f:GetFrameLevel() + 5)
        
        -- QoL: ESC to clear focus
        titleBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        
        -- QoL: TAB or ENTER moves focus to Body
        titleBox:SetScript("OnTabPressed", function(s) 
            if AN.editorFrame and AN.editorFrame.bodyBox then AN.editorFrame.bodyBox:SetFocus() end 
        end)
        titleBox:SetScript("OnEnterPressed", function(s) 
            if AN.editorFrame and AN.editorFrame.bodyBox then AN.editorFrame.bodyBox:SetFocus() end 
        end)
        
        -- AutoSave Trigger
        titleBox:SetScript("OnTextChanged", function(self)
            AN:TriggerAutoSave()
        end)

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
        
        -- QoL: ESC to clear focus
        bodyBox:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)

        -- AutoSave Trigger
        bodyBox:SetScript("OnTextChanged", function(self)
            AN:TriggerAutoSave()
        end)
        
        local bodyBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
        bodyBg:SetPoint("TOPLEFT", scroll, -5, 5)
        bodyBg:SetPoint("BOTTOMRIGHT", scroll, 25, -5)
        bodyBg:SetFrameLevel(scroll:GetFrameLevel() - 1)
        bodyBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=2})
        bodyBg:SetBackdropColor(unpack(AN.COLORS.input_bg))       
        bodyBg:SetBackdropBorderColor(unpack(AN.COLORS.input_border)) 
        
        bodyBox:SetScript("OnEditFocusGained", function(self) bodyBg:SetBackdropBorderColor(unpack(AN.COLORS.input_focus)) end)
        bodyBox:SetScript("OnEditFocusLost", function(self) bodyBg:SetBackdropBorderColor(unpack(AN.COLORS.input_border)) end)
        
        if GameFontHighlightHuge then bodyBox:SetFontObject(GameFontHighlightHuge) else bodyBox:SetFontObject(GameFontHighlight) end
        bodyBox:SetTextInsets(8, 8, 8, 8) 
        bodyBox:SetTextColor(unpack(AN.COLORS.text_normal)) 
        scroll:SetScrollChild(bodyBox)
        f.bodyBox = bodyBox

        f:SetScript("OnSizeChanged", function(self, width, height)
            local scrollWidth = scroll:GetWidth()
            bodyBox:SetWidth(scrollWidth)
        end)

        -- Category Selector
        local catBtn = self:CreateStyledButton(f, "Uncategorized", "normal")
        catBtn:SetSize(140, 26)
        catBtn:SetPoint("BOTTOMRIGHT", -20, 60)
        catBtn:SetFrameLevel(f:GetFrameLevel() + 5) 
        catBtn.arrow = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        catBtn.arrow:SetPoint("RIGHT", -10, 0)
        catBtn.arrow:SetText("v")
        catBtn:SetScript("OnClick", function(self)
            AN:ToggleCategoryDropdown(f, self)
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
        
        -- QoL: ESC to clear focus
        tagInput:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        
        tagInput:SetScript("OnEnterPressed", function(self)
            local text = self:GetText()
            if text and text ~= "" then
                AN:AddTagToCurrentNote(text)
                self:SetText("")
                AN:TriggerAutoSave()
            end
            self:ClearFocus()
        end)
        f.tagInput = tagInput

        f.tagDisplay = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.tagDisplay:SetPoint("LEFT", tagInput, "RIGHT", 5, 0)
        f.tagDisplay:SetTextColor(unpack(AN.COLORS.text_tag))

        -- BOTTOM BUTTON ROW
        local saveBtn = self:CreateStyledButton(f, "Save", "primary")
        saveBtn:SetSize(100, 28)
        saveBtn:SetPoint("BOTTOMRIGHT", -20, 15)
        saveBtn:SetFrameLevel(f:GetFrameLevel() + 5) 
        saveBtn:SetScript("OnClick", function() AN:SaveNote(false) end)

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
    
    -- STATE MANAGEMENT
    if noteData then
        -- EDIT EXISTING NOTE
        self.editorFrame.titleBox:SetText(noteData.title or "")
        self.editorFrame.bodyBox:SetText(noteData.body or "")
        self.editorFrame.categoryBtn.selectedCat = noteData.category
        self.editorFrame.categoryBtn.text:SetText(noteData.category or "Uncategorized")
        self.currentTags = AN:CopyTable(noteData.tags or {})
    else
        -- CREATE NEW NOTE (Optimized Flow)
        local autoTitle = date("Note %Y-%m-%d %H:%M")
        self.editorFrame.titleBox:SetText(autoTitle) -- Default Title
        self.editorFrame.bodyBox:SetText("")
        self.editorFrame.categoryBtn.selectedCat = nil
        self.editorFrame.categoryBtn.text:SetText("Uncategorized")
        self.currentTags = {}
    end
    
    self.editorFrame.isDirty = false 
    self.editorFrame.statusText:SetText("All changes saved")
    self.editorFrame.statusText:SetTextColor(0.5, 0.5, 0.5)
    
    AN:UpdateEditorTags()
    self.editorFrame:Show()
    
    local w = self.editorFrame.bodyBox:GetParent():GetWidth()
    self.editorFrame.bodyBox:SetWidth(w)
    
    -- FOCUS LOGIC
    if not noteData then
        -- If new note: Focus Body directly for speed
        self.editorFrame.bodyBox:SetFocus()
    else
        -- If editing: Clear focus
        self.editorFrame.titleBox:ClearFocus()
        self.editorFrame.bodyBox:ClearFocus()
    end
end

-- ----------------------------------------------------------------------------
-- AUTO SAVE LOGIC
-- ----------------------------------------------------------------------------

function AN:TriggerAutoSave()
    if not self.editorFrame then return end
    
    self.editorFrame.isDirty = true
    self.editorFrame.statusText:SetText("Saving...")
    self.editorFrame.statusText:SetTextColor(1, 0.8, 0) 

    if self.autoSaveTimer then self.autoSaveTimer:Cancel() end
    
    self.autoSaveTimer = C_Timer.NewTimer(2, function()
        AN:SaveNote(true) 
    end)
end

function AN:SaveNote(isAutoSave)
    local title = self.editorFrame.titleBox:GetText()
    local body = self.editorFrame.bodyBox:GetText()
    local category = self.editorFrame.categoryBtn.selectedCat
    local timestamp = date("%Y-%m-%d %H:%M")
    local tagsToSave = AN:CopyTable(self.currentTags or {})

    if title == "" and body == "" then return end

    if self.currentNote then
        self.currentNote.title = title
        self.currentNote.body = body
        self.currentNote.category = category
        self.currentNote.tags = tagsToSave
        self.currentNote.updated = timestamp
    else
        local newNote = {
            id = AN:GenerateID(),
            title = (title ~= "" and title) or "Untitled",
            body = body,
            category = category,
            tags = tagsToSave,
            created = timestamp,
        }
        if not AscensionNotesDB.notes then AscensionNotesDB.notes = {} end
        table.insert(AscensionNotesDB.notes, newNote)
        self.currentNote = newNote 
    end

    self.editorFrame.isDirty = false
    self.editorFrame.statusText:SetText("Saved")
    self.editorFrame.statusText:SetTextColor(0, 1, 0) 
    
    AN:RefreshNoteGrid()

    if not isAutoSave then
        self.editorFrame:Hide()
    end
end

-- ----------------------------------------------------------------------------
-- TAGS & UTILS
-- ----------------------------------------------------------------------------

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

function AN:DeleteCurrentNote()
    if not self.currentNote then return end
    for i, note in ipairs(AscensionNotesDB.notes) do
        if note.id == self.currentNote.id then
            table.remove(AscensionNotesDB.notes, i)
            break
        end
    end
    self.editorFrame:Hide()
    AN:RefreshNoteGrid()
end

function AN:ToggleTemplateMenu()
    if not self.tmplFrame then
        local f = CreateFrame("Frame", nil, self.editorFrame, "BackdropTemplate")
        f:SetSize(180, 100)
        f:SetPoint("TOPRIGHT", self.editorFrame.tmplBtn, "BOTTOMRIGHT", 0, -2)
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        f:SetBackdropColor(unpack(AN.COLORS.menu_bg)) 
        f:SetBackdropBorderColor(unpack(AN.COLORS.window_border)) 
        
        f:SetFrameStrata("FULLSCREEN_DIALOG") 
        f:SetFrameLevel(9999) 
        
        local lastBtn = nil
        for i, tmpl in ipairs(AN.TEMPLATES) do
            local btn = CreateFrame("Button", nil, f)
            btn:SetSize(180, 30)
            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
            txt:SetPoint("LEFT", 10, 0)
            txt:SetText(tmpl.name)
            txt:SetTextColor(unpack(AN.COLORS.text_normal)) 
            
            btn:SetScript("OnEnter", function(s) txt:SetTextColor(unpack(AN.COLORS.text_highlight)) end) 
            btn:SetScript("OnLeave", function(s) txt:SetTextColor(unpack(AN.COLORS.text_normal)) end) 
            
            btn:SetScript("OnClick", function()
                local editBox = AN.editorFrame.bodyBox
                if editBox then
                    local currentText = editBox:GetText() or ""
                    local newText = tmpl.body or ""
                    if currentText ~= "" and string.sub(currentText, -1) ~= "\n" then
                        newText = "\n\n" .. newText
                    elseif currentText ~= "" then
                        newText = "\n" .. newText
                    end
                    editBox:SetText(currentText .. newText)
                    editBox:SetFocus()
                    editBox:SetCursorPosition(string.len(editBox:GetText()))
                    AN:TriggerAutoSave() 
                end
                f:Hide()
            end)
            
            if lastBtn then btn:SetPoint("TOP", lastBtn, "BOTTOM", 0, 0) else btn:SetPoint("TOP", 0, 0) end
            btn:SetPoint("LEFT", 0, 0)
            lastBtn = btn
        end
        f:SetHeight(#AN.TEMPLATES * 30)
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
        f:SetBackdropColor(unpack(AN.COLORS.bg))
        f:SetBackdropBorderColor(unpack(AN.COLORS.window_border))
        
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
        bg:SetBackdropColor(unpack(AN.COLORS.input_bg))       
        bg:SetBackdropBorderColor(unpack(AN.COLORS.input_border)) 
        
        if GameFontHighlightHuge then editBox:SetFontObject(GameFontHighlightHuge) else editBox:SetFontObject(GameFontHighlight) end
        editBox:SetTextInsets(10,10,10,10)
        editBox:SetTextColor(unpack(AN.COLORS.text_normal)) 
        f.editBox = editBox

        local btn = AN:CreateStyledButton(f, "Action", "primary")
        btn:SetSize(120, 30)
        btn:SetPoint("BOTTOM", 0, 10)
        f.actionBtn = btn

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 0, 0)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.title:SetPoint("TOP", 0, -20) 
        f.title:SetTextColor(unpack(AN.COLORS.text_title))
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
                id = AN:GenerateID(), title = newTitle, body = newBody,
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

-- ----------------------------------------------------------------------------
-- IMPORT / EXPORT
-- ----------------------------------------------------------------------------

function AN:ExportCurrentNote()
    if not self.editorFrame then return end
    local title = self.editorFrame.titleBox:GetText()
    local body = self.editorFrame.bodyBox:GetText()
    local fullText = title .. "\n" .. body
    AN:ShowCopyPasteWindow("Export Note (Ctrl+C)", fullText, false)
end

function AN:ShowImportWindow()
    AN:ShowCopyPasteWindow("Import Note", "", true)
end

-- ----------------------------------------------------------------------------
-- CATEGORY DROPDOWN LOGIC
-- ----------------------------------------------------------------------------

function AN:ToggleCategoryDropdown(parent, anchor)
    if not self.catDropdown then
        local f = CreateFrame("Frame", "AscensionCatDropdown", UIParent, "BackdropTemplate")
        f:SetWidth(160)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(unpack(AN.COLORS.menu_bg))
        f:SetBackdropBorderColor(unpack(AN.COLORS.window_border))
        local scroll = CreateFrame("ScrollFrame", "AscensionCatScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 5, -5)
        scroll:SetPoint("BOTTOMRIGHT", -25, 5)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(130, 100)
        scroll:SetScrollChild(content)
        f.scroll = scroll
        f.content = content
        local closer = CreateFrame("Button", nil, f)
        closer:SetFrameStrata("FULLSCREEN_DIALOG")
        closer:SetFrameLevel(f:GetFrameLevel() - 1)
        closer:SetAllPoints(UIParent)
        closer:SetScript("OnClick", function() f:Hide() end)
        f:SetScript("OnShow", function() closer:Show() end)
        f:SetScript("OnHide", function() closer:Hide() end)
        self.catDropdown = f
    end
    
    local d = self.catDropdown
    
    if d:IsShown() then d:Hide() return end
    
    local cats = { "Uncategorized" }
    if AscensionNotesDB.categories then
        for _, c in ipairs(AscensionNotesDB.categories) do table.insert(cats, c) end
    end
    
    if not d.buttons then d.buttons = {} end
    for _, btn in ipairs(d.buttons) do btn:Hide() end
    
    local BUTTON_HEIGHT = 25
    local totalHeight = 0
    
    for i, catName in ipairs(cats) do
        local btn = d.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, d.content)
            btn:SetSize(130, BUTTON_HEIGHT)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 10, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetWidth(110)
            
            btn:SetScript("OnEnter", function(s) 
                s.text:SetTextColor(unpack(AN.COLORS.text_highlight))
                s.bg = s.bg or s:CreateTexture(nil, "BACKGROUND"); s.bg:SetAllPoints(); s.bg:SetColorTexture(1, 1, 1, 0.1)
            end)
            btn:SetScript("OnLeave", function(s) 
                s.text:SetTextColor(unpack(AN.COLORS.text_normal))
                if s.bg then s.bg:Hide() s.bg = nil end
            end)
            
            btn:SetScript("OnClick", function(s)
                local selected = (s.catValue ~= "Uncategorized") and s.catValue or nil
                if AN.editorFrame and AN.editorFrame.categoryBtn then
                    AN.editorFrame.categoryBtn.selectedCat = selected
                    AN.editorFrame.categoryBtn.text:SetText(s.catValue)
                end
                
                AN:TriggerAutoSave()
                d:Hide()
            end)
            
            d.buttons[i] = btn
        end
        
        btn.catValue = catName
        btn.text:SetText(catName)
        btn:SetPoint("TOPLEFT", 0, -((i-1) * BUTTON_HEIGHT))
        btn:Show()
        
        totalHeight = totalHeight + BUTTON_HEIGHT
    end
    
    d.content:SetHeight(totalHeight)
    
    local displayHeight = math.min(totalHeight + 10, 200)
    d:SetHeight(displayHeight)
    
    d:ClearAllPoints()
    d:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
    
    d:Show()
end
