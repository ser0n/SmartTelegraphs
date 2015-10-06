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
  		minor = 4,
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
		self.wndColorPicker = Apollo.LoadForm(self.xmlDoc, "SmartTelegraphsColorPicker", self.wndMain, self)
		self.wndFloat = Apollo.LoadForm(self.xmlDoc, "SmartTelegraphsFloat", nil, self)
		self.wndFloatList = Apollo.LoadForm(self.xmlDoc, "SmartTelegraphsFloatList", self.wndFloat, self)
		
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
		self.wndColorPicker:Show(false, true)
		self.wndFloat:Show(true, true)
		self.wndFloatList:Show(false, true)
		
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
		end


		--- Main window ---
		self.main = {}

		self.main.zoneConfigArea = self.wndMain:FindChild("ZoneConfigArea")
		self.main.zoneTab = self.wndMain:FindChild("btnZoneTab")
		self.main.colorConfigArea = self.wndMain:FindChild("ColorsConfigArea")
		self.main.colorTab = self.wndMain:FindChild("btnColorTab")
		self.main.settingsTab = self.wndMain:FindChild("btnSettingsTab")
		
		self.main.listArea = self.wndMain:FindChild("ListArea")
		self.main.settingsArea = self.wndMain:FindChild("SettingsArea")
		
		self.main.colorName = self.wndMain:FindChild("ColorNameEditBox")
		self.main.colorDisplay = self.wndMain:FindChild("ColorDisplay")
		
		self.main.zoneNameDisplay = self.wndMain:FindChild("ZoneNameDisplay")
		self.main.subZoneNameDisplay = self.wndMain:FindChild("SubzoneNameDisplay")
		self.main.zoneColorDisplay = self.wndMain:FindChild("zoneColorDisplay")

		self.main.btnMiniFloater = self.wndMain:FindChild("btnMiniFloaterCB")
		
		--- Color Picker ---
		self.colorPick = {}
		
		self.colorPick.REditBox = self.wndColorPicker:FindChild("REditBox")
		self.colorPick.GEditBox = self.wndColorPicker:FindChild("GEditBox")
		self.colorPick.BEditBox = self.wndColorPicker:FindChild("BEditBox")
		self.colorPick.IFEditBox = self.wndColorPicker:FindChild("IFEditBox")
		self.colorPick.IFSlider = self.wndColorPicker:FindChild("IFSliderBar")
		self.colorPick.OFEditBox = self.wndColorPicker:FindChild("OFEditBox")
		self.colorPick.OFSlider = self.wndColorPicker:FindChild("OFSliderBar")
		self.colorPick.ColorPicker = self.wndColorPicker:FindChild("ColorPicker")
		
		--- Floater ---
		self.float = {}

		self.float.textContainer = self.wndFloat:FindChild("wndPresetTextContainer")
		self.float.txtZone = self.wndFloat:FindChild("txtFloatZone")
		self.float.txtSubzone = self.wndFloat:FindChild("txtFloatSubzone")
		self.float.colorDisplay = self.wndFloat:FindChild("ColorDisplay")

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
	local zoneId = -1
	if tZone ~= nil then zoneId = tZone.id end

	local zone = self:GetZone(zoneId)

	-- Main Window
	if self.wndMain:IsShown() then
		if self.config.lastTab ~= nil and self.config.lastTab then
			self:ShowTab(self.config.lastTab)
		else
			self:ShowTab(1)
		end
	end
	-- Floater
	self:UpdateFloaterWindow()
	-- Telegraphs
	self:UpdateTelegraphs()
end

function SmartTelegraphs:UpdateTelegraphs()
	local tZone = GameLib.GetCurrentZoneMap()
	local zoneId = -1
	if tZone ~= nil then zoneId = tZone.id end
	local zone = self:GetZone(zoneId)

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
	local tZone = GameLib.GetCurrentZoneMap()
	local tSubzoneName = GetCurrentSubZoneName()
	local zoneId = -1
	if tZone ~= nil then zoneId = tZone.id end

	local zone = self:GetZone(zoneId)
	
	local color = self:GetColor(zone.colorId)

	-- Folder
	self.main.zoneNameDisplay:SetText(zone.zoneName)
	self.main.subZoneNameDisplay:SetText(tSubzoneName)
	self.main.zoneColorDisplay:SetBGColor(self:CreateCColor(color))
