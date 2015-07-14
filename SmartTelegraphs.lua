-----------------------------------------------------------------------------------------------
-- Client Lua Script for SmartTelegraphs
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"
 
-----------------------------------------------------------------------------------------------
-- SmartTelegraphs Module Definition
-----------------------------------------------------------------------------------------------
local SmartTelegraphs = {}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function SmartTelegraphs:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

	self.config = {}

	self.config.version = {
		major = 0,
  		minor = 2,
  		patch = 0
	}

	self.config.lastTab = 1
	self.config.showSmallFloat = false
	self.config.defaultColor = {
			colorName = "CRB_RED",
			r = 255,
			g = 0,
			b = 0,
			fo = 100,
			oo = 100
		}

	self.data = {
		zones = {},
		colors = {}
	}

	self.data.zones[0] = {
				zoneName = "Default",
				subzoneName = "",
				colorId = "255|0|0"
			} 

	self.updateZoneId = nil
	
	self.config.rtname = "spell.custom1EnemyNPCDetrimentalTelegraphColorR"
	self.config.gtname = "spell.custom1EnemyNPCDetrimentalTelegraphColorG"
	self.config.btname = "spell.custom1EnemyNPCDetrimentalTelegraphColorB"
	self.config.fotname = "spell.fillOpacityCustom1_34"
	self.config.ootname = "spell.outlineOpacityCustom1_34"

    return o
end

function SmartTelegraphs:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs OnLoad
-----------------------------------------------------------------------------------------------
function SmartTelegraphs:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("SmartTelegraphs.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs OnDocLoaded
-----------------------------------------------------------------------------------------------
function SmartTelegraphs:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "SmartTelegraphsForm", nil, self)
		self.wndFloat = Apollo.LoadForm(self.xmlDoc, "SmartTelegraphsFloat", nil, self)
		-- self.wndSmallFloat = Appolo.LoadForm(self.xmlDoc, "SmartTelegraphsSmallFloat", nil, self) TODO Create and fix this
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		elseif self.wndFloat == nil then
			Apollo.AddAddonErrorText(self, "Could not load the floater for some reason.")
			return
			--[[
		elseif self.wndSmallFloat == nil then
			Apollo.AddAddonErrorText(self, "Could not load the floater for some reason.")
			return
			]]--
		end
		
	  	self.wndMain:Show(false, true)
		self.wndFloat:Show(true, true)
		-- self.wndSmallFloat:Show(false, true)

		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("st", 						"OnSmartTelegraphsOn", self)
		--Apollo.RegisterEventHandler("VarChange_ZoneName", 		"OnChangeZoneName", self)
		Apollo.RegisterEventHandler("SubZoneChanged", 			"OnChangeZoneName", self)

		-- Check if offsets exist
		if self.config ~= nil then
			if self.config.mainWindowOffset and self.config.mainWindowOffset ~= nil then
				self.wndMain:SetAnchorOffsets(unpack(self.config.mainWindowOffset))
			end
			if self.config.floatWindowOffset and self.config.floatWindowOffset ~= nil then
				self.wndFloat:SetAnchorOffsets(unpack(self.config.floatWindowOffset))
			end
			--[[
			if self.config.smallFloatWindowOffset and self.config.smallFloatWindowOffset ~= nil then
				self.wndFloat:SetAnchorOffsets(unpack(self.config.smallFloatWindowOffset))
			end
			]]--
		end


		--- Main window ---
		self.main = {}

		self.main.zoneConfigArea = self.wndMain:FindChild("ZoneConfigArea")
		self.main.zoneTab = self.wndMain:FindChild("btnZoneTab")
		self.main.colorConfigArea = self.wndMain:FindChild("ColorsConfigArea")
		self.main.colorTab = self.wndMain:FindChild("btnColorTab")

		self.main.listArea = self.wndMain:FindChild("ListArea")

		self.main.zoneNameDisplay = self.wndMain:FindChild("ZoneNameDisplay")
		self.main.subZoneNameDisplay = self.wndMain:FindChild("SubzoneNameDisplay")

		self.main.colorName = self.wndMain:FindChild("ColorNameEditBox")
		self.main.colorDisplay = self.wndMain:FindChild("ColorDisplay")
		self.main.REditBox = self.wndMain:FindChild("REditBox")
		self.main.GEditBox = self.wndMain:FindChild("GEditBox")
		self.main.BEditBox = self.wndMain:FindChild("BEditBox")
		self.main.IFEditBox = self.wndMain:FindChild("IFEditBox")
		self.main.OFEditBox = self.wndMain:FindChild("OFEditBox")

		--- Floater ---
		self.float = {}

		self.float.presetList = self.wndFloat:FindChild("wndPresetList")
		self.float.presetList:Show(false, true)
		self.float.txtZone = self.wndFloat:FindChild("wndPresetZoneText")
		self.float.txtSubzone = self.wndFloat:FindChild("wndPresetSubzoneText")
		self.float.colorDisplay = self.wndFloat:FindChild("wndPresetColorDisplay")

		--- Small floater ---
		self.smallFloat = {}
		--self.smallFloat.colorDisplay = nil

		self:UpdateUI()
	end
