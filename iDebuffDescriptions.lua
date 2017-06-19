local addon = CreateFrame('Frame')
addon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)
addon:RegisterUnitEvent('UNIT_AURA', 'player', 'target')
addon:RegisterEvent('ADDON_LOADED')
addon:RegisterUnitEvent('UNIT_TARGET', 'player')
local iDD = {}
iDD.backdrop = {
	bgFile = 'Interface\\Buttons\\WHITE8x8',
	edgeFile = 'Interface\\Buttons\\WHITE8x8',
	edgeSize = 1,
	insets = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}
}
local debuffTypes = {
	['Disease'] = true,
	['Poison'] = true,
	['Curse'] = true,
	['Magic'] = true,
}
local font = NumberFont_Shadow_Small:GetFont()
local fontSize = 11
local fontFlags
iDD.frames = {['player'] = {}, ['target'] = {}, ['anchorFrames'] = {}}
iDD.frames.anchorFrames.player = CreateFrame('Frame', nil, UIParent)
iDD.frames.anchorFrames.player:SetSize(5,5)
iDD.frames.anchorFrames.player:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -2, -2)
iDD.frames.anchorFrames.target = CreateFrame('Frame', nil, UIParent)
iDD.frames.anchorFrames.target:SetSize(5,5)
iDD.frames.anchorFrames.target:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -266, -2)

function iDD:setFrame(frameID, data, unit)
	local frames
	local anchorFrame
	if unit == 'player' then
		frames = iDD.frames.player
		anchorFrame = iDD.frames.anchorFrames.player
	elseif unit == 'target' then
		frames = iDD.frames.target
		anchorFrame = iDD.frames.anchorFrames.target
	else 
		return
	end
	if not frames[frameID] then
		local f
		if frameID > 1 then
			frames[frameID] = CreateFrame('Frame', nil, frames[frameID-1])
			f = frames[frameID]
			f:SetPoint('TOPRIGHT', frames[frameID-1], 'BOTTOMRIGHT', 0,-2)
		else
			frames[frameID] = CreateFrame('Frame', nil, anchorFrame)
			f = frames[frameID]
			f:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0,0)
		end
		f:SetSize(200, 30)
		f:SetBackdrop(iDD.backdrop)
		f:SetBackdropColor(0.1,0.1,0.1,0.8)
		f:SetBackdropBorderColor(0,0,0,1)
		
		f.icon = CreateFrame('Frame', nil, f)
		f.icon:SetSize(30,30)
		if unit == 'player' then
			f.icon:SetPoint('TOPRIGHT', f, 'TOPLEFT', -1, 0)
		elseif unit == 'target' then
			f.icon:SetPoint('TOPLEFT', f, 'TOPRIGHT', 1, 0)
		end
		f.icon.tex = f.icon:CreateTexture()
		f.icon.tex:SetAllPoints(f.icon)
		
		f.text = f:CreateFontString()
		f.text:SetFont(font, fontSize, fontFlags)
		f.text:SetPoint('TOPLEFT', f, 'TOPLEFT', 2, -2)
		f.text:SetWidth(198)
		f.text:SetJustifyH('LEFT')
		f:EnableMouse(true)
		f:SetScript('OnMouseDown', function()
			if IsShiftKeyDown() then
				iDebuffDescriptionsDB.ignored[f.data.spellID] = true
				print(string.format('Ignored: %s (%s).',f.data.spellName, f.data.spellID))
				addon:UNIT_AURA(unit)
			else
				print(f.data.spellName, f.data.spellID)
			end
		end)
	end
	local f = frames[frameID]
	f:Show()
	f.text:SetText(data.text)
	f.icon.tex:SetTexture(data.icon)
	f.data = {['spellName'] = data.name, ['spellID'] = data.spellID}
	f:SetHeight(math.max(f.text:GetHeight()+4, 30))
	if debuffTypes[data.auraType] then
		local c = DebuffTypeColor[data.auraType]
		f:SetBackdropBorderColor(c.r,c.g,c.b,1)
	else
		f:SetBackdropBorderColor(0,0,0,1)
	end