end

function SmartTelegraphs:UpdateColorConfigArea()
	local tZone = GameLib.GetCurrentZoneMap()
	local zoneId = -1
	if tZone ~= nil then zoneId = tZone.id end

	local zone = self:GetZone(zoneId)
	
	local color = self:GetColor(zone.colorId)

	self.main.colorName:SetText(color.colorName)
	
	self.colorPick.REditBox:SetText(color.r)
	self.colorPick.GEditBox:SetText(color.g)
	self.colorPick.BEditBox:SetText(color.b)
	self.colorPick.IFEditBox:SetText(color.fo)
	self.colorPick.IFSlider:SetValue(color.fo)
	self.colorPick.OFEditBox:SetText(color.oo)
	self.colorPick.OFSlider:SetValue(color.oo)
	
	self.main.colorDisplay:SetBGColor(self:CreateCColor(color))
	self.colorPick.ColorPicker:SetColor(ApolloColor.new(color.r / 255.0, color.g / 255.0, color.b / 255.0))
end

function SmartTelegraphs:UpdateFloaterWindow()
	local tZone = GameLib.GetCurrentZoneMap()
	local zoneId = -1
	if tZone ~= nil then zoneId = tZone.id end

	local zone = self:GetZone(zoneId)
	
	local color = self:GetColor(zone.colorId)
	
	self.float.textContainer:Show(not self.config.showSmallFloat,true)
	self.float.txtZone:SetText(zone.zoneName)
	self.float.txtSubzone:SetText("") -- zone.subzoneName
	self.float.colorDisplay:SetBGColor(self:CreateCColor(color))
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
	local newColorItem = Apollo.LoadForm(self.xmlDoc,"ColorFloatItemTemplateFrame", self.wndFloatList, self)	

	local color = self:GetColor(colorId)

	newColorItem:SetData(colorId)
	newColorItem:SetName("color_" .. colorId)
	
	local txtColorName = newColorItem:FindChild("txtColorName")
	txtColorName:SetText(color.colorName)
	
	local colorDisplay = newColorItem:FindChild("ColorDisplay")
	colorDisplay:SetBGColor(self:CreateCColor(color));
	
	self.wndFloatList:ArrangeChildrenVert()
end

function SmartTelegraphs:OnSaveColorButton( wndHandler, wndControl, eMouseButton )

	local r = self.colorPick.REditBox:GetText()
	local g = self.colorPick.GEditBox:GetText()
	local b = self.colorPick.BEditBox:GetText()
	local fo = self.colorPick.IFEditBox:GetText()
	local oo = self.colorPick.OFEditBox:GetText()
	
	local colorHash = r .. "|" .. g .. "|" .. b
		
	self.data.colors[colorHash] = {
		colorName = self.main.colorName:GetText(),
		r = r,
		g = g,
		b = b,
		fo = fo,
		oo = oo
	}

	self:UpdateColorList()
	self:UpdateColorConfigArea()
	self:UpdateFloaterWindow()
end

function SmartTelegraphs:OnCheckColorTab( wndHandler, wndControl, eMouseButton )
	self:ShowTab(1);
end

function SmartTelegraphs:OnCheckZoneTab( wndHandler, wndControl, eMouseButton )
	self:ShowTab(2);
end

function SmartTelegraphs:OnCheckSettingsTab( wndHandler, wndControl, eMouseButton )
	self:ShowTab(3);
end

