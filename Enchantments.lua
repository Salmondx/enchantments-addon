Enchantments = LibStub("AceAddon-3.0"):NewAddon("Enchantments", "AceConsole-3.0", "AceEvent-3.0")
local EnchantmentsLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Enchantments", {
  type = "data source",
  text = "Enchantments",
  icon = "Interface\\Icons\\Spell_ChargeNegative",
  OnClick = function() Enchantments:Trigger() end,
  OnTooltipShow = function(tooltip) Enchantments:Tooltip(tooltip) end,
})
local icon = LibStub("LibDBIcon-1.0")

function Enchantments:OnInitialize()
  self:Print("Available commands: /ench on | /ench off")
  self.db = LibStub("AceDB-3.0"):New("EnchantmentsDB", {
    profile = {
      minimap = { hide = false }
    }
  })

  self.enabled = false
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

-- Addon on/off state handling
function Enchantments:Enable()
  self:Print("enabled")
  self.enabled = true
  EnchantmentsLDB.icon = "Interface\\Icons\\Spell_ChargePositive"

  self:RegisterEvent("CHAT_MSG_CHANNEL")
end

function Enchantments:Disable()
  self:Print("disabled")
  self.enabled = false
  EnchantmentsLDB.icon = "Interface\\Icons\\Spell_ChargeNegative"

  self:UnregisterEvent("CHAT_MSG_CHANNEL")
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
end

-- Chat parser
function Enchantments:CHAT_MSG_CHANNEL(_, text, playerName, _, _, _, _, zoneChannelID, _, _, _, lineID, _, bnSenderID, ...)
  local lcText = text:lower()
  -- check that text doesn't contain words that we are not interested in
  if HasBannedWord(lcText) then return end

  if not HasSearchWord(lcText) then return end
  -- print message to chat
  self:Printf("|cff1E90FF|Hplayer:%s:%s|h[%s]|h|r: |cffFFFF66|%s|r", playerName, zoneChannelID, playerName, text)
  -- sound action window close. For open: 5274
  PlaySound(5275)
end

function HasBannedWord(text)
  local bannedWords = { '300', 'lfw', 'phase', 'looking for work', 'best enchants', 'and .* other .*', 'your mats' }

  for i = 1, #bannedWords do
    if text:find(bannedWords[i]) then return true end
  end

  return false
end

function HasSearchWord(text)
  local wordsToSearch = {
    'enchanter', 'ench', 'enchanter', '.* lf .* enchanter',
    'crusader', 'fiery', 'agility', '3 stats', 'riding skill',
    '55 healing', '30 spell', 'who can .* enchant', 'healing power',
    '4 stats', '.* wtb .* ench'
  }

  for i = 1, #wordsToSearch do
    if text:match(wordsToSearch[i]) then return true end
  end

  return false
end

-- Register Commands and Events
Enchantments:RegisterChatCommand("ench", "HandleSlashInput")