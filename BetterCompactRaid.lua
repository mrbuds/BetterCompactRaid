-- Buds#0500 @ Discord  - https://wago.io/p/Buds
-- https://wago.io/MakeBlizzCompactRaidFramesGreatAgain
-- update: 18/06/2018

local addonName, addon = ...


------------------
local reorder_class = {  -- melee > hybrid > ranged
    --[[ 
1  WARRIOR      1
2  ROGUE        4
3  DEMONHUNTER 12
4  DEATHKNIGHT  6
5  MONK        10
6  PALADIN      2
7  SHAMAN       7
8  DRUID       11
9  PRIEST       5
10  HUNTER      3
11 MAGE         8
12 WARLOCK      9


]]--
    [1] = 1,
    [2] = 6,
    [3] = 10,
    [4] = 2,
    [5] = 9,
    [6] = 4,
    [7] = 7,
    [8] = 11,
    [9] = 12,
    [10] = 5,
    [11] = 8,
    [12] = 3,
    [99] = 99 -- reserved for non player units
}

local function removeGroupLabel(prefix, mode, row)
    if InCombatLockdown() then return end
    local groupFrame = _G[prefix]
    local groupLabelFrame = _G[prefix.."Title"]
    if groupLabelFrame then
        groupLabelFrame:Hide()
        local unit1Frame = _G[prefix.."Member1"]
        local unitFrameHeight = unit1Frame:GetHeight()
        
        if mode == "horizontal" then
            unit1Frame:ClearAllPoints()
            unit1Frame:SetPoint("TOPLEFT",groupFrame,"TOPLEFT",0,0)
            groupFrame:ClearAllPoints()
            groupFrame:SetHeight(unitFrameHeight)
            groupFrame:SetPoint("TOPLEFT",CompactRaidFrameContainer,"TOPLEFT",0,-(row-1)*unitFrameHeight)
        elseif mode == "vertical" then
            unit1Frame:SetPoint("TOP",groupFrame,"TOP",0,0)
        end
    end
end

local function sortGroup(prefix, mode)
    if InCombatLockdown() then return end
    local groupByRole, count = {}, 0
    if mode == "flush" then
        for _,unitFrame in pairs(CompactRaidFrameContainer.flowFrames) do
            if unitFrame and unitFrame.unit and unitFrame:IsVisible() then
                local role = UnitGroupRolesAssigned(unitFrame.unit) or "NONE"
                groupByRole[role] = groupByRole[role] or {}
                table.insert(groupByRole[role], { 
                        unitFrame,
                        reorder_class[select(3, UnitClass(unitFrame.unit)) or 99]
                })
                count = count + 1
            end
        end
    else
        for j=1,5 do
            unitFrame = _G[prefix.."Member"..j]
            if unitFrame and unitFrame:IsVisible() and unitFrame.unit then
                local role = UnitGroupRolesAssigned(unitFrame.unit) or "NONE"
                groupByRole[role] = groupByRole[role] or {}
                table.insert(groupByRole[role], { 
                        unitFrame,
                        reorder_class[select(3, UnitClass(unitFrame.unit)) or 99]
                })
                count = count + 1
            end
        end
    end
    
    if count ~= 0 then
        -- sort each role of groupByRole by class
        for _,v in pairs(groupByRole) do
            table.sort(v, function(a,b)
                    if not a then return false end
                    if not b then return true end
                    return a[2]<b[2]
            end)
        end
        
        local roleValues = { "MAINTANK", "MAINASSIST", "TANK", "HEALER", "DAMAGER", "NONE" }
        local regroup = {} -- concatenate sorted roles in one table
        for _,role in pairs(roleValues) do
            if groupByRole[role] then
                for _,v in pairs(groupByRole[role]) do table.insert(regroup, v) end 
            end
        end
        
        for _,v in pairs(regroup) do
            v[1]:ClearAllPoints()
        end
        
        if mode == "flush" then
            local unitFrameWidth = regroup[1][1]:GetWidth()
            local unitFrameHeight = regroup[1][1]:GetHeight()
            local maxHeight = CompactRaidFrameContainer:GetHeight()
            local i, j = 0, 0
            for _,v in pairs(regroup) do
                local y = unitFrameHeight * i
                v[1]:SetPoint("TOPLEFT", CompactRaidFrameContainer, "TOPLEFT", j*unitFrameWidth, -i*unitFrameHeight)
                if unitFrameHeight*(i+1) >= maxHeight then
                    i, j = 0, j + 1
                else
                    i = i + 1
                end
            end
        else
            local i, prev = 0
            local groupFrame = _G[prefix]
            for _,v in pairs(regroup) do
                i = i + 1
                if i == 1 then
                    if mode == "horizontal" then
                        v[1]:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 0, 0)
                    else
                        v[1]:SetPoint("TOP", groupFrame, "TOP", 0, 0)
                    end
                else
                    if mode == "horizontal" then
                        v[1]:SetPoint("LEFT", prev, "RIGHT", 0, 0)
                    else
                        v[1]:SetPoint("TOP", prev, "BOTTOM", 0, 0)
                    end
                end
                prev = v[1]
            end
        end
    end
end


