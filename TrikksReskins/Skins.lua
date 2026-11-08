-- Module: Skins
-- Our own reskin of Blizzard's windows in the Trikks Tweaks look (flat dark
-- panel, 1px border, thin accent line). No Aurora needed.
--
-- How it works: most Blizzard windows are built from the same templates, so
-- they share named parts: a "NineSlice" border, "Bg" background, portrait,
-- "Inset" boxes, tabs with Left/Middle/Right art and buttons with
-- Left/Middle/Right art. We make those parts invisible (opacity 0, so
-- Blizzard re-showing them doesn't matter) and draw our flat style instead.
-- Windows with special parts (like the character window) get a few extra rules.
-- Skins can't be "un-applied", so switching them off needs a reload.
-- Part of TrikksReskins: uses Trikks Tweaks' core (hub, UI kit, module system).
local TT = TrikksTweaks
local C = TT.C

-- key, label, global frame name, load-on-demand Blizzard addon (if any)
local WINDOWS = {
    { "character", "Character",             "CharacterFrame" },
    { "spells",    "Spellbook / talents",   "PlayerSpellsFrame", "Blizzard_PlayerSpells" },
    { "spellbook", "Spellbook (classic)",   "SpellBookFrame" },
    { "friends",   "Friends / social",      "FriendsFrame" },
    { "mail",      "Mail",                  "MailFrame" },
    { "openmail",  "Open mail",             "OpenMailFrame" },
    { "merchant",  "Merchant",              "MerchantFrame" },
    { "gossip",    "NPC chat (gossip)",     "GossipFrame" },
    { "quest",     "Quest window",          "QuestFrame" },
    { "questlog",  "Quest log (classic)",   "QuestLogFrame" },
    { "bank",      "Bank",                  "BankFrame" },
    { "pve",       "Group finder",          "PVEFrame" },
    { "trainer",   "Class trainer",         "ClassTrainerFrame", "Blizzard_TrainerUI" },
    { "profs",     "Professions (crafting)", "ProfessionsFrame", "Blizzard_Professions" },
    { "profbook",  "Professions book",      "ProfessionsBookFrame", "Blizzard_ProfessionsBook" },
    { "gamemenu",  "Game menu (Esc)",       "GameMenuFrame" },
    { "tradeskill","Trade skill (classic)", "TradeSkillFrame", "Blizzard_TradeSkillUI" },
    { "auction",   "Auction house",         "AuctionHouseFrame", "Blizzard_AuctionHouseUI" },
    { "trade",     "Trade",                 "TradeFrame" },
    { "loot",      "Loot",                  "LootFrame" },
    { "dressup",   "Dressing room",         "DressUpFrame" },
    { "taxi",      "Flight map (classic)",  "TaxiFrame" },
    { "inspect",   "Inspect",               "InspectFrame", "Blizzard_InspectUI" },
    { "macro",     "Macros",                "MacroFrame", "Blizzard_MacroUI" },
    { "communities","Guild & communities",  "CommunitiesFrame", "Blizzard_Communities" },
    { "collections","Collections",          "CollectionsJournal", "Blizzard_Collections" },
    { "addons",    "AddOn list",            "AddonList" },
    { "itemtext",  "Books / letters",       "ItemTextFrame" },
    { "stable",    "Pet stable",            "PetStableFrame" },
    { "tabard",    "Tabard designer",       "TabardFrame" },
    { "timemanager","Clock / stopwatch",    "TimeManagerFrame", "Blizzard_TimeManager" },
    { "guildbank", "Guild bank",            "GuildBankFrame", "Blizzard_GuildBankUI" },
    -- 1.1: one checkbox can cover several frames (a list of names)
    { "bags",      "Bags",                  "BAGS" },
    { "flyout",    "Equipment flyout",      "EquipmentFlyoutFrame" },
    { "achieve",   "Achievements",          "AchievementFrame" },
    { "calendar",  "Calendar",              "CalendarFrame" },
    { "journal",   "Adventure guide",       "EncounterJournal" },
    { "transmog",  "Transmog",              { "TransmogFrame", "WardrobeFrame" } },
    { "socket",    "Socketing",             "ItemSocketingFrame" },
    { "upgrade",   "Item upgrade",          "ItemUpgradeFrame" },
    { "scrap",     "Scrapping",             "ScrappingMachineFrame" },
    { "blackmarket","Black market",         "BlackMarketFrame" },
    { "weekly",    "Weekly rewards",        "WeeklyRewardsFrame" },
    { "guildctrl", "Guild control",         "GuildControlUI" },
    { "petition",  "Petition / guild registrar", { "PetitionFrame", "GuildRegistrarFrame" } },
    { "raidinfo",  "Raid info",             "RaidInfoFrame" },
    { "loothist",  "Loot history",          "GroupLootHistoryFrame" },
    { "lootroll",  "Loot rolls",            { "GroupLootFrame1", "GroupLootFrame2", "GroupLootFrame3", "GroupLootFrame4" } },
    { "settings",  "Options (Esc > Options)", "SettingsPanel" },
    { "chatcfg",   "Chat settings",         "ChatConfigFrame" },
    { "colour",    "Colour picker",         "ColorPickerFrame" },
    { "help",      "Help / support",        "HelpFrame" },
    { "mirror",    "Breath / fatigue timers", "MirrorTimerContainer" },
    -- 1.1: chat tabs and edit box (the chat background stays yours to set)
    { "chat",      "Chat (tabs, edit box)", "ChatFrame1" },
    { "xpbar",     "XP / reputation bars",  "StatusTrackingBarManager" },
}
-- the bag windows: the combined bag and every separate one
local BAGS = { "ContainerFrameCombinedBags" }
for i = 1, 13 do BAGS[#BAGS + 1] = "ContainerFrame" .. i end
local function FrameNames(w)
    if w[3] == "BAGS" then return BAGS end
    if type(w[3]) == "table" then return w[3] end
    return { w[3] }
end

local defaults = { buttons = true, tooltips = true, popups = true, style = "grey", lightText = true, bars = true, menus = false, cdm = true, windows = {} }
for _, w in ipairs(WINDOWS) do defaults.windows[w[1]] = true end
local M = TT:RegisterModule("Skins", {
    title = "Skins",
    category = "Reskin",
    addon = "TrikksReskins", svName = "TrikksReskinDB",
    desc = "Reskins Blizzard's windows (character, spellbook, mail, merchant, ...) in the Trikks Tweaks style.",
    defaults = defaults,
})

local function AuroraRunning()
    local f = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    return f and f("Aurora") or false
end

---------------------------------------------------------------------------
-- Engine
---------------------------------------------------------------------------
local S = {}
TT.Skin = S                          -- other modules can use it too

-- In combat the client protects some frames and turns sizes, colours and
-- texture names into "secret" values; skinning then causes Lua errors (e.g.
-- a backdrop doing maths on a secret width). So skin work that would run
-- during combat is remembered (each thing once) and done when combat ends.
local deferred, deferredSet = {}, {}
-- Blizzard tables (mixins, managers) we already hooked: kept here, never as a
-- field on their table (see the stats list below for why)
local hookedTables = {}
local function Defer(fn, obj)
    if not InCombatLockdown() then return false end
    deferredSet[fn] = deferredSet[fn] or {}
    if not deferredSet[fn][obj] then
        deferredSet[fn][obj] = true
        deferred[#deferred + 1] = { fn, obj }
    end
    return true
end
local combatEv = CreateFrame("Frame")
combatEv:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEv:SetScript("OnEvent", function()
    local list = deferred
    deferred, deferredSet = {}, {}
    for _, d in ipairs(list) do
        local ok, err = pcall(d[1], d[2])
        if not ok then geterrorhandler()("Trikks Reskins: " .. tostring(err)) end
    end
end)

-- Border / accent colours. "accent" is the thin line on top of windows, the
-- bar under the selected tab and the selected side tab; "border" is the 1px edge.
local STYLES = {
    grey  = { border = { 0.20, 0.20, 0.22, 1 }, accent = { 0.42, 0.42, 0.45, 1 } },
    black = { border = { 0, 0, 0, 1 },          accent = { 0.30, 0.30, 0.32, 1 } },
    green = { border = { 0.20, 0.20, 0.22, 1 }, accent = C.accent },
}
local function Style() return STYLES[M.db and M.db.style] or STYLES.grey end
local function Border() return Style().border end
local function Accent() return Style().accent end
S.Border, S.Accent = Border, Accent

-- Make something invisible, and keep it that way: Blizzard sometimes sets the
-- opacity back (e.g. item slots on every update), so we answer every SetAlpha
-- with 0 again.
local function KeepHidden(self, a)
    if a ~= 0 and not self.ttHiding then
        self.ttHiding = true
        self:SetAlpha(0)
        self.ttHiding = false
    end
end
function S.Kill(obj)
    if not obj or not obj.SetAlpha then return end
    obj:SetAlpha(0)
    if not obj.ttKept then
        obj.ttKept = true
        hooksecurefunc(obj, "SetAlpha", KeepHidden)
    end
end

-- Blizzard "chrome" (frame borders, panel art, decorative backgrounds), by
-- atlas name. Anything with one of these names anywhere in a skinned window
-- is hidden.
local CHROME = {
    "^_?!?UI%-Frame%-",             -- metal / inner frame borders and tiles
    "^common%-insideframe",
    "^common%-sidetab$", "^common%-sidetab%-hover",
    "^Profession%-Background",      -- painted profession backgrounds
    "^Professions%-Slot%-Frame",
    "^Profession%-ProgressBar%-frame",
    "^UI%-Character%-Info%-Title",  -- brown header plates in the stats list
    "^UI%-Character%-Info%-ScrollLine",
    "^common%-framedivider",        -- the vertical divider lines
    "^UI%-Character%-Info%-GearSlot", -- bronze frames around the gear slots
    "^UIFrameBackground%-NineSlice",
    "^Professions%-QualityPane%-",  -- quality pane plates and dividers
    "^Professions%-Equipment%-Divider",
}
-- On top of that list: anything whose atlas name says it is a background
-- ("...Background...", "...-BG", "...StoneBG3", "Parchment") is decoration and
-- goes too. Progress/status bar backgrounds, icons, glows and gamepad hints stay,
-- because those are part of how something works, not wallpaper.
local KEEP = { "bar", "icon", "glow", "highlight", "gamepad", "button", "slot" }
local function IsBackground(lower)
    if not (lower:find("background") or lower:find("%-bg") or lower:find("bg%d*$")
            or lower:find("parchment")) then
        return false
    end
    for _, k in ipairs(KEEP) do if lower:find(k, 1, true) then return false end end
    return true
end
local function IsChrome(atlas)
    if not atlas or atlas == "" or TT.IsSecret(atlas) then return false end
    for _, pat in ipairs(CHROME) do if atlas:find(pat) then return true end end
    return IsBackground(atlas:lower())
end

-- Dark text was made for parchment; on our dark panels it is unreadable.
-- Every dark colour Blizzard puts on a text inside a skinned window is turned
-- light grey (now and every time Blizzard sets the colour again).
local function Luma(r, g, b) return 0.3 * r + 0.59 * g + 0.11 * b end
local function LightenText(fs, r, g, b, a)
    if fs.ttLighting or not M.db.lightText then return end
    if TT.IsSecret(r) or TT.IsSecret(g) or TT.IsSecret(b) then return end
    if r and Luma(r, g, b) < 0.35 then
        fs.ttLighting = true
        fs:SetTextColor(0.88, 0.88, 0.88, a or 1)
        fs.ttLighting = false
    end
end
function S.LightText(fs)
    if not fs.ttLight then
        fs.ttLight = true
        hooksecurefunc(fs, "SetTextColor", LightenText)
    end
    LightenText(fs, fs:GetTextColor())
end

-- Walk a window and everything inside it; hide chrome, tint the selected side tab.
function S.Deep(frame, depth)
    depth = depth or 0
    if depth == 0 and Defer(S.Deep, frame) then return end
    if depth > 10 or (frame.IsForbidden and frame:IsForbidden()) then return end
    for _, r in ipairs({ frame:GetRegions() }) do
        if r:IsObjectType("Texture") and r.GetAtlas then
            local atlas = r:GetAtlas()
            if TT.IsSecret(atlas) then atlas = nil end
            if atlas == "common-sidetab-selected" then
                if not r.ttTinted then
                    r.ttTinted = true
                    local a = Accent()
                    r:SetDesaturated(true)
                    r:SetVertexColor(a[1], a[2], a[3], 0.8)
                end
            elseif atlas and not TT.IsSecret(atlas) and atlas:find("Options_ListExpand") then
                S.Kill(r)               -- the brown/gold header plate of collapsible lists
                S.Header(frame)
            elseif IsChrome(atlas) then
                S.Kill(r)
            end
        elseif r:IsObjectType("FontString") then
            S.LightText(r)
        end
    end
    if frame:IsObjectType("StatusBar") then S.StatusBar(frame) end
    S.WatchScrollBox(frame)
    for _, child in ipairs({ frame:GetChildren() }) do S.Deep(child, depth + 1) end
end

-- Lists (reputation, skills, currencies, recipes, ...) live in a ScrollBox that
-- only makes rows for what is on screen, and makes more when you scroll or open
-- a header. Blizzard calls the ScrollBox's Update each time: we look at the
-- rows right after (one frame later, so it never runs inside Blizzard's code).
function S.WatchScrollBox(box)
    if box.ttWatched or type(box.GetFrames) ~= "function" or type(box.Update) ~= "function" then return end
    box.ttWatched = true
    local pending = false
    hooksecurefunc(box, "Update", function()
        if pending then return end
        pending = true
        C_Timer.After(0, function() pending = false; S.Deep(box) end)
    end)
end

-- Collapsible list headers ("Horde", "Steamwheedle Cartel", skill groups):
-- the art is gone (see Deep), this gives them a flat bar instead.
function S.Header(btn)
    if btn.ttHeader or not M.db.bars then return end
    btn.ttHeader = true
    TT.Flat(btn, C.panel, Border())
    if btn.HookScript and btn:IsMouseEnabled() then
        btn:HookScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(Accent())) end)
        btn:HookScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(Border())) end)
    end