end

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs General Events
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/st"
function SmartTelegraphs:OnSmartTelegraphsOn()
	if not self.wndMain:IsShown() then
		self:UpdateUI()

		if self.config.lastTab ~= nil and self.config.lastTab then
			self:ShowTab(self.config.lastTab)
		else
			self:ShowTab(1)
		end

		self.wndMain:Invoke()
	else
		self.wndMain:Close()
	end
end

-- oVar = ID, strNewZone = Name
function SmartTelegraphs:OnChangeZoneName(oVar, strNewZone)
	Apollo.SetConsoleVariable("spell.telegraphColorSet", 4)

	if oVar ~= "ZoneName" then
		self:UpdateUI()
	end
	--[[
	local tZoneId = GameLib.GetCurrentZoneId()
	local tWorldId = GameLib.GetCurrentWorldId()
	local tZone = GameLib.GetCurrentZoneMap()
	local tZoneName = tZone.strName
	local tSubzoneName = GetCurrentSubZoneName()

	Print("WorldId: " .. tWorldId)
	Print("ContinentId: " .. tZone.continentId)
	Print("ZoneId: " .. tZone.id .. " | ZoneName: "  .. tZoneName)
	Print("SubzoneId: " .. tZoneId .. " | SubzoneName: " .. tSubzoneName )
	Print("ParentZoneId: " .. tZone.parentZoneId .. " | strFolder: " .. tZone.strFolder)
	]]--
end

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs Functions
-----------------------------------------------------------------------------------------------

function SmartTelegraphs:UpdateUI()
	local tZone = GameLib.GetCurrentZoneMap()
	local zone = self:GetZone(tZone.id)

	-- Main Window
	if self.wndMain:IsShown() then
		if self.config.lastTab ~= nil and self.config.lastTab then
			self:ShowTab(self.config.lastTab)
		else
			self:ShowTab(1)
		end
	end
	-- Floater
	self:UpdateFloaterWindow(zone)
	-- Telegraphs
	self:UpdateTelegraphs()
end

function SmartTelegraphs:UpdateTelegraphs()
	local tZone = GameLib.GetCurrentZoneMap()
	local zone = self:GetZone(tZone.id)

	self:SetTelegraphColors(zone.colorId)
end

function SmartTelegraphs:SetTelegraphColors(colorId)
	local color = self:GetColor(colorId)
	
	Apollo.SetConsoleVariable("spell.telegraphColorSet", 4)
	Apollo.SetConsoleVariable(self.config.rtname, color.r)
	Apollo.SetConsoleVariable(self.config.gtname, color.g)
	Apollo.SetConsoleVariable(self.config.btname, color.b)
	Apollo.SetConsoleVariable(self.config.fotname, color.fo)
	Apollo.SetConsoleVariable(self.config.ootname, color.oo)
		
	GameLib.RefreshCustomTelegraphColors()
end

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs UI
-----------------------------------------------------------------------------------------------

function SmartTelegraphs:UpdateZoneConfigArea()
	local tZoneId = GameLib.GetCurrentZoneId()
	local tWorldId = GameLib.GetCurrentWorldId()
	local tZone = GameLib.GetCurrentZoneMap()
	local tZoneName = tZone.strName
	local tSubzoneName = GetCurrentSubZoneName()

	--local color = self:GetColor("||")

	-- Folder
	self.main.zoneNameDisplay:SetText(tZoneName)
	self.main.subZoneNameDisplay:SetText(tSubzoneName)
