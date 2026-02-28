-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode 
-- File: Utils.lua
-- Version: @project-version@
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
-- DATA HELPERS
-- ----------------------------------------------------------------------------

function AN:CopyTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then dest[k] = AN:CopyTable(v, dest[k]) else dest[k] = v end
        end
    end
    return dest
end

function AN:GenerateID()
    return GetTime() .. "-" .. random(1000, 9999)
end

-- ----------------------------------------------------------------------------
-- UI WIDGET FACTORIES
-- ----------------------------------------------------------------------------

function AN:CreateStyledButton(parent, text, colorType)
    if not parent then return nil end

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2 
    })
    
    local normalColor = AN.COLORS.btn_normal
    if colorType == "primary" then normalColor = AN.COLORS.btn_primary end
    if colorType == "danger" then normalColor = AN.COLORS.btn_danger end
    
    btn:SetBackdropColor(unpack(normalColor))
    btn:SetBackdropBorderColor(unpack(AN.COLORS.btn_border)) 
    
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
    
    if GameFontHighlightHuge then
        editBox:SetFontObject(GameFontHighlightHuge)
    else
        editBox:SetFontObject(GameFontHighlight)
    end
    
    editBox:SetTextColor(unpack(AN.COLORS.text_normal)) 
    editBox:SetTextInsets(8, 8, 2, 2) 
    
    if not editBox.bg then
        local bg = CreateFrame("Frame", nil, editBox, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", -2, 2)
        bg:SetPoint("BOTTOMRIGHT", 2, -2)
        
        -- Prevent error assigning boolean/nil to frame level logic
        local level = editBox:GetFrameLevel() or 1
        bg:SetFrameLevel(math.max(1, level - 1))
        
        bg:SetBackdrop({ 
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            edgeFile = "Interface\\Buttons\\WHITE8x8", 
            edgeSize = 2
        })
        
        bg:SetBackdropColor(unpack(AN.COLORS.input_bg))       
        bg:SetBackdropBorderColor(unpack(AN.COLORS.input_border)) 
        editBox.bg = bg

        editBox:SetScript("OnEditFocusGained", function(self) 
            self.bg:SetBackdropBorderColor(unpack(AN.COLORS.input_focus)) 
        end)
        editBox:SetScript("OnEditFocusLost", function(self) 
            self.bg:SetBackdropBorderColor(unpack(AN.COLORS.input_border)) 
        end)
    end
end