end

-- Progress bars (reputation, skills, ...): drop the bevelled border pieces and
-- the gradient fill, keep the colour Blizzard gives the bar, draw a 1px edge.
-- Which pieces are border art: parts with a border-ish key or name, or chrome.
local BAR_PARTS = { LeftTexture = true, RightTexture = true, MiddleTexture = true, Border = true,
    BorderLeft = true, BorderRight = true, BorderMid = true, BorderMiddle = true, Background = true,
    BG = true, Bg = true, BarBG = true, BarFrame = true, Frame = true, Left = true, Right = true, Middle = true }
local function IsBarArtName(n)
    n = n:lower()
    return n:find("border$") or n:find("background$") or n:find("bg$") or n:find("frame$")
        or n:find("left$") or n:find("right$")
end
local WHITE = "Interface\\Buttons\\WHITE8x8"
function S.StatusBar(bar)
    if bar.ttSkinned or not M.db.bars or (bar.IsForbidden and bar:IsForbidden()) then return end
    local fill = bar:GetStatusBarTexture()
    if not fill then return end
    bar.ttSkinned = true
    -- which key does each texture have on the bar? (bar.LeftTexture -> "LeftTexture")
    local keyOf = {}
    for k, v in pairs(bar) do
        if type(k) == "string" and not TT.IsSecret(v) and type(v) == "table" then keyOf[v] = k end
    end
    for _, r in ipairs({ bar:GetRegions() }) do
        if r ~= fill and r:IsObjectType("Texture") then
            local key, name = keyOf[r], r:GetName()
            if (key and BAR_PARTS[key]) or (name and IsBarArtName(name)) or IsChrome(r:GetAtlas()) then S.Kill(r) end
        end
    end
    -- a fill made from a file (not an atlas) only carries its colour through
    -- SetStatusBarColor, so a plain white texture keeps that colour, flat.
    -- Atlas fills have the colour painted in: those stay as they are.
    local atlas = fill.GetAtlas and fill:GetAtlas()
    if TT.IsSecret(atlas) then atlas = "?" end                -- can't tell: leave the fill alone
    if not atlas or atlas == "" then
        local r, g, b, a = bar:GetStatusBarColor()
        bar:SetStatusBarTexture(WHITE)
        if r and not (TT.IsSecret(r) or TT.IsSecret(g) or TT.IsSecret(b)) then bar:SetStatusBarColor(r, g, b, a) end
        local t = bar:GetStatusBarTexture()
        if t then t:SetAlpha(0.85) end
    end
    TT.Flat(bar, { 0, 0, 0, 0.45 }, Border())