end

function SmartTelegraphs:UpdateColorConfigArea()
	local tZoneId = GameLib.GetCurrentZoneId()
	local zone = self:GetZone(tZoneId)
	local color = self:GetColor(zone.colorId)

	self.main.colorName:SetText(color.colorName)

	self.main.REditBox:SetText(color.r)
	self.main.GEditBox:SetText(color.g)
	self.main.BEditBox:SetText(color.b)
	self.main.IFEditBox:SetText(color.fo)
	self.main.OFEditBox:SetText(color.oo)

	self.main.colorDisplay:SetBGColor(self:CreateCColor(color))
end

function SmartTelegraphs:UpdateFloaterWindow(zone)
	local color = self:GetColor(zone.colorId)

	if not self.config.showSmallFloat then
		self.float.txtZone:SetText(zone.zoneName)
		self.float.txtSubzone:SetText("") -- zone.subzoneName
		self.float.colorDisplay:SetBGColor(self:CreateCColor(color))
	else
		self.smallFloat.colorDisplay:SetBGColor(self:CreateCColor(color))
	end
end


function SmartTelegraphs:OpenMainWindow()
	if self.wndMain == nil then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "SmartTelegraphsForm", nil, self)
	end
	
	self.wndMain:Invoke()	
end


-----------------------------------------------------------------------------------------------
-- SmartTelegraphsForm Functions
-----------------------------------------------------------------------------------------------
function SmartTelegraphs:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
		
	local tData = {}
	
	self.config.mainWindowOffset = { self.wndMain:GetAnchorOffsets() }
	self.config.floatWindowOffset = { self.wndFloat:GetAnchorOffsets() }
	-- self.config.smallFloatWindowOffset = { self.wndSmallFloat:GetAnchorOffsets() } TODO Create and enable this

	tData.config = self:DeepCopy(self.config)
	tData.data = self:DeepCopy(self.data)
	
	return tData 
end

function SmartTelegraphs:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	
	if tData.config then
		self.config = self:DeepCopy(tData.config)
	end

	if tData.data then
		self.data = self:DeepCopy(tData.data)
	end
end

function SmartTelegraphs:OnCloseButtonPressed( wndHandler, wndControl, eMouseButton )
	self.main.zoneNameDisplay:SetText("")
	self.main.subZoneNameDisplay:SetText("")
	self.wndMain:Close()
end

-- TODO should probably do a wrapper function for getting color from ui
function SmartTelegraphs:OnColorEditBoxChanged( wndHandler, wndControl, strText )
	local value = tonumber(strText)
	if value ~= nil then
		if value > 255 then
			wndControl:SetText(255)
		elseif value < 0 then
			wndControl:SetText(0)
		end
	else
		wndControl:SetText(0)
	end
	
	local r = tonumber(self.main.REditBox:GetText()) / 255.0
	local g = tonumber(self.main.GEditBox:GetText()) / 255.0
	local b = tonumber(self.main.BEditBox:GetText()) / 255.0
	local fo = tonumber(self.main.IFEditBox:GetText()) / 100.0
	local of = tonumber(self.main.OFEditBox:GetText()) / 100.0
	
	self.main.colorDisplay:SetBGColor(CColor.new(r, g, b, fo))
end

function SmartTelegraphs:OnOpacityEditBoxChanged( wndHandler, wndControl, strText )
	local value = tonumber(strText)
	if value ~= nil then
		if value > 100 then
			wndControl:SetText(100)
		elseif value < 0 then
			wndControl:SetText(0)
		end
	else
		wndControl:SetText(0)
	end

	local r = tonumber(self.main.REditBox:GetText()) / 255.0
	local g = tonumber(self.main.GEditBox:GetText()) / 255.0
	local b = tonumber(self.main.BEditBox:GetText()) / 255.0
	local fo = tonumber(self.main.IFEditBox:GetText()) / 100.0
	local of = tonumber(self.main.OFEditBox:GetText()) / 100.0
	
	self.main.colorDisplay:SetBGColor(CColor.new(r, g, b, fo))
end

