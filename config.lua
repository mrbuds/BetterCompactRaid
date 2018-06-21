local addonName, addon = ...

local frame = addon.frame
frame.name = addonName
frame:Hide()

frame:SetScript("OnShow", function(frame)
	local function newCheckbox(label, description, onClick)
		local check = CreateFrame("CheckButton", addonName .. label, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetScript("OnClick", function(self)
			local tick = self:GetChecked()
			onClick(self, tick and true or false)
			if tick then
				PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
			else
				PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
			end
		end)
		check.label = _G[check:GetName() .. "Text"]
		check.label:SetText(label)
		check.tooltipText = label
		check.tooltipRequirement = description
		return check
	end

	local function newSlider(label, description, OnValueChanged)
		local slider = CreateFrame("Slider", addonName .. label, frame, "OptionsSliderTemplate")
		slider:SetScript("OnValueChanged", function(self)
			self:SetValue(math.floor( self:GetValue() ))
			OnValueChanged(self, self:GetValue())
		end)
		slider:SetMinMaxValues(3, 5)
		slider:SetValueStep(1)
		slider:SetStepsPerPage(1)
		slider.text = _G[slider:GetName() .. "Text"]
		slider.low = _G[slider:GetName() .. "Low"]
		slider.high = _G[slider:GetName() .. "High"]
		slider.text:SetText(label)
		slider.low:SetText("3")
		slider.high:SetText("5")
		slider.tooltipText = description
		return slider
	end

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addonName)

	local labels = newCheckbox(
		"Remove Labels",
		"Remove Party & Raid groups labels",
		function(self, value) addon.db.show_label = value end)
	labels:SetChecked(addon.db.show_label)
	labels:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

	local sortGroups = newCheckbox(
		"Sort Groups",
		"Replace default sorting. Sort by role, and then by class with melees class first, then hybrid class and after pure ranged class.",
		function(self, value) addon.db.sortGroups = value end)
	sortGroups:SetChecked(addon.db.sortGroups)
	sortGroups:SetPoint("TOPLEFT", labels, "BOTTOMLEFT", 0, -8)

	local noDpsIcon = newCheckbox(
		"Remove dps icons",
		"Remove dps icons",
		function(self, value) addon.db.noDpsIcon = value end)
	noDpsIcon:SetChecked(addon.db.noDpsIcon)
	noDpsIcon:SetPoint("TOPLEFT", sortGroups, "BOTTOMLEFT", 0, -8)

	local noClamp = newCheckbox(
		"Can move raidframe out of screen",
		"By default the raid frame can't be move out of screen",
		function(self, value) addon.db.noClamp = value end)
	noClamp:SetChecked(addon.db.noClamp)
	noClamp:SetPoint("TOPLEFT", noDpsIcon, "BOTTOMLEFT", 0, -8)

	local numBuffs = newSlider(
		"Buffs",
		"Set how many buffs icons are shown",
		function(self, value) addon.db.numBuffs = value end)
	numBuffs:SetValue(addon.db.numBuffs)
	numBuffs:SetPoint("TOPLEFT", noClamp, "BOTTOMLEFT", 0, -12)
	
	local numDebuffs = newSlider(
		"Debuffs",
		"Set how many debuffs icons are shown",
		function(self, value) addon.db.numDebuffs = value end)
	numDebuffs:SetValue(addon.db.numDebuffs)
	numDebuffs:SetPoint("TOPLEFT", numBuffs, "BOTTOMLEFT", 0, -12)
	
	frame:SetScript("OnShow", nil)
end)

InterfaceOptions_AddCategory(frame)