end

-- flat panel + optional green line on top
function S.Panel(frame, bg, border, accent)
    TT.Flat(frame, bg or C.bg, border or Border())
    if accent and not frame.ttLine then
        local line = frame:CreateTexture(nil, "OVERLAY")
        line:SetPoint("TOPLEFT", 1, -1); line:SetPoint("TOPRIGHT", -1, -1)
        line:SetHeight(2)
        line:SetColorTexture(unpack(Accent()))
        frame.ttLine = line
    end
end

-- the big round "x" close button -> small flat "x"
function S.Close(btn)
    if not btn or btn.ttSkinned then return end
    btn.ttSkinned = true
    for _, t in ipairs({ btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetHighlightTexture(), btn:GetDisabledTexture() }) do
        S.Kill(t)
    end
    local x = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    x:SetPoint("CENTER", 0, 1)
    x:SetText("x")
    x:SetTextColor(unpack(C.dim))
    btn:HookScript("OnEnter", function() x:SetTextColor(1, 0.35, 0.35) end)
    btn:HookScript("OnLeave", function() x:SetTextColor(unpack(C.dim)) end)
end

-- Is this texture button art (the red/grey plate), not an icon on the button?
-- Judged by atlas name: "...button..." is art, "...icon..." never is.
local function AtlasOf(t)
    local a = t and t.GetAtlas and t:GetAtlas()
    if not a or a == "" or TT.IsSecret(a) then return nil end
    return a:lower()
end
local function IsButtonArt(t)
    local a = AtlasOf(t)
    return a and a:find("button", 1, true) and not a:find("icon", 1, true) or false
end

-- standard red/grey Blizzard buttons. Three kinds exist:
--   old:    Left / Middle / Right pieces
--   modern: Left / Right / Center pieces
--   newest: one "StateTexture" with a common-button-* atlas
-- Only the plate goes; icons on the button (the "+" on "New Set") stay.
-- all = true hides every texture (pooled buttons whose art has no names).
local ART_KEYS = { "Left", "Middle", "Right", "Center", "StateTexture", "LeftSeparator", "RightSeparator" }
function S.Button(btn, all)
    if not btn or btn.ttSkinned then return end
    btn.ttSkinned = true
    for _, k in ipairs(ART_KEYS) do S.Kill(btn[k]) end
    local name = btn:GetName()
    if name then for _, k in ipairs({ "Left", "Middle", "Right", "Center" }) do S.Kill(_G[name .. k]) end end
    local icon = btn.Icon or btn.icon
    for _, t in ipairs({ btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetDisabledTexture() }) do
        if t ~= icon and not (AtlasOf(t) or ""):find("icon", 1, true) then S.Kill(t) end
    end
    local hl = btn:GetHighlightTexture()
    for _, r in ipairs({ btn:GetRegions() }) do
        if r:IsObjectType("Texture") and r ~= hl and r ~= icon and (all or IsButtonArt(r)) then S.Kill(r) end
    end
    if hl then hl:SetColorTexture(1, 1, 1, 0.06) end
    TT.Flat(btn, C.panel, Border())
    btn:HookScript("OnEnter", function(self) if self:IsEnabled() then self:SetBackdropBorderColor(unpack(Accent())) end end)
    btn:HookScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(Border())) end)
end

local function IsArtButton(b)
    if not b:IsObjectType("Button") or b:IsObjectType("CheckButton") then return false end
    if b.Left and b.Right and (b.Middle or b.Center) then return true end
    local a = AtlasOf(b.StateTexture)
    return a and a:find("^common%-button") and true or false
