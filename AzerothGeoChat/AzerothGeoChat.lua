--[[--------------------------------------------------------------------
	AzerothGeoChat v1.2.0
	Georgian (Mkhedruli) chat transliteration & font support for WoW 3.3.5a
	Author: Azeroth Reborn

	Features:
	- Transliterates English QWERTY keys into Georgian Unicode on the fly.
	- Intercepts Windows Georgian layout '?' characters caused by DirectX 9
	  ANSI limitations and restores the intended Georgian letters.
	- Smart slash command and whisper protection (keeps player names in Latin).
	- Preserves WoW hyperlinks (|c...|H...|h...|h|r).
	- In-place text conversion (Latin <-> Georgian via right-click or /geo c).
	- Bundled Sylfaen/Segoe UI fonts for clean Georgian glyph rendering.
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

-- Physical key mappings for when Windows sends '?' under Georgian keyboard layout
local KEY_TO_GEO = {
	["A"] = "ა", ["B"] = "ბ", ["G"] = "გ", ["D"] = "დ", ["E"] = "ე",
	["V"] = "ვ", ["Z"] = "ზ", ["T"] = "ტ", ["I"] = "ი", ["K"] = "კ",
	["L"] = "ლ", ["M"] = "მ", ["N"] = "ნ", ["O"] = "ო", ["P"] = "პ",
	["J"] = "ჯ", ["R"] = "რ", ["S"] = "ს", ["U"] = "უ", ["F"] = "ფ",
	["Q"] = "ქ", ["Y"] = "ყ", ["C"] = "ც", ["W"] = "წ", ["X"] = "ხ",
	["H"] = "ჰ",
}

local SHIFT_KEY_TO_GEO = {
	["T"] = "თ",
	["J"] = "ჟ",
	["R"] = "ღ",
	["S"] = "შ",
	["C"] = "ჩ",
	["Z"] = "ძ",
	["W"] = "ჭ",
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
-- Database & Helpers
----------------------------------------------------------------------
AzerothGeoChatDB = AzerothGeoChatDB or { enabled = true }

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
-- In-Place Text Transliteration (Latin <-> Georgian)
----------------------------------------------------------------------
local function TransliterateString(text)
	if not text or text == "" then return text end

	-- Check if text already contains Georgian characters (UTF-8 sequence \225\131)
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
-- Core Character Replacement (EditBox Hook)
----------------------------------------------------------------------
local function Geo_OnChar(self, char)
	if not AzerothGeoChatDB.enabled then return end

	local mapped = GEO_MAP[char]

	-- If Windows Georgian layout sent '?' for an alphabetical keystroke:
	if not mapped and char == "?" and self.lastKeyDown then
		local key = self.lastKeyDown:upper()
		local now = GetTime()
		if (not self.lastKeyTime or (now - self.lastKeyTime) < 0.25) and key:match("^[A-Z]$") then
			if self.lastKeyShift and SHIFT_KEY_TO_GEO[key] then
				mapped = SHIFT_KEY_TO_GEO[key]
			elseif KEY_TO_GEO[key] then
				mapped = KEY_TO_GEO[key]
			end
		end
	end

	if not mapped then return end

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

	-- Safe in-place replacement
	self:HighlightText(pos - 1, pos)
	self:Insert(mapped)
end

----------------------------------------------------------------------
-- EditBox Hooking
----------------------------------------------------------------------
local function HookEditBox(box)
	if not box or box.AzerothGeoChatHooked then return end
	box.AzerothGeoChatHooked = true

	ApplyGeorgianFont(box)

	local origKeyDown = box:GetScript("OnKeyDown")
	box:SetScript("OnKeyDown", function(self, key)
		self.lastKeyDown = key
		self.lastKeyShift = IsShiftKeyDown()
		self.lastKeyTime = GetTime()
		if origKeyDown then origKeyDown(self, key) end
	end)

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
-- Positioned cleanly at the BOTTOM part of the chat box
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
		btn:SetText(color .. "[" .. label .. "]|r")
	end
end

local function CreateToggleButton(editBox)
	if not editBox or editBox.AzerothGeoChatBtn then return end

	local btn = CreateFrame("Button", nil, editBox)
	editBox.AzerothGeoChatBtn = btn

	btn:SetWidth(44)
	btn:SetHeight(16)

	-- Placed neatly at the BOTTOM part of the edit box (underneath the input box)
	btn:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 6, -2)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	btn:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	btn:SetBackdropColor(0, 0, 0, 0.8)
	btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)

	local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	fs:SetPoint("CENTER", 0, 0)
	btn:SetFontString(fs)

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
		GameTooltip:AddLine("AzerothGeoChat", 0.2, 1.0, 0.6)
		GameTooltip:AddLine("|cffffffffLeft-Click:|r Toggle Georgian / English input", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("|cffffffffRight-Click:|r Convert typed text (Latin <-> Geo)", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("|cff888888Slash commands: /geo, /geo c|r", 0.6, 0.6, 0.6)
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
-- Toggle & Slash Command Handlers
----------------------------------------------------------------------
function AzerothGeoChat_Toggle(force)
	if force ~= nil then
		AzerothGeoChatDB.enabled = not not force
	else
		AzerothGeoChatDB.enabled = not AzerothGeoChatDB.enabled
	end
	RefreshButtons()
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
		if AzerothGeoChatDB.enabled == nil then
			AzerothGeoChatDB.enabled = true
		end
		HookAllEditBoxes()
		CreateAllToggleButtons()
		SetupChatFont()

		if ChatEdit_ActivateChat then
			hooksecurefunc("ChatEdit_ActivateChat", function(editBox)
				if editBox then
					HookEditBox(editBox)
					CreateToggleButton(editBox)
					RefreshButtons()
				end
			end)
		end

		Print("v1.2.0 loaded. |cff00ff00/geo|r to toggle, |cff00ff00/geo c|r to convert text, |cff00ff00Right-Click [GEO]|r.")
	elseif event == "ADDON_LOADED" and arg1 == "Blizzard_MacroUI" then
		if MacroFrameText then
			HookEditBox(MacroFrameText)
		end
	elseif event == "MAIL_SHOW" then
		HookAllEditBoxes()
	end
end)
