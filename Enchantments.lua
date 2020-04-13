Enchantments = LibStub("AceAddon-3.0"):NewAddon("Enchantments", "AceConsole-3.0", "AceEvent-3.0")
local EnchantmentsLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Enchantments", {
  type = "data source",
  text = "Enchantments",
  icon = "Interface\\Icons\\Spell_ChargeNegative",
  OnClick = function(_, button) Enchantments:OnButtonClick(button) end,
  OnTooltipShow = function(tooltip) Enchantments:Tooltip(tooltip) end,
})
local icon = LibStub("LibDBIcon-1.0")
local AceGUI = LibStub("AceGUI-3.0")

local defaults = {
  profile = {
    minimap = { hide = false },
    debug = true,
    whitelist = {
      'enchanter', 'enchanter', '.* lf .* enchanter',
      'crusader', 'fiery', 'agility', '3 stats', 'riding skill',
      '55 healing', '30 spell', 'who can .* enchant', 'healing power',
      'enchant', 'can .* enchant'
    },
    blacklist = {
      '300', 'lfw', 'phase', 'looking for work', 'best enchants',
      'and .* other .*', 'your mats', 'fiery core', 'wts', '+ more', '4 stats', '30 spell', '30 spd', 'riding',
      'guild', 'hosted', 'pug', 'mallet', 'invite', 'reserved', '4stats', '+4', 'helm', 'legs', 'speed .* gloves'
    },
    announcement = {
      autoreply = "Hi! I'm 300 enchanter on IF bridge, what enchant do you need?",
      trade = "{star} Enchanting {star} Weap - +55 heal/Crusader/Fiery Weapon/9spirit/9int/15agi, Boots - Speed/7agi/7stam, Bracer - 7int/9stam/9str/24heal, Gloves - 7str/7agi/5skining, Shield - 7stam, Chest - 100mana/100hp/3stats, Cloak - 5res/3agi/70arm + more"
    }
  }
}

function Enchantments:OnInitialize()
  self:Print("Available commands: /ench on | /ench off")
  self.db = LibStub("AceDB-3.0"):New("EnchantmentsDB", defaults)

  self.enabled = false
  self.repliesCache = {}
  -- Register Minimap Icon
  icon:Register("EnchantmentsLDB", EnchantmentsLDB, self.db.profile.minimap)
end

function Enchantments:HandleSlashInput(input)
  if input == 'on' then
    Enchantments:Enable()
  elseif input == 'off' then
    Enchantments:Disable()
  else
    self:Print("Unknown command. Available options: on, off")
  end
end

function Enchantments:OnButtonClick(button)
  if button == 'LeftButton' then
    return self:Trigger()
  elseif button == 'RightButton' then
    self:ChatAnnouncements()
  elseif button == 'MiddleButton' then
    self:ShowSettingsFrame()
  end
end

-- Addon on/off state handling
function Enchantments:Enable()
  self:Print("enabled")
  self.enabled = true
  EnchantmentsLDB.icon = "Interface\\Icons\\Spell_ChargePositive"

  self:RegisterEvent("CHAT_MSG_CHANNEL")
  self:RegisterEvent("CHAT_MSG_SAY")
  self:RegisterEvent("CHAT_MSG_YELL")
end

function Enchantments:Disable()
  self:Print("disabled")
  self.enabled = false
  EnchantmentsLDB.icon = "Interface\\Icons\\Spell_ChargeNegative"

  self:UnregisterEvent("CHAT_MSG_CHANNEL")
  self:UnregisterEvent("CHAT_MSG_SAY")
  self:UnregisterEvent("CHAT_MSG_YELL")
end

function Enchantments:Trigger()
  if not self.enabled then
    self:Enable()
  else
    self:Disable()
  end
end

function Enchantments:Tooltip(tooltip)
  tooltip:SetText("Enchantments " .. (self.enabled and "Enabled" or "Disabled"))
  tooltip:AddLine("Left Click - enable/disable")
  tooltip:AddLine("Right Click - announce in chat")
  tooltip:AddLine("Middle Click - show settings")
end

-- Chat parser
function Enchantments:CHAT_MSG_CHANNEL(_, text, playerName, _, _, _, _, zoneChannelID, _, _, _, lineID, _, bnSenderID, ...)
  self:HandleMessage(text, playerName, zoneChannelID)
end

function Enchantments:CHAT_MSG_SAY(_, text, playerName, _, _, _, _, zoneChannelID, _, _, _, lineID, _, bnSenderID, ...)
  self:HandleMessage(text, playerName, zoneChannelID)
end

function Enchantments:CHAT_MSG_YELL(_, text, playerName, _, _, _, _, zoneChannelID, _, _, _, lineID, _, bnSenderID, ...)
  self:HandleMessage(text, playerName, zoneChannelID)
end

function Enchantments:HandleMessage(text, playerName, zoneChannelID)
  local lcText = text:lower()
  -- check that text doesn't contain words that we are not interested in
  if self:HasBannedWord(lcText) then return end

  if not self:HasSearchWord(lcText) then return end

  if self.repliesCache[playerName] then
    return
  end

  self.repliesCache[playerName] = true

  -- print message to chat
  self:Printf("|cff1E90FF|Hplayer:%s:%s|h[%s]|h|r: |cffFFFF66 %s|r", playerName, zoneChannelID, playerName, text)
  -- sound action window close. For open: 5274
  PlaySound(5275)
  -- Send Message
  self:ChatReply(playerName)
  -- Invite to party
  InviteUnit(playerName)