end

-- walk a window's children and restyle Blizzard buttons in it
function S.ButtonsIn(frame, depth)
    depth = depth or 0
    if depth == 0 and Defer(S.ButtonsIn, frame) then return end
    if depth > 5 or not M.db.buttons then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        if not (child.IsForbidden and child:IsForbidden()) then
            if IsArtButton(child) then S.Button(child) end
            S.ButtonsIn(child, depth + 1)
        end
    end
end

-- inset boxes inside windows
function S.Inset(inset)
    if not inset or inset.ttSkinned then return end
    inset.ttSkinned = true
    S.Kill(inset.Bg); S.Kill(inset.NineSlice)
    local name = inset.GetName and inset:GetName()
    if name then S.Kill(_G[name .. "Bg"]) end
    S.Panel(inset, { 1, 1, 1, 0.02 }, Border())
end

-- tabs at the bottom / top of windows; the selected one gets a green bar
local tabbed = {}
function S.Tab(tab)
    if not tab or tab.ttSkinned then return end
    tab.ttSkinned = true
    for _, k in ipairs({ "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
                         "LeftHighlight", "MiddleHighlight", "RightHighlight", "LeftDisabled", "MiddleDisabled", "RightDisabled" }) do
        S.Kill(tab[k])
    end
    local name = tab:GetName()
    if name then
        for _, k in ipairs({ "Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled", "HighlightTexture" }) do
            S.Kill(_G[name .. k])
        end
    end
    S.Kill(tab:GetHighlightTexture())
    TT.Flat(tab, C.panel, Border())
    local bar = tab:CreateTexture(nil, "OVERLAY")
    bar:SetPoint("BOTTOMLEFT", 1, 1); bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetHeight(2)
    bar:SetColorTexture(unpack(Accent()))
    bar:Hide()
    tab.ttBar = bar
end

local function TabsOf(frame)
    local list = {}
    if type(frame.Tabs) == "table" then for _, t in ipairs(frame.Tabs) do list[#list + 1] = t end end
    local name = frame:GetName()
    if name then
        for i = 1, 12 do
            local t = _G[name .. "Tab" .. i]
            if t then list[#list + 1] = t end
        end
    end
    return list
end

function S.TabState(frame)
    local tabs = tabbed[frame]
    if not tabs then return end
    for i, tab in ipairs(tabs) do
        local selected = frame.selectedTab == i or frame.selectedTab == tab:GetID()
        if tab.ttBar then tab.ttBar:SetShown(selected) end
    end
end

function S.Tabs(frame)
    local tabs = TabsOf(frame)
    if #tabs == 0 then return end
    for _, t in ipairs(tabs) do S.Tab(t) end
    tabbed[frame] = tabs
    S.TabState(frame)
end
-- look at a skinned window again, one frame later, at most once per frame
-- (pages like the currency list load / fill in after the tab is clicked)
function S.Later(frame)
    if not frame or not frame.ttReskin or frame.ttLater then return end
    frame.ttLater = true
    C_Timer.After(0, function()
        frame.ttLater = nil
        local ok, err = pcall(frame.ttReskin)
        if not ok then geterrorhandler()("Trikks Tweaks skin: " .. tostring(err)) end
    end)
end
for _, fn in ipairs({ "PanelTemplates_UpdateTabs", "PanelTemplates_SetTab" }) do
    if type(_G[fn]) == "function" then
        hooksecurefunc(fn, function(frame)
            if not frame then return end
            if tabbed[frame] then S.TabState(frame) end
            S.Later(frame)
        end)
    end
end

-- item buttons (gear slots, ...): the same square look as Clean Action
-- Buttons. Square cropped icon in a flat dark box; the item's quality colour
-- (green, blue, purple) moves from Blizzard's glow frame onto the box's edge.
function S.SetQualityBorder(btn, quality)
    if not btn.SetBackdropBorderColor then return end
    local c = quality and not TT.IsSecret(quality) and quality >= 1 and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if c then btn:SetBackdropBorderColor(c.r, c.g, c.b, 1) else btn:SetBackdropBorderColor(0, 0, 0, 1) end
end
function S.ItemButton(btn)
    if not btn or btn.ttSkinned then return end
    if Defer(S.ItemButton, btn) then return end
    btn.ttSkinned = true
    local name = btn:GetName()
    local icon = btn.icon or btn.Icon or (name and _G[name .. "IconTexture"])
    if icon then
        -- the round-cornered mask makes icons look soft; square them off
        if btn.Mask and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, btn.Mask) end
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)       -- cut off the icon's own baked-in border
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", 1, -1); icon:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    S.Kill(btn:GetNormalTexture())
    S.Kill(btn.BorderFrame)                                -- the bronze slot frame
    if name then S.Kill(_G[name .. "Frame"]); S.Kill(_G[name .. "NormalTexture"]) end
    for _, r in ipairs({ btn:GetRegions() }) do
        if r:IsObjectType("Texture") and IsChrome(r.GetAtlas and r:GetAtlas()) then S.Kill(r) end
    end
    -- flat hover / click instead of the glossy ones
    local hl = btn:GetHighlightTexture()
    if hl then hl:SetColorTexture(1, 1, 1, 0.12); hl:ClearAllPoints(); hl:SetAllPoints(icon or btn) end
    local pushed = btn:GetPushedTexture()
    if pushed then pushed:SetColorTexture(1, 1, 1, 0.2); pushed:ClearAllPoints(); pushed:SetAllPoints(icon or btn) end
    TT.Flat(btn, { 0.03, 0.03, 0.04, 1 }, { 0, 0, 0, 1 })
    -- quality colour: Blizzard tints IconBorder and shows/hides it; copy that
    -- colour to our edge whenever it changes, and keep IconBorder itself hidden
    local ib = btn.IconBorder
    if ib then
        S.Kill(ib)
        local function Sync()
            if ib:IsShown() then
                local r, g, b = ib:GetVertexColor()
                if r and not (TT.IsSecret(r) or TT.IsSecret(g) or TT.IsSecret(b)) then
                    btn:SetBackdropBorderColor(r, g, b, 1)
                    return
                end
            end
            btn:SetBackdropBorderColor(0, 0, 0, 1)
        end
        for _, fn in ipairs({ "SetVertexColor", "Show", "Hide", "SetShown" }) do hooksecurefunc(ib, fn, Sync) end
        Sync()
    end
end

-- equipment slots, for the character and inspect windows
local GEAR = { "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands",
               "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
               "MainHand", "SecondaryHand", "Ranged", "Ammo" }

