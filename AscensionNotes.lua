-------------------------------------------------------------------------------
-- Project: AscensionNotes
-- Author: Aka-DoctorCode
-- File: AscensionNotes.lua
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
-- INITIALIZATION & EVENT HANDLING
-- ----------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize Database
        if AscensionNotesDB == nil then
            AscensionNotesDB = AN:CopyTable(AN.DefaultDB)
        end
        if AscensionNotesDB.notes == nil then
            AscensionNotesDB.notes = {}
        end
        if AscensionNotesDB.categoryColors == nil then
            AscensionNotesDB.categoryColors = {}
        end
        if AscensionNotesDB.bindings == nil then
            AscensionNotesDB.bindings = { toggle = "NONE", newNote = "NONE" }
        end

        -- Initialize Components
        AN:SetupBindings()
        AN:SetupSettingsPanel()
    elseif event == "PLAYER_LOGIN" then
        -- Restore saved bindings on login
        if AscensionNotesDB and AscensionNotesDB.bindings then
            if AscensionNotesDB.bindings.toggle and AscensionNotesDB.bindings.toggle ~= "NONE" then
                SetBindingClick(AscensionNotesDB.bindings.toggle, "ASCENSIONNOTES_TOGGLE_BUTTON", "LeftButton")
            end
            if AscensionNotesDB.bindings.newNote and AscensionNotesDB.bindings.newNote ~= "NONE" then
                SetBindingClick(AscensionNotesDB.bindings.newNote, "ASCENSIONNOTES_NEW_BUTTON", "LeftButton")
            end
        end
    end
end)

-- ----------------------------------------------------------------------------
-- SLASH COMMANDS
-- ----------------------------------------------------------------------------

SLASH_ASCENSIONNOTES1 = "/an"
SlashCmdList["ASCENSIONNOTES"] = function(msg)
    if not AN.mainFrame then AN:CreateMainFrame() end
    if AN.mainFrame then
        if AN.mainFrame:IsShown() then
            AN.mainFrame:Hide()
        else
            AN.mainFrame:Show()
        end
    end
end