end

function iDD:GetDesc(debuffID, spellIDToFind, unit)
	if not iDD.dummyTooltip then
		iDD.dummyTooltip = CreateFrame('GameTooltip', 'iDebuffDescriptionsDummyTooltip', UIParent, 'GameTooltipTemplate')
	end
	iDD.dummyTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	if unit == 'player' then
		if spellIDToFind then
			for i = 1, 40 do
				local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, spellID = UnitDebuff('player', i)
				if spellIDToFind == spellID then
					iDD.dummyTooltip:SetUnitDebuff('player', i)
					local text = iDebuffDescriptionsDummyTooltipTextLeft2:GetText()
					iDD.dummyTooltip:Hide()
					return text
				end
			end
		elseif debuffID then
			local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, spellID = UnitDebuff('player', debuffID)
			if name then 
				iDD.dummyTooltip:SetUnitDebuff('player', debuffID)
				local text = iDebuffDescriptionsDummyTooltipTextLeft2:GetText()
				iDD.dummyTooltip:Hide()			
				return text
			else 
				return 'Something failed'
			end
		end
	elseif unit == 'target' then
		if spellIDToFind then
			for i = 1, 40 do
				local name, _, icon, count, buffType, duration, expirationTime, _, _, _, spellID = UnitBuff('target', i)
				if spellIDToFind == spellID then
					iDD.dummyTooltip:SetUnitBuff('player', i)
					local text = iDebuffDescriptionsDummyTooltipTextLeft2:GetText()
					iDD.dummyTooltip:Hide()
					return text
				end
			end
		elseif debuffID then
			local name, _, icon, count, buffType, duration, expirationTime, _, _, _, spellID = UnitBuff('target', debuffID)
			if name then 
				iDD.dummyTooltip:SetUnitBuff('target', debuffID)
				local text = iDebuffDescriptionsDummyTooltipTextLeft2:GetText()
				iDD.dummyTooltip:Hide()
				return text
			else 
				return 'Something failed'
			end
		end
	end
end
function addon:UNIT_AURA(unitID)
	-- unit should always be player, atleast for now
	if not unitID then return end
	if unitID == 'player' then
		local descCounter = 1
		for i = 1, 40 do
			local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, spellID = UnitDebuff('player', i)
			if name then
				if not iDebuffDescriptionsDB.ignored[spellID] then
					local text = iDD:GetDesc(i, nil, unitID)
					iDD:setFrame(descCounter,{
						['name'] = name,
						['icon'] = icon,
						['auraType'] = debuffType,
						['spellID'] = spellID,
						['text'] = text,
					}, unitID)
					descCounter = descCounter + 1
				end
			end
		end
		for i = descCounter, #iDD.frames.player do
			iDD.frames.player[i]:Hide()
		end
	elseif unitID == 'target' then
		local descCounter = 1
		for i = 1, 40 do
			local name, _, icon, count, buffType, duration, expirationTime, _, _, _, spellID = UnitBuff('target', i)
			if name then
				if not iDebuffDescriptionsDB.ignored[spellID] then
					local text = iDD:GetDesc(i, nil, unitID)
					iDD:setFrame(descCounter,{
						['name'] = name,
						['icon'] = icon,
						['auraType'] = buffType,
						['spellID'] = spellID,
						['text'] = text,
					}, unitID)
					descCounter = descCounter + 1
				end
			end
		end
		for i = descCounter, #iDD.frames.target do
			iDD.frames.target[i]:Hide()
		end
	end
end
function addon:UNIT_TARGET(unitID) -- currently only player
	addon:UNIT_AURA('target')
end
function addon:ADDON_LOADED(addonName)
	if addonName and addonName == 'iDebuffDescriptions' then
		iDebuffDescriptionsDB = iDebuffDescriptionsDB or {['ignored'] = {}}
	end
end