-- a whole standard window
function S.Window(frame)
    if not frame or frame.ttSkinned then return end
    frame.ttSkinned = true
    local name = frame:GetName()
    for _, k in ipairs({ "NineSlice", "Bg", "Background", "TitleBg", "TopTileStreaks", "PortraitContainer",
                         "portrait", "Portrait", "PortraitFrame", "TitleMarquee" }) do
        S.Kill(frame[k])
    end
    if name then
        for _, k in ipairs({ "Bg", "TitleBg", "Portrait", "PortraitFrame", "TopTileStreaks",
                             "TopLeft", "TopRight", "BotLeft", "BotRight", "BottomLeft", "BottomRight",
                             "TopBorder", "BottomBorder", "LeftBorder", "RightBorder",
                             "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner" }) do
            S.Kill(_G[name .. k])
        end
    end
    S.Panel(frame, C.bg, Border(), true)
    local title = (frame.TitleContainer and frame.TitleContainer.TitleText) or frame.TitleText or (name and _G[name .. "TitleText"])
    if title then title:SetTextColor(unpack(C.text)) end
    for _, inset in ipairs({ frame.Inset, frame.InsetRight, frame.InsetLeft, name and _G[name .. "Inset"] }) do S.Inset(inset) end
    S.Close(frame.CloseButton or (name and _G[name .. "CloseButton"]))
    S.Tabs(frame)
    S.ButtonsIn(frame)
    S.Deep(frame)
    -- some windows create their buttons / tabs / panels only when first opened:
    -- look again each time the window opens (already-done parts are skipped)
    local function Again()
        if Defer(frame.ttReskin, frame) then return end
        S.Tabs(frame)
        S.ButtonsIn(frame)
        S.Deep(frame)
    end
    frame.ttReskin = Again
    -- and once more a moment later: lists and pages fill in right after OnShow
    frame:HookScript("OnShow", function() Again(); C_Timer.After(0.1, Again) end)
end

---------------------------------------------------------------------------
-- Extra rules for windows with special parts
---------------------------------------------------------------------------
local EXTRA = {}

EXTRA.GameMenuFrame = function()
    S.Kill(GameMenuFrame.Border)                 -- the dialog border around the menu
    -- the menu's buttons come from a pool and are (re)made in InitButtons each time it opens
    local function SkinPool(menu)
        if menu.buttonPool then
            for b in menu.buttonPool:EnumerateActive() do S.Button(b, true) end
        end
    end
    if GameMenuFrame.InitButtons then hooksecurefunc(GameMenuFrame, "InitButtons", SkinPool) end
    SkinPool(GameMenuFrame)
    local header = GameMenuFrame.Header
    if header then
        for _, r in ipairs({ header:GetRegions() }) do
            if r:IsObjectType("Texture") then S.Kill(r) end
        end
    end
end

-- Professions: pages (crafting, specializations, orders) are built when you
-- first switch to them, and the art changes per profession: look again then.
-- A flat panel as a separate child frame behind something (so nothing is
-- mixed into Blizzard's own frame), and a set of things already done.
local function FlatBehind(parent, l, t, r, b)
    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", l, t); bg:SetPoint("BOTTOMRIGHT", r, b)
    bg:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))
    return bg
end
local extraSkinned = {}

-- The professions book (Forever: a page of this window, "BookPage"): one card
-- per profession. The card art (brown box + illustration, one atlas:
-- "Profession-overview-Card-...") goes, a flat panel goes behind instead; the
-- skill bars lose their frame and background; the spell buttons get a square
-- 1px edge; the red crossmark becomes a small flat "x". Spell buttons are
-- secure, so our edges are separate child frames, nothing is mixed into them.
local CARDS = { "PrimaryProfession1", "PrimaryProfession2",
                "SecondaryProfession1", "SecondaryProfession2", "SecondaryProfession3" }
local function SkinCard(card)
    if extraSkinned[card] then return end
    extraSkinned[card] = true
    S.Kill(card.Background)
    TT.Flat(FlatBehind(card, 0, 0, 0, 0), { 1, 1, 1, 0.03 }, Border())
    local bar = card.StatusBar
    if bar then
        S.Kill(bar.Background); S.Kill(bar.Border)
        TT.Flat(FlatBehind(bar, -1, 1, 1, -1), { 0, 0, 0, 0.55 }, Border())
    end
    for i = 1, 4 do
        local b = card["SpellButton" .. i]
        if b then
            S.Kill(b.IconBorder)
            TT.Flat(FlatBehind(b, -1, 1, 1, -1), { 0.03, 0.03, 0.04, 1 }, { 0, 0, 0, 1 })
        end
    end
    local un = card.UnlearnButton
    if un then
        S.Kill(un.Icon); S.Kill(un.NormalTexture)
        local x = un:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        x:SetPoint("CENTER", 0, 1)
        x:SetText("x")
        x:SetTextColor(unpack(C.dim))
        un:HookScript("OnEnter", function() x:SetTextColor(1, 0.35, 0.35) end)
        un:HookScript("OnLeave", function() x:SetTextColor(unpack(C.dim)) end)
    end
end
local function SkinBookPage()
    local page = ProfessionsFrame and ProfessionsFrame.BookPage
    local content = page and page.ProfessionsContentFrame
    if not content then return end
    if Defer(SkinBookPage, "book") then return end
    for _, k in ipairs(CARDS) do
        if content[k] then SkinCard(content[k]) end
    end
end

EXTRA.ProfessionsFrame = function()
    local f = ProfessionsFrame
    local function Again() C_Timer.After(0, f.ttReskin); C_Timer.After(0, SkinBookPage) end
    SkinBookPage()
    for _, fn in ipairs({ "SetTab", "Refresh", "SetProfessionInfo" }) do
        if type(f[fn]) == "function" then hooksecurefunc(f, fn, Again) end
    end
    if f.TabSystem and f.TabSystem.SetTab then hooksecurefunc(f.TabSystem, "SetTab", Again) end
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("Professions.ProfessionSelected", Again, M)
    end
end

-- quest and NPC text is re-filled every time: look again when it is
local function QuestText()
    for _, n in ipairs({ "QuestFrame", "GossipFrame" }) do
        local f = _G[n]
        if f and f.ttReskin and f:IsShown() then f.ttReskin() end
    end
end
if type(QuestInfo_Display) == "function" then hooksecurefunc("QuestInfo_Display", QuestText) end
EXTRA.GossipFrame = function()
    if GossipFrame.Update then hooksecurefunc(GossipFrame, "Update", function() C_Timer.After(0, QuestText) end) end
end

-- bags: every slot square with a quality edge (slots are made / refilled in UpdateItems)
local function SkinBagItems(frame)
    if type(frame.EnumerateValidItems) ~= "function" then return end
    for _, b in frame:EnumerateValidItems() do S.ItemButton(b) end