function SmartTelegraphs:DrawZoneItem(zoneId)
	local newZoneItem = Apollo.LoadForm(self.xmlDoc,"ZoneTemplateFrame", self.main.listArea, self)	
	
	local zone = self:GetZone(zoneId)

	newZoneItem:SetData(zoneId)
	newZoneItem:SetName("zone_" .. zoneId)

	local txtZoneName = newZoneItem:FindChild("txtZoneName")
	txtZoneName:SetTextRaw(zone.zoneName);
	
	local txtSubzoneName = newZoneItem:FindChild("txtSubzoneName")
	txtSubzoneName:SetTextRaw(zone.subzoneName);
	
	local color = self:GetColor(zone.colorId)

	local txtColorName = newZoneItem:FindChild("txtColorName")
	txtColorName:SetText(color.colorName)

	local colorDisplay = newZoneItem:FindChild("ColorDisplay")
	colorDisplay:SetBGColor(self:CreateCColor(color));

	local removeButton = newZoneItem:FindChild("btnRemoveZone")

	if zoneId == 0 then
		removeButton:Show(false, true)
	end
	
	self.main.listArea:ArrangeChildrenVert()
end

function SmartTelegraphs:DrawColorItem(colorId)
	local newColorItem = Apollo.LoadForm(self.xmlDoc,"ColorTemplateFrame", self.main.listArea, self)	

	local color = self:GetColor(colorId)

	newColorItem:SetData(colorId)
	newColorItem:SetName("color_" .. colorId)
	
	local txtColorName = newColorItem:FindChild("txtColorName")
	txtColorName:SetText(color.colorName)
	
	local colorDisplay = newColorItem:FindChild("ColorDisplay")
	colorDisplay:SetBGColor(self:CreateCColor(color));
	
	self.main.listArea:ArrangeChildrenVert()
end

function SmartTelegraphs:DrawFloatListItem(colorId)
	local newColorItem = Apollo.LoadForm(self.xmlDoc,"ColorFloatItemTemplateFrame", self.float.presetList, self)	

	local color = self:GetColor(colorId)

	newColorItem:SetData(colorId)
	newColorItem:SetName("color_" .. colorId)
	
	local txtColorName = newColorItem:FindChild("txtColorName")
	txtColorName:SetText(color.colorName)
	
	local colorDisplay = newColorItem:FindChild("ColorDisplay")
	colorDisplay:SetBGColor(self:CreateCColor(color));
	
	self.float.presetList:ArrangeChildrenVert()
end

function SmartTelegraphs:OnSaveColorButton( wndHandler, wndControl, eMouseButton )

	local r = self.main.REditBox:GetText()
	local g = self.main.GEditBox:GetText()
	local b = self.main.BEditBox:GetText()
	
	local colorHash = r .. "|" .. g .. "|" .. b
		
	self.data.colors[colorHash] = {
		colorName = self.main.colorName:GetText(),
		r = r,
		g = g,
		b = b,
		fo = 100,
		oo = 100
	}

	self:UpdateColorList()
end

function SmartTelegraphs:OnCheckZoneTab( wndHandler, wndControl, eMouseButton )
	self:ShowTab(1);
end

function SmartTelegraphs:OnCheckColorTab( wndHandler, wndControl, eMouseButton )
	self:ShowTab(2);
end

function SmartTelegraphs:OnCheckSettingsTab( wndHandler, wndControl, eMouseButton )
	self:ShowTab(3);
end

function SmartTelegraphs:ShowTab(nTab)
	if nTab < 1 or nTab > 2 then return end
	
	self.main.zoneConfigArea:Show(nTab == 1, true)
	self.main.zoneTab:SetCheck(nTab == 1)
	self.main.colorConfigArea:Show(nTab == 2, true)
	self.main.colorTab:SetCheck(nTab == 2)

	if nTab == 1 then
		self:UpdateZoneConfigArea()
		self:UpdateZoneList()		
	elseif nTab == 2 then
		self:UpdateColorConfigArea()
		self:UpdateColorList()
	end

	self.config.lastTab = nTab
end

function SmartTelegraphs:UpdateZoneList()
	self.main.listArea:DestroyChildren()

	for i, peCurrent in pairs(self.data.zones) do
		self:DrawZoneItem(i)
	end
end