function SmartTelegraphs:ShowTab(nTab)
	if nTab < 1 or nTab > 3 then return end
			
	self.main.listArea:Show(nTab == 1 or nTab == 2, true)
	self.main.colorConfigArea:Show(nTab == 1, true)
	self.wndColorPicker:Show(nTab == 1, true)
	self.main.colorTab:SetCheck(nTab == 1)
	self.main.zoneConfigArea:Show(nTab == 2, true)
	self.main.zoneTab:SetCheck(nTab == 2)
	
	self.main.settingsArea:Show(nTab == 3, true)
	self.main.settingsTab:SetCheck(nTab == 3)
	
	if nTab == 1 then
		self:UpdateColorConfigArea()
		self:UpdateColorList()
	elseif nTab == 2 then
		self:UpdateZoneConfigArea()
		self:UpdateZoneList()
	elseif nTab == 3 then
		self.main.btnMiniFloater:SetCheck(self.config.showSmallFloat)
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
	self.wndFloatList:DestroyChildren()

	for i, peCurrent in pairs(self.data.colors) do
		self:DrawFloatListItem(i)
	end
end

function SmartTelegraphs:OnMiniFloaterCBCheck( wndHandler, wndControl, eMouseButton )
	self.config.showSmallFloat = self.main.btnMiniFloater:IsChecked()
	self.float.textContainer:Show(not self.config.showSmallFloat)
end

function SmartTelegraphs:OnMainWindowClosed( wndHandler, wndControl )
	self.main.listArea:DestroyChildren()
end

function SmartTelegraphs:OnFloaterListClosed( wndHandler, wndControl )
	self.wndFloatList:DestroyChildren()
end

---------------------------------------------------------------------------------------------------
-- SmartTelegraphsColorPicker Functions
---------------------------------------------------------------------------------------------------

function SmartTelegraphs:OnColorChanged( wndHandler, wndControl, crNewColor )
	self.colorPick.REditBox:SetText(math.floor(crNewColor.r * 255.0))
	self.colorPick.GEditBox:SetText(math.floor(crNewColor.g * 255.0))
	self.colorPick.BEditBox:SetText(math.floor(crNewColor.b * 255.0))
	
	local fo = tonumber(self.colorPick.IFEditBox:GetText()) / 100.0
	
	self.main.colorDisplay:SetBGColor(ApolloColor.new(crNewColor.r, crNewColor.g, crNewColor.b, fo))
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
	
	local r = tonumber(self.colorPick.REditBox:GetText()) / 255.0
	local g = tonumber(self.colorPick.GEditBox:GetText()) / 255.0
	local b = tonumber(self.colorPick.BEditBox:GetText()) / 255.0
	local fo = tonumber(self.colorPick.IFEditBox:GetText()) / 100.0
	local of = tonumber(self.colorPick.OFEditBox:GetText()) / 100.0
	
	self.main.colorDisplay:SetBGColor(ApolloColor.new(r, g, b, fo))
	self.colorPick.ColorPicker:SetColor(ApolloColor.new(r, g, b))
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

	local r = tonumber(self.colorPick.REditBox:GetText()) / 255.0
	local g = tonumber(self.colorPick.GEditBox:GetText()) / 255.0
	local b = tonumber(self.colorPick.BEditBox:GetText()) / 255.0
	local fo = tonumber(self.colorPick.IFEditBox:GetText()) / 100.0
	local of = tonumber(self.colorPick.OFEditBox:GetText()) / 100.0
	
	self.main.colorDisplay:SetBGColor(ApolloColor.new(r, g, b, fo))
	self.colorPick.ColorPicker:SetColor(ApolloColor.new(r, g, b))
end


function SmartTelegraphs:OnIFOpacitySliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.colorPick.IFEditBox:SetText(math.floor(fNewValue))
end

function SmartTelegraphs:OnOFOpacitySliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.colorPick.OFEditBox:SetText(math.floor(fNewValue))
end

---------------------------------------------------
-- Floater Event Handling
---------------------------------------------------

function SmartTelegraphs:OnFloatClick( wndHandler, wndControl, eMouseButton )
	if wndControl == self.float.colorDisplay or wndControl == self.float.textContainer then else return end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		self:UpdateFloatList()
		self.wndFloatList:Show(true, true)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Right  then
		self:OnSmartTelegraphsOn()
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
		self:UpdateTelegraphs()
		self.wndFloatList:Show(false, true)
		self.wndFloatList:DestroyChildren()
		self:UpdateUI()
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
		local zoneName = "Loading..."
		if tZone ~= nil then zoneName = tZone.strName end
		zone = {
			zoneName = zoneName,
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
	local color = ApolloColor.new(
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