end
local function BagExtra(frame)
    if type(frame.UpdateItems) == "function" then hooksecurefunc(frame, "UpdateItems", SkinBagItems) end
    SkinBagItems(frame)
end
for _, n in ipairs(BAGS) do EXTRA[n] = BagExtra end

-- frames that get only their own rule, no window panel
local NOPANEL = { EquipmentFlyoutFrame = true, MirrorTimerContainer = true }

-- the "pick another item for this slot" popup on the character window
EXTRA.EquipmentFlyoutFrame = function(f)
    local bf = f.buttonFrame
    if bf then
        for _, r in ipairs({ bf:GetRegions() }) do if r:IsObjectType("Texture") then S.Kill(r) end end
        S.Kill(bf.NineSlice)
        S.Panel(bf, C.bg, Border())
    end
    if type(EquipmentFlyout_DisplayButton) == "function" then
        hooksecurefunc("EquipmentFlyout_DisplayButton", function(button) S.ItemButton(button) end)
    end
end

-- breath / fatigue / feign death bars: drop the cast-bar frame art, flat edge
EXTRA.MirrorTimerContainer = function(f)
    local function SkinTimer(t)
        if t.ttSkinned or not t.StatusBar then return end
        t.ttSkinned = true
        S.Kill(t.Border); S.Kill(t.TextBorder)
        for _, r in ipairs({ t:GetRegions() }) do
            if r:IsObjectType("Texture") then S.Kill(r) end
        end
        for _, r in ipairs({ t.StatusBar:GetRegions() }) do
            if r:IsObjectType("Texture") and r ~= t.StatusBar:GetStatusBarTexture() then S.Kill(r) end
        end
        TT.Flat(t.StatusBar, { 0, 0, 0, 0.5 }, Border())
    end
    local function All()
        if Defer(All, f) then return end                            -- breath bars can start mid-fight
        for _, t in ipairs({ f:GetChildren() }) do SkinTimer(t) end
    end
    if type(f.SetupTimer) == "function" then hooksecurefunc(f, "SetupTimer", All) end
    All()
end

-- Chat: flat tabs (accent line under the selected one) and a flat edit box.
-- The chat background itself stays Blizzard's: its colour and opacity are a
-- setting in the chat window's own options. Our panels are separate child
-- frames behind Blizzard's, so nothing is mixed into the chat frames: the edit
-- box sends secure commands (/cast, ...) and stays free of addon code.
local function SkinChatFrame(name)
    if extraSkinned[name] then return end
    local cf = _G[name]
    if not cf then return end
    extraSkinned[name] = true

    local tab = _G[name .. "Tab"]
    if tab then
        for _, k in ipairs({ "Left", "Middle", "Right", "ActiveLeft", "ActiveMiddle", "ActiveRight",
                             "HighlightLeft", "HighlightMiddle", "HighlightRight" }) do
            S.Kill(tab[k])
        end
        -- the tab's art only fills the bottom part of the 32px button
        local bg = FlatBehind(tab, 2, -8, -2, 2)
        TT.Flat(bg, C.panel, Border())
        local bar = bg:CreateTexture(nil, "OVERLAY")
        bar:SetPoint("BOTTOMLEFT", 1, 1); bar:SetPoint("BOTTOMRIGHT", -1, 1)
        bar:SetHeight(2)
        bar:SetColorTexture(unpack(Accent()))
        bar:SetShown(tab.ActiveMiddle and tab.ActiveMiddle:IsShown() or false)
        extraSkinned[tab] = bar
        -- the "new message" glow: our accent colour instead of gold
        if tab.glow then tab.glow:SetVertexColor(unpack(Accent())) end
    end

    local eb = cf.editBox or _G[name .. "EditBox"]
    if eb then
        for _, k in ipairs({ "Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid" }) do
            S.Kill(_G[name .. "EditBox" .. k])
        end
        S.Kill(eb.focusLeft); S.Kill(eb.focusRight); S.Kill(eb.focusMid)
        local bg = FlatBehind(eb, 2, -4, -2, 4)
        TT.Flat(bg, { C.bg[1], C.bg[2], C.bg[3], 0.9 }, Border())
        -- typing: accent edge, like a focused box elsewhere
        eb:HookScript("OnEditFocusGained", function() bg:SetBackdropBorderColor(unpack(Accent())) end)
        eb:HookScript("OnEditFocusLost", function() bg:SetBackdropBorderColor(unpack(Border())) end)
    end
end
local function SkinAllChat()
    if Defer(SkinAllChat, "chat") then return end
    for _, name in ipairs(CHAT_FRAMES or {}) do SkinChatFrame(name) end
    for i = 1, NUM_CHAT_WINDOWS or 10 do SkinChatFrame("ChatFrame" .. i) end
end
NOPANEL.ChatFrame1 = true
EXTRA.ChatFrame1 = function()
    SkinAllChat()
    -- selected tab: Blizzard shows / hides its (now invisible) "active" art here
    if type(FCFTab_UpdateColors) == "function" then
        hooksecurefunc("FCFTab_UpdateColors", function(tab, selected)
            local bar = extraSkinned[tab]
            if bar then bar:SetShown(selected and true or false) end
        end)
    end
    -- whisper / pet battle windows opened later
    if type(FCF_OpenTemporaryWindow) == "function" then
        hooksecurefunc("FCF_OpenTemporaryWindow", function() C_Timer.After(0, SkinAllChat) end)
    end
end

