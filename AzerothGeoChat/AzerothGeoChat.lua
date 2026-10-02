--[[--------------------------------------------------------------------
	AzerothGeoChat v1.3.0
	Georgian (Mkhedruli) chat transliteration & font support for WoW 3.3.5a
	Author: Azeroth Reborn

	Features:
	- Real-time QWERTY to Mkhedruli transliteration.
	- Phonetic Digraphs: type sh->შ, ch->ჩ, gh->ღ, zh->ჟ, th->თ, dz->ძ, ts->ც
	  without needing to press Shift!
	- Incoming chat translator: auto-converts Latin translit messages from
	  other Georgian players into readable Georgian.
	- In-game Blizzard Interface Options Panel (Options -> AddOns -> AzerothGeoChat).
	- Native sound effects on toggle.
	- Smart slash command and whisper protection (keeps player names in Latin).
	- Preserves WoW hyperlinks (|c...|H...|h...|h|r).
	- In-place text conversion (Latin <-> Georgian via right-click or /geo c).
	- WIM (WoW Instant Messenger) support.
	- Bundled Sylfaen/Segoe UI fonts for clean Georgian glyph rendering.
	- Draggable [GEO] toggle button with Shift+Drag.
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- Georgian QWERTY (Mkhedruli) Mapping
----------------------------------------------------------------------
local GEO_MAP = {
	-- Standard lowercase Mkhedruli (33 letters)
	["a"] = "ა", ["b"] = "ბ", ["g"] = "გ", ["d"] = "დ", ["e"] = "ე",
	["v"] = "ვ", ["z"] = "ზ", ["t"] = "ტ", ["i"] = "ი", ["k"] = "კ",
	["l"] = "ლ", ["m"] = "მ", ["n"] = "ნ", ["o"] = "ო", ["p"] = "პ",
	["r"] = "რ", ["s"] = "ს", ["u"] = "უ", ["f"] = "ფ", ["q"] = "ქ",
	["y"] = "ყ", ["c"] = "ც", ["w"] = "წ", ["x"] = "ხ", ["j"] = "ჯ",
	["h"] = "ჰ",

	-- Shifted keys in standard Georgian (QWERTY) layout
	["T"] = "თ",
	["J"] = "ჟ",
	["R"] = "ღ",
	["S"] = "შ",
	["C"] = "ჩ",
	["Z"] = "ძ",
	["W"] = "ჭ",

	-- Smart CapsLock & Shift fallbacks
	["A"] = "ა", ["B"] = "ბ", ["G"] = "გ", ["D"] = "დ", ["E"] = "ე",
	["V"] = "ვ", ["I"] = "ი", ["K"] = "კ", ["L"] = "ლ", ["M"] = "მ",
	["N"] = "ნ", ["O"] = "ო", ["P"] = "პ", ["U"] = "უ", ["F"] = "ფ",
	["Q"] = "ქ", ["Y"] = "ყ", ["X"] = "ხ", ["H"] = "ჰ",
}

-- Phonetic Digraphs: allows typing combined letters without Shift
local DIGRAPHS = {
	["h"] = {
		["ს"] = "შ", -- sh -> შ
		["ც"] = "ჩ", -- ch -> ჩ
		["ზ"] = "ჟ", -- zh -> ჟ
		["გ"] = "ღ", -- gh -> ღ
		["ტ"] = "თ", -- th -> თ
	},
	["z"] = {
		["დ"] = "ძ", -- dz -> ძ
	},
	["s"] = {
		["ტ"] = "ც", -- ts -> ც
	},
}

-- Reverse mapping for Georgian -> Latin conversion
local REV_MAP = {
	["ა"] = "a", ["ბ"] = "b", ["გ"] = "g", ["დ"] = "d", ["ე"] = "e",
	["ვ"] = "v", ["ზ"] = "z", ["თ"] = "T", ["ტ"] = "t", ["ი"] = "i",
	["კ"] = "k", ["ლ"] = "l", ["მ"] = "m", ["ნ"] = "n", ["ო"] = "o",
	["პ"] = "p", ["ჟ"] = "J", ["რ"] = "r", ["ს"] = "s", ["უ"] = "u",
	["ფ"] = "f", ["ქ"] = "q", ["ღ"] = "R", ["ყ"] = "y", ["შ"] = "S",
	["ჩ"] = "C", ["ც"] = "c", ["ძ"] = "Z", ["წ"] = "w", ["ჭ"] = "W",
	["ხ"] = "x", ["ჯ"] = "j", ["ჰ"] = "h",
}

----------------------------------------------------------------------
-- Slash Command Rules
----------------------------------------------------------------------
local CHAT_COMMANDS = {
	["/s"] = true, ["/say"] = true,
	["/y"] = true, ["/yell"] = true,
	["/p"] = true, ["/party"] = true,
	["/g"] = true, ["/guild"] = true, ["/gc"] = true,
	["/ra"] = true, ["/raid"] = true,
	["/rw"] = true, ["/raidwarning"] = true,
	["/bg"] = true, ["/battleground"] = true,
	["/o"] = true, ["/officer"] = true,
	["/e"] = true, ["/me"] = true, ["/emote"] = true,
}
for i = 1, 10 do
	CHAT_COMMANDS["/" .. i] = true
end

local WHISPER_COMMANDS = {
	["/w"] = true, ["/whisper"] = true,
	["/t"] = true, ["/tell"] = true,
}

----------------------------------------------------------------------
-- Keybindings Strings (Options -> Key Bindings -> AzerothGeoChat)
----------------------------------------------------------------------
BINDING_HEADER_AZEROTHGEOCHAT         = "AzerothGeoChat"
BINDING_NAME_AZEROTHGEOCHAT_TOGGLE    = "Toggle Georgian / English input"
BINDING_NAME_AZEROTHGEOCHAT_CONVERT   = "Convert typed text (Latin <-> Geo)"

----------------------------------------------------------------------
-- Database & Default Preferences
----------------------------------------------------------------------
local DB_DEFAULTS = {
	enabled = true,
	digraphs = true,          -- sh->შ, ch->ჩ, gh->ღ, etc.
	translateIncoming = false,-- Auto-translate incoming translit
	sound = true,             -- Sound on toggle
	showButton = true,        -- Show [GEO] button
}

AzerothGeoChatDB = AzerothGeoChatDB or {}

local function InitDB()
	for k, v in pairs(DB_DEFAULTS) do
		if AzerothGeoChatDB[k] == nil then
			AzerothGeoChatDB[k] = v
		end
	end
end

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AzerothGeoChat|r: " .. msg)
end

-- Check if cursor position is inside a WoW hyperlink |c...|H...|h[...]...|h|r
local function IsInsideHyperlink(text, pos)
	if not text or pos <= 0 then return false end
	local sub = text:sub(1, pos)
	local linkStart = sub:match("^.*()|H")
	if linkStart then
		local linkEnd = text:find("|h", linkStart, true)
		if linkEnd then
			local secondH = text:find("|h", linkEnd + 2, true)
			if secondH and pos <= secondH + 4 then
				return true
			elseif pos <= linkEnd + 2 then
				return true
			end
		end
	end
	return false
end

----------------------------------------------------------------------
-- Font Configuration
----------------------------------------------------------------------
local FONT_PATHS = {
	"Interface\\AddOns\\AzerothGeoChat\\Fonts\\ARIALN.ttf",
	"Fonts\\ARIALN.ttf",
}

local function ApplyGeorgianFont(obj)
	if not obj then return end
	for _, f in ipairs(FONT_PATHS) do
		local ok = pcall(function()
			local _, size, flags = obj:GetFont()
			obj:SetFont(f, size or 14, flags)
		end)
		if ok then break end
	end
end

local function SetupChatFont()
	ApplyGeorgianFont(ChatFontNormal)
	ApplyGeorgianFont(ChatFontSmall)

	for i = 1, NUM_CHAT_WINDOWS do
		local cf = _G["ChatFrame" .. i]
		if cf then ApplyGeorgianFont(cf) end
		local eb = _G["ChatFrame" .. i .. "EditBox"]
		if eb then ApplyGeorgianFont(eb) end
	end

	if SendMailSubjectEditBox then ApplyGeorgianFont(SendMailSubjectEditBox) end
	if SendMailBodyEditBox then ApplyGeorgianFont(SendMailBodyEditBox) end
	if OpenMailReplySubjectEditBox then ApplyGeorgianFont(OpenMailReplySubjectEditBox) end
	if OpenMailReplyBodyEditBox then ApplyGeorgianFont(OpenMailReplyBodyEditBox) end
end

----------------------------------------------------------------------
-- Text Transliteration (Latin <-> Georgian)
----------------------------------------------------------------------
local function TransliterateString(text)
	if not text or text == "" then return text end

	local hasGeorgian = text:find("\225\131")

	local prefix = ""
	local body = text
	if text:sub(1, 1) == "/" then
		local firstSpace = text:find(" ", 1, true)
		if firstSpace then
			local cmd = text:sub(1, firstSpace - 1):lower()
			if CHAT_COMMANDS[cmd] then
				prefix = text:sub(1, firstSpace)
				body = text:sub(firstSpace + 1)
			elseif WHISPER_COMMANDS[cmd] then
				local secondSpace = text:find(" ", firstSpace + 1, true)
				if secondSpace then
					prefix = text:sub(1, secondSpace)
					body = text:sub(secondSpace + 1)
				else
					return text
				end
			else
				return text
			end
		else
			return text
		end
	end

	-- Protect hyperlinks
	local links = {}
	local linkCount = 0
	body = body:gsub("(|c%x+|H.-|h.-|h|r)", function(link)
		linkCount = linkCount + 1
		links[linkCount] = link
		return string.format("\001LNK%d\002", linkCount)
	end)

	if hasGeorgian then
		-- Convert Georgian -> Latin
		for geoChar, latChar in pairs(REV_MAP) do
			body = body:gsub(geoChar, latChar)
		end
	else
		-- Convert Latin -> Georgian
		-- Check digraphs first if enabled
		if AzerothGeoChatDB.digraphs then
			body = body:gsub("sh", "შ"):gsub("Sh", "შ"):gsub("SH", "შ")
			body = body:gsub("ch", "ჩ"):gsub("Ch", "ჩ"):gsub("CH", "ჩ")
			body = body:gsub("gh", "ღ"):gsub("Gh", "ღ"):gsub("GH", "ღ")
			body = body:gsub("zh", "ჟ"):gsub("Zh", "ჟ"):gsub("ZH", "ჟ")
			body = body:gsub("th", "თ"):gsub("Th", "თ"):gsub("TH", "თ")
			body = body:gsub("dz", "ძ"):gsub("Dz", "ძ"):gsub("DZ", "ძ")
			body = body:gsub("ts", "ც"):gsub("Ts", "ც"):gsub("TS", "ც")
		end

		body = body:gsub("[a-zA-Z]", function(c)
			return GEO_MAP[c] or c
		end)
	end

	-- Restore hyperlinks
	body = body:gsub("\001LNK(%d+)\002", function(id)
		return links[tonumber(id)] or ""
	end)

	return prefix .. body
end

function AzerothGeoChat_ConvertCurrentEditBox()
	local editBox = GetFocus()
	if not editBox or not editBox.IsObjectType or not editBox:IsObjectType("EditBox") then
		if ChatEdit_GetActiveWindow then
			editBox = ChatEdit_GetActiveWindow()
		end
	end

	if editBox and editBox:IsShown() then
		local currentText = editBox:GetText() or ""
		if currentText ~= "" then
			local converted = TransliterateString(currentText)
			editBox:SetText(converted)
			editBox:SetCursorPosition(string.len(converted))
		end
	else
		Print("No active chat box found to convert. Open chat first.")
	end
end

----------------------------------------------------------------------
-- Incoming Chat Event Filter
----------------------------------------------------------------------
local function IncomingChatFilter(self, event, msg, author, ...)
	if not AzerothGeoChatDB.translateIncoming or not msg or msg == "" then
		return false, msg, author, ...
	end

	-- Only translate if the message has Latin letters and no Georgian letters
	if not msg:find("\225\131") and msg:find("%a") then
		local converted = TransliterateString(msg)
		return false, converted, author, ...
	end

	return false, msg, author, ...
end

local CHAT_FILTER_EVENTS = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_CHANNEL",
}

for _, ev in ipairs(CHAT_FILTER_EVENTS) do
	ChatFrame_AddMessageEventFilter(ev, IncomingChatFilter)
end

----------------------------------------------------------------------
-- Core Character Replacement (EditBox OnChar Hook)
----------------------------------------------------------------------
local warnedAboutLayout = false

local function Geo_OnChar(self, char)
	if not AzerothGeoChatDB.enabled then return end

	-- Warn if Windows layout is set to Georgian sending raw '?'
	if char == "?" and not warnedAboutLayout then
		warnedAboutLayout = true
		Print("|cffffcc00შენიშვნა:|r Windows-ში დატოვეთ ინგლისური |cff00ff00[EN]|r კლავიატურა! აკრიფეთ ინგლისურად (QWERTY) და ადონი თვითონ გადაიყვანს ქართულად.")
	end

	local text = self:GetText() or ""
	local pos  = self:GetCursorPosition()
	if not pos or pos <= 0 then return end

	-- Slash command protection
	if text:sub(1, 1) == "/" then
		local firstSpace = text:find(" ", 1, true)
		if not firstSpace then
			return
		end

		local cmd = text:sub(1, firstSpace - 1):lower()
		if CHAT_COMMANDS[cmd] then
			if pos <= firstSpace then return end
		elseif WHISPER_COMMANDS[cmd] then
			local secondSpace = text:find(" ", firstSpace + 1, true)
			if not secondSpace or pos <= secondSpace then
				return
			end
		else
			return
		end
	end

	-- Hyperlink protection
	if IsInsideHyperlink(text, pos) then
		return
	end

	-- Phonetic Digraph check (sh->შ, ch->ჩ, gh->ღ, zh->ჟ, th->თ, dz->ძ, ts->ც)
	if AzerothGeoChatDB.digraphs and pos >= 2 and self.lastInsertedChar and self.lastInsertedPos == (pos - 1) then
		local digGroup = DIGRAPHS[char:lower()]
		if digGroup and digGroup[self.lastInsertedChar] then
			local combined = digGroup[self.lastInsertedChar]
			self:HighlightText(pos - 2, pos)
			self:Insert(combined)
			self.lastInsertedChar = combined
			self.lastInsertedPos  = pos - 1
			return
		end
	end

	local mapped = GEO_MAP[char]
	if not mapped then
		self.lastInsertedChar = nil
		self.lastInsertedPos = nil
		return
	end

	-- Safe in-place replacement
	self:HighlightText(pos - 1, pos)
	self:Insert(mapped)

	self.lastInsertedChar = mapped
	self.lastInsertedPos  = pos
end

----------------------------------------------------------------------
-- EditBox Hooking
----------------------------------------------------------------------
local function HookEditBox(box)
	if not box or box.AzerothGeoChatHooked then return end
	box.AzerothGeoChatHooked = true

	ApplyGeorgianFont(box)

	local origChar = box:GetScript("OnChar")
	box:SetScript("OnChar", function(self, char)
		if origChar then origChar(self, char) end
		Geo_OnChar(self, char)
	end)
end

local function HookAllEditBoxes()
	for i = 1, NUM_CHAT_WINDOWS do
		local box = _G["ChatFrame" .. i .. "EditBox"]
		if box then HookEditBox(box) end
	end

	if SendMailSubjectEditBox then HookEditBox(SendMailSubjectEditBox) end
	if SendMailBodyEditBox then HookEditBox(SendMailBodyEditBox) end
	if OpenMailReplySubjectEditBox then HookEditBox(OpenMailReplySubjectEditBox) end
	if OpenMailReplyBodyEditBox then HookEditBox(OpenMailReplyBodyEditBox) end
	if MacroFrameText then HookEditBox(MacroFrameText) end
	if GuildMemberDetailFrameNoteEditBox then HookEditBox(GuildMemberDetailFrameNoteEditBox) end
	if GuildMemberDetailFrameOfficerNoteEditBox then HookEditBox(GuildMemberDetailFrameOfficerNoteEditBox) end
end

----------------------------------------------------------------------
-- UI Toggle Button ([GEO] / [ENG])
----------------------------------------------------------------------
local buttons = {}

local function RefreshButtons()
	local label, color
	if AzerothGeoChatDB.enabled then
		label, color = "GEO", "|cff00ff00"
	else
		label, color = "ENG", "|cff888888"
	end
	for _, btn in ipairs(buttons) do
		if AzerothGeoChatDB.showButton then
			btn:Show()
			btn:SetText(color .. "[" .. label .. "]|r")
		else
			btn:Hide()
		end
	end
end

function AzerothGeoChat_ResetButtonPosition()
	for _, btn in ipairs(buttons) do
		if btn.parentBox then
			btn:ClearAllPoints()
			btn:SetPoint("RIGHT", btn.parentBox, "RIGHT", -6, 0)
		end
	end
end

local function CreateToggleButton(editBox)
	if not editBox or editBox.AzerothGeoChatBtn then return end

	local btn = CreateFrame("Button", nil, editBox)
	editBox.AzerothGeoChatBtn = btn
	btn.parentBox = editBox

	btn:SetWidth(44)
	btn:SetHeight(18)
	btn:SetPoint("RIGHT", editBox, "RIGHT", -6, 0)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	btn:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	btn:SetBackdropColor(0, 0, 0, 0.85)
	btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)

	local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	fs:SetPoint("CENTER", 0, 0)
	btn:SetFontString(fs)

	-- Allow moving with Shift + Drag
	btn:SetMovable(true)
	btn:EnableMouse(true)
	btn:RegisterForDrag("LeftButton")
	btn:SetScript("OnDragStart", function(self)
		if IsShiftKeyDown() then
			self:StartMoving()
		end
	end)
	btn:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	btn:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			AzerothGeoChat_ConvertCurrentEditBox()
		else
			AzerothGeoChat_Toggle()
		end
		if editBox:IsShown() then
			editBox:SetFocus()
		end
	end)

	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("AzerothGeoChat v1.3.0", 0.2, 1.0, 0.6)
		GameTooltip:AddLine("|cffffffffLeft-Click:|r ჩართვა / გამორთვა (GEO / ENG)", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("|cffffffffRight-Click:|r აკრეფილი ტექსტის გადაყვანა (Latin <-> Geo)", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("|cffffffffShift + Drag:|r ღილაკის გადაადგილება", 0.7, 0.7, 0.7)
		GameTooltip:AddLine("|cff888888ბრძანებები: /geo, /geo c, /geo opt|r", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	tinsert(buttons, btn)
end

local function CreateAllToggleButtons()
	for i = 1, NUM_CHAT_WINDOWS do
		local box = _G["ChatFrame" .. i .. "EditBox"]
		if box then CreateToggleButton(box) end
	end
	RefreshButtons()
end

----------------------------------------------------------------------
-- Blizzard Interface Options Panel
----------------------------------------------------------------------
local function CreateOptionsPanel()
	local panel = CreateFrame("Frame", "AzerothGeoChatOptionsPanel", UIParent)
	panel.name = "AzerothGeoChat"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("AzerothGeoChat |cff00ff00v1.3.0|r")

	local subtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtext:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtext:SetText("Georgian (ქართული) chat transliteration & font support for WoW 3.3.5a")

	local function CreateCheck(name, label, tooltip, dbKey, yOffset)
		local cb = CreateFrame("CheckButton", "AzerothGeoChat_CB_" .. name, panel, "InterfaceOptionsCheckButtonTemplate")
		cb:SetPoint("TOPLEFT", 16, yOffset)
		_G[cb:GetName() .. "Text"]:SetText(label)
		cb.tooltipText = label
		cb.tooltipRequirement = tooltip

		cb:SetScript("OnClick", function(self)
			AzerothGeoChatDB[dbKey] = self:GetChecked() and true or false
			if dbKey == "showButton" then
				RefreshButtons()
			end
		end)
		cb:SetScript("OnShow", function(self)
			self:SetChecked(AzerothGeoChatDB[dbKey])
		end)
		return cb
	end

	CreateCheck("Enabled", "ქართული რეჟიმის ჩართვა (Enable Addon)", "ჩართავს ან გამორთავს ქართულ შეყვანას", "enabled", -60)
	CreateCheck("Digraphs", "ორმაგი ასოები Shift-ის გარეშე (Phonetic Digraphs: sh=შ, ch=ჩ, gh=ღ, zh=ჟ, th=თ, dz=ძ, ts=ც)", "საშუალებას გაძლევთ დაწეროთ შ, ჩ, ღ და ა.შ. Shift-ის დაჭერის გარეშე", "digraphs", -95)
	CreateCheck("Sound", "ხმოვანი ეფექტი (Sound on Toggle)", "გადართვისას უკრავს სასიამოვნო WoW-ის ხმას", "sound", -130)
	CreateCheck("ShowBtn", "[GEO] ღილაკის ჩვენება ჩატის ველში (Show Toggle Button)", "ჩატის ველში [GEO]/[ENG] ღილაკის გამოჩენა", "showButton", -165)
	CreateCheck("Incoming", "შემომავალი ჩატის გადათარგმნა (Translate Incoming Translit)", "სხვა მოთამაშეების მიერ ინგლისური ასოებით გამოგზავნილ ქართულ ტრანსლიტს გადაიყვანს ქართულად", "translateIncoming", -200)

	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetWidth(220)
	resetBtn:SetHeight(26)
	resetBtn:SetPoint("TOPLEFT", 16, -245)
	resetBtn:SetText("ღილაკის პოზიციის გადატვირთვა")
	resetBtn:SetScript("OnClick", function()
		AzerothGeoChat_ResetButtonPosition()
		Print("ღილაკის პოზიცია გადატვირთულია საწყის მდგომარეობაზე.")
	end)

	InterfaceOptions_AddCategory(panel)
end

----------------------------------------------------------------------
-- Toggle & Slash Command Handlers
----------------------------------------------------------------------
function AzerothGeoChat_Toggle(force)
	if force ~= nil then
		AzerothGeoChatDB.enabled = not not force
	else
		AzerothGeoChatDB.enabled = not AzerothGeoChatDB.enabled
	end
	RefreshButtons()

	if AzerothGeoChatDB.sound then
		if AzerothGeoChatDB.enabled then
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end

	if AzerothGeoChatDB.enabled then
		Print("Georgian input |cff00ff00[ON]|r (QWERTY -> მხედრული)")
	else
		Print("Georgian input |cff888888[OFF]|r (English input)")
	end
end

SLASH_AZEROTHGEOCHAT1 = "/geo"
SLASH_AZEROTHGEOCHAT2 = "/geochat"
SlashCmdList.AZEROTHGEOCHAT = function(msg)
	msg = strtrim(strlower(msg or ""))
	if msg == "on" then
		AzerothGeoChat_Toggle(true)
	elseif msg == "off" then
		AzerothGeoChat_Toggle(false)
	elseif msg == "c" or msg == "convert" then
		AzerothGeoChat_ConvertCurrentEditBox()
	elseif msg == "dg" or msg == "digraphs" then
		AzerothGeoChatDB.digraphs = not AzerothGeoChatDB.digraphs
		Print("Phonetic digraphs: " .. (AzerothGeoChatDB.digraphs and "|cff00ff00ON|r" or "|cff888888OFF|r"))
	elseif msg == "inc" or msg == "incoming" then
		AzerothGeoChatDB.translateIncoming = not AzerothGeoChatDB.translateIncoming
		Print("Incoming translit translation: " .. (AzerothGeoChatDB.translateIncoming and "|cff00ff00ON|r" or "|cff888888OFF|r"))
	elseif msg == "opt" or msg == "options" or msg == "config" then
		InterfaceOptionsFrame_OpenToCategory("AzerothGeoChat")
	else
		AzerothGeoChat_Toggle()
	end
end

----------------------------------------------------------------------
-- Event Initialization
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MAIL_SHOW")

frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "PLAYER_LOGIN" then
		InitDB()
		HookAllEditBoxes()
		CreateAllToggleButtons()
		SetupChatFont()
		CreateOptionsPanel()

		-- Hook third-party or dynamic chat activations (e.g. WIM, Chatter, Prat)
		if ChatEdit_ActivateChat then
			hooksecurefunc("ChatEdit_ActivateChat", function(editBox)
				if editBox then
					HookEditBox(editBox)
					CreateToggleButton(editBox)
					RefreshButtons()
				end
			end)
		end

		-- WIM (WoW Instant Messenger) integration
		if WIM and WIM.CreateMessageWindow then
			hooksecurefunc(WIM, "CreateMessageWindow", function(self, win)
				if win and win.widgets and win.widgets.msg_box then
					HookEditBox(win.widgets.msg_box)
				end
			end)
		end

		Print("v1.3.0 loaded. |cff00ff00/geo|r to toggle, |cff00ff00/geo opt|r for settings panel.")
	elseif event == "ADDON_LOADED" and arg1 == "Blizzard_MacroUI" then
		if MacroFrameText then
			HookEditBox(MacroFrameText)
		end
	elseif event == "MAIL_SHOW" then
		HookAllEditBoxes()
	end
end)
