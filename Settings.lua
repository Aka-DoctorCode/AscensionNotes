-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode 
-- File: Utils.lua
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
-- POPUP DEFINITIONS
-- ----------------------------------------------------------------------------
function AN:ShowCustomPopup(mode, title, initialText, onAccept)
    if not self.popupFrame then
        local f = CreateFrame("Frame", "AscensionPopup", UIParent, "BackdropTemplate")
        f:SetSize(350, 160)
        f:SetPoint("CENTER", 0, 100)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(9999)
        
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        f:SetBackdropColor(unpack(AN.COLORS.bg))
        f:SetBackdropBorderColor(unpack(AN.COLORS.window_border))
        
        -- Title
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.title:SetPoint("TOP", 0, -20)
        f.title:SetTextColor(unpack(AN.COLORS.text_title))
        
        -- EditBox (Only for Input mode)
        f.editBox = CreateFrame("EditBox", nil, f)
        f.editBox:SetSize(300, 30)
        f.editBox:SetPoint("CENTER", 0, 10)
        f.editBox:SetAutoFocus(false)
        AN:StyleInputBox(f.editBox)
        
        -- Buttons
        f.acceptBtn = AN:CreateStyledButton(f, "Accept", "primary")
        f.acceptBtn:SetSize(120, 28)
        f.acceptBtn:SetPoint("BOTTOMLEFT", 40, 20)
        
        f.cancelBtn = AN:CreateStyledButton(f, "Cancel", "normal")
        f.cancelBtn:SetSize(120, 28)
        f.cancelBtn:SetPoint("BOTTOMRIGHT", -40, 20)
        f.cancelBtn:SetScript("OnClick", function() f:Hide() end)
        
        -- Key Handlers
        f.editBox:SetScript("OnEscapePressed", function() f:Hide() end)
        f.editBox:SetScript("OnEnterPressed", function() 
            if f.acceptBtn:IsEnabled() then f.acceptBtn:GetScript("OnClick")(f.acceptBtn) end 
        end)
        
        self.popupFrame = f
    end

    local f = self.popupFrame
    f.mode = mode
    f.onAccept = onAccept
    f.title:SetText(title)
    
    -- Reset State
    f.editBox:SetText(initialText or "")
    f.editBox:ClearFocus()
    
    if mode == "INPUT" then
        f.editBox:Show()
        f:SetHeight(160)
        f.editBox:SetFocus()
        f.editBox:HighlightText()
    elseif mode == "CONFIRM" then
        f.editBox:Hide()
        f:SetHeight(130)
    end
    
    f.acceptBtn:SetText(mode == "CONFIRM" and "Delete" or "Save")
    if mode == "CONFIRM" then 
        -- Style Delete button red
        f.acceptBtn:SetBackdropColor(unpack(AN.COLORS.btn_danger))
    else
        f.acceptBtn:SetBackdropColor(unpack(AN.COLORS.btn_primary))
    end

    f.acceptBtn:SetScript("OnClick", function()
        if f.onAccept then
            f.onAccept(f.editBox:GetText())
        end
        f:Hide()
    end)

    f:Show()
end

-- ----------------------------------------------------------------------------
-- SETTINGS PANEL
-- ----------------------------------------------------------------------------

function AN:SetupBindings()
    local btnToggle = CreateFrame("Button", "ASCENSIONNOTES_TOGGLE_BUTTON", UIParent)
    btnToggle:SetScript("OnClick", function()
        if not AN.mainFrame then AN:CreateMainFrame() end
        if AN.mainFrame then
             if AN.mainFrame:IsShown() then AN.mainFrame:Hide() else AN.mainFrame:Show() end
        end
    end)

    local btnNew = CreateFrame("Button", "ASCENSIONNOTES_NEW_BUTTON", UIParent)
    btnNew:SetScript("OnClick", function() AN:OpenEditor(nil) end)
end

function AN:SetupSettingsPanel()
    if not Settings then return end 

    local panel = CreateFrame("Frame")
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
            if key and key ~= "NONE" then btn:SetText(key) else btn:SetText("Click to Bind") end
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
                if SaveBindings then SaveBindings(GetCurrentBindingSet()) end
                
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