-- XP / reputation / honor bars at the bottom of the screen: the frame around
-- them and their background go, a flat dark panel with a 1px edge goes behind
-- each bar. The fills stay Blizzard's (they carry the colours: XP, rested,
-- reputation level, ...). Panels are child frames of the bars, nothing is
-- written into Blizzard's bar code.
NOPANEL.StatusTrackingBarManager = true
EXTRA.StatusTrackingBarManager = function(mgr)
    local function SkinBar(bar)
        local sb = bar and bar.StatusBar
        if not sb or extraSkinned[sb] then return end
        extraSkinned[sb] = true
        S.Kill(sb.Background); S.Kill(sb.Underlay)
        local bg = FlatBehind(sb, -1, 1, 1, -1)
        TT.Flat(bg, { 0, 0, 0, 0.55 }, Border())
    end
    local function All()
        if Defer(All, mgr) then return end
        for _, c in ipairs(mgr.barContainers or { MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
            if c then
                S.Kill(c.BarFrameTexture)
                for _, bar in pairs(c.bars or {}) do SkinBar(bar) end
            end
        end
    end
    All()
end

EXTRA.InspectFrame = function()
    for _, slot in ipairs(GEAR) do S.ItemButton(_G["Inspect" .. slot .. "Slot"]) end
    if type(InspectPaperDollItemSlotButton_Update) == "function" then
        hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(b)
            local unit = InspectFrame and InspectFrame.unit
            if b and b.ttSkinned and unit then S.SetQualityBorder(b, GetInventoryItemQuality(unit, b:GetID())) end
        end)
    end
end

EXTRA.CharacterFrame = function()
    -- the painted background behind your character model and its inner border
    for _, corner in ipairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
        S.Kill(_G["CharacterModelFrameBackground" .. corner])
    end
    S.Kill(CharacterModelFrameBackgroundOverlay)
    for _, part in ipairs({ "TopLeft", "TopRight", "BottomLeft", "BottomRight", "Left", "Right", "Top", "Bottom", "Bottom2" }) do
        S.Kill(_G["PaperDollInnerBorder" .. part])
    end
    local strip = PaperDollFrame and PaperDollFrame.TopBackgroundStripHost
    if strip then S.Kill(strip.TopBackgroundStrip); S.Kill(strip.TopBackgroundStripBottomEdge) end
    -- equipment slots; after Blizzard updates a slot, colour its edge by the
    -- quality of what you wear there (the IconBorder copy covers the rest)
    for _, slot in ipairs(GEAR) do S.ItemButton(_G["Character" .. slot .. "Slot"]) end
    if type(PaperDollItemSlotButton_Update) == "function" then
        hooksecurefunc("PaperDollItemSlotButton_Update", function(b)
            if b and b.ttSkinned then S.SetQualityBorder(b, GetInventoryItemQuality("player", b:GetID())) end
        end)
    end
    for _, inset in ipairs({ CharacterFrame.LeftPaneHost, CharacterFrame.RightPaneHost }) do S.Inset(inset) end
    -- stats list: brown header plates and the striped row backgrounds
    local function FlatRow(element)
        if element and element.Background then
            element.Background:SetColorTexture(1, 1, 1, 0.03)
        end
    end
    for _, mixin in ipairs({ CharacterStatFrameCategoryScrollBoxElementMixin, CharacterStatFrameScrollBoxBaseElementMixin }) do
        -- remember hooked mixins in OUR table: a flag written into Blizzard's mixin
        -- would be copied into every row Blizzard builds, and reading our value
        -- taints Blizzard's code -> "secret value ... tainted by TrikksReskins"
        if mixin and mixin.Init and not hookedTables[mixin] then
            hookedTables[mixin] = true
            hooksecurefunc(mixin, "Init", FlatRow)
        end
    end
    if type(PaperDollFrame_SetStat) == "function" then
        hooksecurefunc("PaperDollFrame_SetStat", function(statFrame) FlatRow(statFrame) end)
    end
end

---------------------------------------------------------------------------
-- Tooltips and popups
---------------------------------------------------------------------------
local function SkinTooltip(tt)
    if not tt or not tt.NineSlice then return end
    local ns = tt.NineSlice
    if ns.SetCenterColor then ns:SetCenterColor(C.bg[1], C.bg[2], C.bg[3], 0.95) end
    local b = Border()
    if ns.SetBorderColor then ns:SetBorderColor(b[1], b[2], b[3], 1) end
end

local function SkinPopups()
    for i = 1, 4 do
        local p = _G["StaticPopup" .. i]
        if p and not p.ttSkinned then
            p.ttSkinned = true
            S.Kill(p.NineSlice); S.Kill(p.Border); S.Kill(p.BG)
            S.Panel(p, C.bg, Border(), true)
            S.ButtonsIn(p)
        end
    end
end

-- Dropdown menus (Blizzard's menu system, 11.0+): hide the menu's own
-- background art and put a flat panel behind it. Our panel is a separate child
-- frame, so nothing is written into Blizzard's menu frame itself.
local function SkinMenu(menu)
    if not menu or menu.ttMenu then return end
    menu.ttMenu = true
    for _, r in ipairs({ menu:GetRegions() }) do
        if r:IsObjectType("Texture") then
            local a = r.GetAtlas and r:GetAtlas()
            if a and not TT.IsSecret(a) and a:find("dropdown") and a:find("bg") then S.Kill(r) end
        end
    end
    local bg = CreateFrame("Frame", nil, menu, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", 2, -2); bg:SetPoint("BOTTOMRIGHT", -2, 2)
    bg:SetFrameLevel(math.max(0, menu:GetFrameLevel() - 1))
    S.Panel(bg, C.bg, Border(), false)
end
local function HookMenus()
    if not (Menu and Menu.GetManager) then return end
    local manager = Menu.GetManager()
    if not manager or hookedTables[manager] then return end
    hookedTables[manager] = true
    local function Latest()
        C_Timer.After(0, function()
            local m = manager.GetOpenMenu and manager:GetOpenMenu()
            if m and not InCombatLockdown() then SkinMenu(m) end      -- menus are short-lived: skip in combat
        end)
    end
    for _, fn in ipairs({ "OpenMenu", "OpenContextMenu" }) do
        if type(manager[fn]) == "function" then hooksecurefunc(manager, fn, Latest) end
    end
end

-- Blizzard's Cooldown Manager icons (Essential, Utility, Tracked Buffs): square
-- cropped icon with a 1px edge, like Clean Action Buttons. Only the look
-- changes: the rounded mask and the overlay ring go, our edge is a separate
-- child frame. Timers, visibility and everything secret stay Blizzard's. The
-- hooks only schedule the work for the next frame (never run inside Blizzard's code).
local CDM_VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer" }
local SQUARE = "Interface\\Buttons\\WHITE8x8"
local function FlatCDMIcon(item)
    if item.ttFlat or not item.Icon then return end
    item.ttFlat = true
    local icon = item.Icon
    for _, r in ipairs({ item:GetRegions() }) do
        if r:IsObjectType("MaskTexture") then
            pcall(icon.RemoveMaskTexture, icon, r)
        elseif r:IsObjectType("Texture") and r ~= icon then
            local a = r.GetAtlas and r:GetAtlas()
            if a and not TT.IsSecret(a) and a:find("IconOverlay") then S.Kill(r) end
        end
    end
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Blizzard draws the icon bigger than its slot and trims it round with the
    -- mask; without the mask the square would spill into the next icon. Fit the
    -- icon (and its swipe) inside the slot, 1px in, so the edge fits too and
    -- the gaps between icons are Blizzard's own "Padding" setting.
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
    if item.Cooldown then
        item.Cooldown:ClearAllPoints()
        item.Cooldown:SetAllPoints(icon)
    end
    -- the 1px edge is a plain black texture 1px bigger than the icon, behind it.
    -- (Not a backdrop: a backdrop recalculates in Lua whenever the size
    -- changes, and these icons' sizes are secret in combat -> Lua error.)
    local edge = item:CreateTexture(nil, "BACKGROUND", nil, -8)
    edge:SetPoint("TOPLEFT", icon, -1, 1); edge:SetPoint("BOTTOMRIGHT", icon, 1, -1)
    edge:SetColorTexture(0, 0, 0, 1)
    if item.Cooldown and item.Cooldown.SetSwipeTexture then
        pcall(item.Cooldown.SetSwipeTexture, item.Cooldown, SQUARE)
    end
end
local cdmPending = false
local function FlatCDMAll()
    cdmPending = false
    -- No combat wait here: flattening an icon is safe in combat (no protected
    -- frames, no Lua maths on the secret sizes since the edge is a texture),
    -- and icons that first appear mid-fight (procs like Riposte) need it then.
    for _, n in ipairs(CDM_VIEWERS) do
        local v = _G[n]
        if v and v.itemFramePool then
            for item in v.itemFramePool:EnumerateActive() do FlatCDMIcon(item) end
        end
    end
end
local function QueueCDM()
    if cdmPending then return end
    cdmPending = true
    C_Timer.After(0, FlatCDMAll)
end
local function HookCDM()
    for _, n in ipairs(CDM_VIEWERS) do
        local v = _G[n]
        if v and not v.ttCDMHooked and type(v.RefreshLayout) == "function" then
            v.ttCDMHooked = true
            hooksecurefunc(v, "RefreshLayout", QueueCDM)
        end
    end
    QueueCDM()
end

---------------------------------------------------------------------------
-- Applying
---------------------------------------------------------------------------
local function SkinWindow(w)
    if not M.db.windows[w[1]] then return end
    if Defer(SkinWindow, w) then return end
    for _, name in ipairs(FrameNames(w)) do
        local frame = _G[name]
        if frame and not frame.ttSkinned then
            local ok, err = true, nil
            if NOPANEL[name] then
                frame.ttSkinned = true
            else
                ok, err = pcall(S.Window, frame)
            end
            if ok and EXTRA[name] then ok, err = pcall(EXTRA[name], frame) end
            if not ok then geterrorhandler()("Trikks Reskins skin " .. name .. ": " .. tostring(err)) end
        end
    end
end

local function ApplyAll()
    if not M.enabled or AuroraRunning() then return end
    for _, w in ipairs(WINDOWS) do SkinWindow(w) end
    if M.db.popups then SkinPopups() end
    if M.db.menus then HookMenus() end
    if M.db.cdm then HookCDM() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, event, addon)
    if not M.enabled or AuroraRunning() then return end
    if event == "PLAYER_LOGIN" then
        ApplyAll()
        if M.db.tooltips then
            for _, tt in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, EmbeddedItemTooltip }) do
                if tt then tt:HookScript("OnShow", SkinTooltip) end
            end
            if type(SharedTooltip_SetBackdropStyle) == "function" then
                hooksecurefunc("SharedTooltip_SetBackdropStyle", function(tt) SkinTooltip(tt) end)
            end
        end
    else
        -- a load-on-demand window may have just loaded (auction house, talents,
        -- calendar, ...): try every window that isn't skinned yet (cheap: done
        -- and missing ones are skipped), so we don't depend on addon names
        for _, w in ipairs(WINDOWS) do SkinWindow(w) end
        if M.db.menus then HookMenus() end
        if M.db.cdm then HookCDM() end
        -- it may have added a page to a window that is already open
        -- (Blizzard_TokenUI -> currency list in the character window)
        if IsLoggedIn() then
            for _, w in ipairs(WINDOWS) do
                local f = _G[w[3]]
                if f and f.ttSkinned and f:IsShown() then S.Later(f) end
            end
        end
    end
end)