function SmartTelegraphs:UpdateColorList()
	self.main.listArea:DestroyChildren()

	for i, peCurrent in pairs(self.data.colors) do
		self:DrawColorItem(i)
	end
end

function SmartTelegraphs:UpdateFloatList()
	self.float.presetList:DestroyChildren()

	for i, peCurrent in pairs(self.data.colors) do
		self:DrawFloatListItem(i)
	end
end

function SmartTelegraphs:OnSaveZoneButton( wndHandler, wndControl, eMouseButton )
	local tZone = GameLib.GetCurrentZoneMap()

	self.data.zones[tZone.id] = {
				zoneName = tZone.strName,
				subzoneName = "",
				colorId = "||"
			}

	self:UpdateZoneList()
end

---------------------------------------------------
-- Floater Event Handling
---------------------------------------------------

function SmartTelegraphs:OnFloatClick( wndHandler, wndControl, eMouseButton )
	if wndControl ~= self.wndFloat then return end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		self:UpdateFloatList()
		self.float.presetList:Show(true, true)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Right  then
		SmartTelegraphs:OnSmartTelegraphsOn()
	end
end

function SmartTelegraphs:OnFloatListItemClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local colorId = wndControl:GetParent():GetData()

		local tZone = GameLib.GetCurrentZoneMap()

		local zone = {
				zoneName = tZone.strName,
				subzoneName = "",
				colorId = colorId
			}

		self.data.zones[tZone.id] = zone

		self:UpdateFloaterWindow(zone)
		self:ShowTab(self.config.lastTab)
		self:UpdateTelegraphs()
	end
end

---------------------------------------------------
-- Delete a Zone
---------------------------------------------------
function SmartTelegraphs:OnDeleteZone(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local zoneId = wndControl:GetParent():GetData()
		if zoneId ~= 0 then
			self:DeleteZone(zoneId);
		end
	end
end

function SmartTelegraphs:DeleteZone(zoneId)
	self.data.zones[zoneId] = nil
	
	local zoneId = GameLib.GetCurrentZoneId()
	
	local zone = self:GetZone(zoneId)

	self:SetTelegraphColors(zone.colorId)
	self:UpdateZoneList();
end

---------------------------------------------------
-- Delete a Color
---------------------------------------------------
function SmartTelegraphs:OnDeleteColor(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local colorId = wndControl:GetParent():GetData()
		self:DeleteColor(colorId);
	end
end

function SmartTelegraphs:DeleteColor(colorId)
	self.data.colors[colorId] = nil
	self:UpdateColorList();
end

---------------------------------------------------
-- Update a Zone
---------------------------------------------------

function SmartTelegraphs:UpdateZone(zoneId)
	self.updateZoneId = zoneId
	self:SetUiZone(zoneId)
end

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs Util
-----------------------------------------------------------------------------------------------

function SmartTelegraphs:SetDefaultColor(color)
	self.config.defaultColor = color
end

function SmartTelegraphs:GetZone(zoneId)
	local zone = self.data.zones[zoneId]

	if zone == nil then
		local tZone = GameLib.GetCurrentZoneMap()
		zone = {
			zoneName = tZone.strName,
			subzoneName = "Subzone",
			color = "||"
		}
	end

	return zone
end

function SmartTelegraphs:GetColor(colorId)
	local color = self.data.colors[colorId]

	if color == nil then
		color = self.config.defaultColor
	end

	return color
end

function SmartTelegraphs:CreateCColor(color)	
	local color = CColor.new(
				color.r / 255.0, 
				color.g / 255.0, 
				color.b / 255.0, 
				color.fo / 100.0
			)

	return color
end

function SmartTelegraphs:DeepCopy(t)
	if type(t) == "table" then
		local copy = {}
		for k, v in next, t do
			copy[self:DeepCopy(k)] = self:DeepCopy(v)
		end
		return copy
	else
		return t
	end
end

function SmartTelegraphs:TableLength(tTable)
	if tTable == nil then return 0 end
  	local count = 0
  	for _ in pairs(tTable) do count = count + 1 end
  	return count
end 

-----------------------------------------------------------------------------------------------
-- SmartTelegraphs Instance
-----------------------------------------------------------------------------------------------
local SmartTelegraphsInst = SmartTelegraphs:new()
SmartTelegraphsInst:Init()