local function updateCRF()
    if InCombatLockdown() then return end
    if CompactUnitFrameProfiles.selectedProfile then -- return nil when ui is still loading
        local mode
        if CompactRaidFrameContainer.groupMode == "flush" then
            mode = "flush"
        else
            if GetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, 'horizontalGroups') then
                mode = "horizontal"
            else
                mode = "vertical"
            end
        end
        local isParty = not IsInRaid()
        
        if mode ~= "flush" then
            if isParty then
                removeGroupLabel("CompactPartyFrame", mode, 1)
                if addon.db.sortGroups then
                    sortGroup("CompactPartyFrame", mode)
                end
            else
                local usedGroups = {}
                local row = 0
                RaidUtil_GetUsedGroups(usedGroups)
                for groupNum, isUsed in ipairs(usedGroups) do
                    if isUsed then
                        row = row + 1
                        removeGroupLabel("CompactRaidGroup"..groupNum, mode, row)
                        if addon.db.sortGroups then
                            sortGroup("CompactRaidGroup"..groupNum, mode)
                        end
                    end
                end
            end
        else
            if addon.db.sortGroups then
                sortGroup(nil, mode)
            end
        end
        
        
        -- remove clamped to screen
        if addon.db.noClamp then
            CompactRaidFrameManagerContainerResizeFrame:SetClampedToScreen(false)
        end
    end
end

local function hideRoleIcon(frame)
    if InCombatLockdown() then return end
    if addon.db.noDpsIcon and frame and frame.roleIcon then
        local size = frame.roleIcon:GetHeight();
        local role = UnitGroupRolesAssigned(frame.unit)
        if frame.optionTable.displayRoleIcon and role == "DAMAGER" then
            frame.roleIcon:Hide();
            frame.roleIcon:SetSize(1, size);
        end
    end
end

local NATIVE_UNIT_FRAME_HEIGHT = 36;
local NATIVE_UNIT_FRAME_WIDTH = 72;
local CUF_AURA_BOTTOM_OFFSET = 2;
local CUF_NAME_SECTION_SIZE = 15;
local options = DefaultCompactUnitFrameSetupOptions;
local componentScale = min(options.height / NATIVE_UNIT_FRAME_HEIGHT, options.width / NATIVE_UNIT_FRAME_WIDTH);
local buffSize = 11 * componentScale
local buffPos, buffRelativePoint = "BOTTOMRIGHT", "BOTTOMLEFT"
local debuffPos, debuffRelativePoint = "BOTTOMLEFT", "BOTTOMRIGHT"
local powerBarHeight = 8;
local powerBarUsedHeight = options.displayPowerBar and powerBarHeight or 0;


local function maxdebuff(frame)
    if InCombatLockdown() then return end
    local numDebuffs = addon.db.numDebuffs
    frame.maxDebuffs = numDebuffs
    if numDebuffs > #frame.debuffFrames then
        for i=(#frame.debuffFrames+1),numDebuffs do
            if not frame.debuffFrames[i] then
                frame.debuffFrames[i] = CreateFrame("Button", nil, frame, "CompactDebuffTemplate")
                frame.debuffFrames[i]:ClearAllPoints();
                frame.debuffFrames[i]:SetPoint(debuffPos, frame.debuffFrames[i - 1], debuffRelativePoint, 0, 0);
                frame.debuffFrames[i].baseSize = buffSize;
                frame.debuffFrames[i].maxHeight = options.height - powerBarUsedHeight - CUF_AURA_BOTTOM_OFFSET - CUF_NAME_SECTION_SIZE
            end
        end
    end
end

local function maxbuff(frame)
    if InCombatLockdown() then return end
    local numBuffs = addon.db.numBuffs
    frame.maxBuffs = numBuffs
    if numBuffs > #frame.buffFrames then
        for i=(#frame.buffFrames+1),numBuffs do
            if not frame.buffFrames[i] then
                frame.buffFrames[i] = CreateFrame("Button", nil, frame, "CompactBuffTemplate")
                frame.buffFrames[i]:ClearAllPoints();
                frame.buffFrames[i]:SetPoint(buffPos, frame.buffFrames[i - 1], buffRelativePoint, 0, 0);
                frame.buffFrames[i]:SetSize(buffSize, buffSize);
            end
        end
    end
end

local eventFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
eventFrame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
addon.frame = eventFrame

function eventFrame:ADDON_LOADED(loadedAddon)
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    
    if type(bettercompactraidDB) ~= "table" then bettercompactraidDB = {} end
    local sv = bettercompactraidDB
    sv.profileKeys = nil
    sv.profiles = nil
    if type(sv.show_label) ~= "boolean" then sv.show_label = true end
    if type(sv.sortGroups) ~= "boolean" then sv.sortGroups = true end
    if type(sv.noDpsIcon) ~= "boolean" then sv.noDpsIcon = true end
    if type(sv.noClamp) ~= "boolean" then sv.noClamp = true end
    if type(sv.numDebuffs) ~= "number" then sv.numDebuffs = 3 end
    if type(sv.numBuffs) ~= "number" then sv.numBuffs = 5 end
    addon.db = sv

    self.ADDON_LOADED = nil

    hooksecurefunc("CompactUnitFrame_SetMaxBuffs", maxbuff)
    hooksecurefunc("CompactUnitFrame_SetMaxDebuffs", maxdebuff)
    hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", hideRoleIcon)
    hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", updateCRF)
    hooksecurefunc("CompactRaidFrameContainer_OnSizeChanged", updateCRF)
    hooksecurefunc("CompactRaidFrameContainer_OnLoad", updateCRF)
end

function eventFrame:PLAYER_ENTERING_WORLD(loadedAddon)
    updateCRF()
end