end

function Enchantments:HasBannedWord(text)
  local bannedWords = self.db.profile.blacklist

  for i = 1, #bannedWords do
    if text:find(bannedWords[i]) then
      return true
    end
  end

  return false
end

function Enchantments:HasSearchWord(text)
  local wordsToSearch = self.db.profile.whitelist

  for i = 1, #wordsToSearch do
    if text:match(wordsToSearch[i]) then
      self:Print(text:match(wordsToSearch[i]))
      return true
    end
  end

  return false
end

function Enchantments:ChatReply(player)
  SendChatMessage(self.db.profile.announcement.autoreply, "WHISPER", "Common", player);
end

function Enchantments:ChatAnnouncements()
  local id, name = GetChannelName("Trade");
  local phrase = self.db.profile.announcement.trade
  SendChatMessage(phrase, "CHANNEL", "Common", id)
  SendChatMessage(phrase, "YELL")
end

-- Register Commands and Events
Enchantments:RegisterChatCommand("ench", "HandleSlashInput")

-- #####################################################################
-- ######################## WIDGETS AND UI #############################
-- #####################################################################

function Enchantments:ShowSettingsFrame()
  local settingsFrame = AceGUI:Create("Frame")
  settingsFrame:SetTitle("Entchantments Settings")
  settingsFrame:SetStatusText("Entchantments 1.0.0 by Salmondx")
  settingsFrame:SetWidth(500)
  settingsFrame:SetHeight(500)
  settingsFrame:SetLayout("List")

  local phrasesHeader = AceGUI:Create("Heading")
  phrasesHeader:SetText("Phrases Settings")
  phrasesHeader:SetFullWidth(true)
  settingsFrame:AddChild(phrasesHeader)

  local phrasesEdit = AceGUI:Create("MultiLineEditBox")
  phrasesEdit:SetLabel("Whitelist Phrases")
  phrasesEdit:SetNumLines(6)
  phrasesEdit:SetFullWidth(true)
  phrasesEdit:SetText(self:PhrasesToString(self.db.profile.whitelist, '\n'))
  phrasesEdit:SetCallback("OnEnterPressed", function(widget, event, value) self.db.profile.whitelist = self:ParsePhrases(value) end)
  settingsFrame:AddChild(phrasesEdit)

  local blackListEdit = AceGUI:Create("MultiLineEditBox")
  blackListEdit:SetLabel("Blacklist Phrases")
  blackListEdit:SetNumLines(6)
  blackListEdit:SetFullWidth(true)
  blackListEdit:SetText(self:PhrasesToString(self.db.profile.blacklist, '\n'))
  blackListEdit:SetCallback("OnEnterPressed", function(widget, event, value) self.db.profile.blacklist = self:ParsePhrases(value) end)
  settingsFrame:AddChild(blackListEdit)

  local announceHeader = AceGUI:Create("Heading")
  announceHeader:SetText("Announcement Settings")
  announceHeader:SetFullWidth(true)
  settingsFrame:AddChild(announceHeader)

  local autoreplyEdit = AceGUI:Create("EditBox")
  autoreplyEdit:SetLabel("Autoreply Phrase")
  autoreplyEdit:SetFullWidth(true)
  autoreplyEdit:SetText(self.db.profile.announcement.autoreply)
  autoreplyEdit:SetCallback("OnEnterPressed", function(widget, event, text) self.db.profile.announcement.autoreply = text end)
  settingsFrame:AddChild(autoreplyEdit)

  local tradeEdit = AceGUI:Create("EditBox")
  tradeEdit:SetLabel("Trade Chat Phrase")
  tradeEdit:SetFullWidth(true)
  tradeEdit:SetText(self.db.profile.announcement.trade)
  tradeEdit:SetCallback("OnEnterPressed", function(widget, event, text) self.db.profile.announcement.trade = text end)
  settingsFrame:AddChild(tradeEdit)

  local debugCheckbox = AceGUI:Create("CheckBox")
  debugCheckbox:SetLabel("Debug Mode")
  debugCheckbox:SetFullWidth(true)
  debugCheckbox:SetValue(self.db.profile.debug)
  debugCheckbox:SetCallback("OnValueChanged", function(widget, event, value) self.db.profile.debug = value end)
  settingsFrame:AddChild(debugCheckbox)

end

function Enchantments:ParsePhrases(text)
  local phrases = {}
  for s in text:gmatch("[^\r\n]+") do
    -- trim string
    s = s:gsub("%s+", "")
    if s ~= nil or s ~= '' then
      table.insert(phrases, s)
    end
  end

  return phrases
end

function Enchantments:PhrasesToString(phrases, separator)
  local joinedPhrase = ''
  for i = 1, #phrases do
    if i == 1 then
      joinedPhrase = joinedPhrase .. phrases[i]
    else
      joinedPhrase = joinedPhrase .. separator .. phrases[i]
    end
  end

  return joinedPhrase
end