StaticPopupDialogs["TRIKKSTWEAKS_RELOAD"] = StaticPopupDialogs["TRIKKSTWEAKS_RELOAD"] or {
    text = "%s\n\nReload your UI now?",
    button1 = RELOADUI or "Reload", button2 = LATER or "Later",
    OnAccept = function() C_UI.Reload() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

function M:OnEnable() if IsLoggedIn() then ApplyAll() end end
function M:OnDisable()
    StaticPopup_Show("TRIKKSTWEAKS_RELOAD", "Skins turned off. A reload brings Blizzard's look back.")
end

function M:BuildSettings(body, page)
    local db, checks, y = M.db, {}, 0
    local warn = TT.Label(body, "", "GameFontRedSmall")
    warn:SetPoint("TOPLEFT", 0, -y)
    warn:SetWidth(560)
    y = y + 22
    local function Head(text)
        local h = TT.Label(body, text:upper(), "GameFontNormalSmall")
        h:SetTextColor(unpack(TT.C.dim)); h:SetPoint("TOPLEFT", 0, -y); y = y + 20
    end
    local function Check(tbl, key, text, x)
        local cb = TT.Check(body, text, function(v)
            tbl[key] = v
            TT.Print("skin changes apply after a /reload.")
        end)
        cb:SetPoint("TOPLEFT", (x or 0) + 2, -y)
        checks[#checks + 1] = function() cb:SetChecked(tbl[key]) end
        return cb
    end
    Head("General")
    Check(db, "buttons", "Restyle buttons inside skinned windows"); y = y + 24
    Check(db, "tooltips", "Flat tooltips"); y = y + 24
    Check(db, "popups", "Flat pop-up dialogs"); y = y + 24
    Check(db, "bars", "Flat progress bars and list headers (reputation, skills, ...)"); y = y + 24
    Check(db, "lightText", "Make dark text light (for windows that had parchment behind them)"); y = y + 24
    Check(db, "menus", "Flat dropdown menus (experimental: turn off if a menu option stops working)"); y = y + 24
    Check(db, "cdm", "Flat Cooldown Manager icons (square, thin edge)"); y = y + 28
    local sl = TT.Label(body, "Borders & accent lines:")
    sl:SetPoint("TOPLEFT", 2, -y - 4)
    local styleBtn = TT.Cycle(body, 120, { { "grey", "Dark grey" }, { "black", "Black" }, { "green", "Green" } },
        function() return db.style end,
        function(v) db.style = v; TT.Print("skin changes apply after a /reload.") end)
    styleBtn:SetPoint("LEFT", sl, "RIGHT", 10, 0)
    checks[#checks + 1] = styleBtn.Refresh
    y = y + 30
    Head("Windows")
    -- two columns of window checkboxes
    for i, w in ipairs(WINDOWS) do
        local col = (i - 1) % 2
        Check(db.windows, w[1], w[2], col * 280)
        if col == 1 or i == #WINDOWS then y = y + 24 end
    end
    local help = TT.Label(body,
        "Changes here apply after a /reload.", "GameFontDisableSmall")
    help:SetPoint("TOPLEFT", 0, -y - 8)
    page.OnPageShow = function()
        for _, f in ipairs(checks) do f() end
        warn:SetText(AuroraRunning() and "Aurora is still running: our skins are paused. Disable Aurora in the AddOns list (or delete its folder) and /reload." or "")
    end
end
