--[[
    TradeValueOverlay for Bee Swarm Simulator -- "BSS Index Tools"
    Shows a price (Val) on every trade slot, per-side totals, the diff and an
    auto-convert strip that splits the diff into fixed-price item icons.
    Settings live in getgenv().BSS_INDEX_SETTINGS (gear next to the brand label).

    Price sources (100% our own data: two generated local modules, no network):
      * Stickers/cosmetics: embedded PRICES table (bss-index, 16.10.2026), then
        SITE_PRICES (11 hand-checked means), then bss_index_stickers.luau
        (generated from the site's prices.tsv), then "?".
      * Beequips: the item's REAL roll is matched against OUR OWN site data
        (stat signature from BeeStatMods/StatModifiers descriptions + wax state
        + stars), so a ~1 Val roll of a 167 Val beequip is priced at ~1, not 167.
        No flat price fallback for beequips on purpose: a confident wrong number
        is worse than "?".
    Beequip source priority: bss_index_values.luau (own snapshot of the site's
    beequips_prices.json) -> fresh JSON from our own site, but only if
    INDEX_API_URL is filled in -> "?". No third-party price site is contacted.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TextService = game:GetService("TextService")

local TradeGui = require(game.ReplicatedStorage.Gui.TradeGui)
local StickerTypes = require(game.ReplicatedStorage.Stickers.StickerTypes)
local BeequipTypes = require(game.ReplicatedStorage.Beequips.BeequipTypes)
local BeequipFile = require(game.ReplicatedStorage.Beequips.BeequipFile)
local BeeStatMods = require(game.ReplicatedStorage.BeeStats.BeeStatMods)
local StatModifiers = require(game.ReplicatedStorage.StatModifiers)

-- ===== prices (Val) =====
local PRICES = {
    ["Bee Cub Skin"] = 290
,
    ["Snow Cub Skin"] = 175
,
    ["Peppermint Robo Cub Skin"] = 165
,
    ["Gloomy Cub Skin"] = 73.5
,
    ["Noob Cub Skin"] = 58.5
,
    ["Nessie"] = 57.5
,
    ["Icy Crowned Hive Skin"] = 49.5
,
    ["Gingerbread Cub Skin"] = 46.5
,
    ["Petal Cub Skin"] = 42
,
    ["Doodle Cub Skin"] = 29
,
    ["Offline Voucher"] = 27
,
    ["Wavy Purple Hive Skin"] = 27
,
    ["Brown Cub Skin"] = 23.5
,
    ["Ionic Column Top"] = 21
,
    ["Ionic Column Base"] = 21
,
    ["Stranded Sun Bear"] = 16.5
,
    ["Stick Cub Skin"] = 15.5
,
    ["Glowering Gummy Bear"] = 13.5
,
    ["Royal Symbol"] = 11.5
,
    ["Bear Bee Voucher"] = 10
,
    ["Cyan Hilted Sword"] = 9.75
,
    ["Star Cub Skin"] = 9.75
,
    ["Robo Cub Skin"] = 9.25
,
    ["Round Basic Bee"] = 7.75
,
    ["Cub Buddy Voucher"] = 7.38
,
    ["Ionic Column Middle"] = 5.5
,
    ["Abstract Color Painting"] = 3.75
,
    ["Bear Bee Offer"] = 2.75
,
    ["Pine Tree Forest Stamp"] = 2.75
,
    ["Pepper Patch Stamp"] = 2.75
,
    ["Wall Crack"] = 2.5
,
    ["Tabby From Behind"] = 2.25
,
    ["Wavy Cyan Hive Skin"] = 2.25
,
    ["Right Gold Swirl Fleuron"] = 1.75
,
    ["Left Gold Swirl Fleuron"] = 1.75
,
    ["Eviction"] = 1.75
,
    ["Sitting Mother Bear"] = 1.75
,
    ["Right Shining Diamond Fleuron"] = 1.75
,
    ["Left Mythic Gem Fleuron"] = 1.75
,
    ["Left Shining Diamond Fleuron"] = 1.75
,
    ["Right Mythic Gem Fleuron"] = 1.75
,
    ["Auryn"] = 1.5
,
    ["Virgo Star Sign"] = 1
,
    ["Taurus Star Sign"] = 1
,
    ["Scorpio Star Sign"] = 1
,
    ["Sagittarius Star Sign"] = 1
,
    ["Pisces Star Sign"] = 1
,
    ["Libra Star Sign"] = 1
,
    ["Leo Star Sign"] = 1
,
    ["Gemini Star Sign"] = 1
,
    ["Capricorn Star Sign"] = 1
,
    ["Cancer Star Sign"] = 1
,
    ["Aries Star Sign"] = 1
,
    ["Aquarius Star Sign"] = 1
,
    ["Ticket Voucher"] = 1
,
    ["Tornado"] = 0.88
,
    ["Prismatic Mushroom"] = 0.88
,
    ["Flying Festive Bee"] = 0.88
,
    ["Party Robo Bear"] = 0.88
,
    ["Pearl Girl"] = 0.75
,
    ["Shy Brown Bear"] = 0.63
,
    ["Rose Field Stamp"] = 0.63
,
    ["Spider Field Stamp"] = 0.63
,
    ["Wobbly Looker Bee"] = 0.58
,
    ["Drooping Stubborn Bee"] = 0.58
,
    ["Dapper From Above"] = 0.58
,
    ["Glowing Smile"] = 0.41
,
    ["Small Blue Chick"] = 0.41
,
    ["Flying Photon Bee"] = 0.41
,
    ["Festive Pea"] = 0.41
,
    ["Stump Field Stamp"] = 0.41
,
    ["Strawberry Field Stamp"] = 0.41
,
    ["Pumpkin Patch Stamp"] = 0.41
,
    ["Pineapple Patch Stamp"] = 0.41
,
    ["Mushroom Field Stamp"] = 0.41
,
    ["Mountain Top Field Stamp"] = 0.41
,
    ["Sunflower Field Stamp"] = 0.41
,
    ["Clover Field Stamp"] = 0.41
,
    ["Cactus Field Stamp"] = 0.41
,
    ["Blue Flower Field Stamp"] = 0.41
,
    ["Bamboo Field Stamp"] = 0.41
,
    ["Dandelion Field Stamp"] = 0.41
,
    ["Coconut Field Stamp"] = 0.41
,
    ["Black Diamond"] = 0.36
,
    ["Black Star"] = 0.36
,
    ["Dark Flame"] = 0.36
,
    ["Hourglass"] = 0.29
,
    ["Cool Backpack"] = 0.29
,
    ["Jack-O-Lantern"] = 0.29
,
    ["Precise Eye"] = 0.29
,
    ["Taunting Doodle Person"] = 0.29
,
    ["Yellow Sticky Hand"] = 0.29
,
    ["4-Pronged Vector Bee"] = 0.29
,
    ["Purple 4-Point Flower"] = 0.29
,
    ["Prism Painting"] = 0.29
,
    ["Banana Painting"] = 0.29
,
    ["Gummyballer"] = 0.29
,
    ["Hub Field Stamp"] = 0.29
,
    ["Robot Head"] = 0.29
,
    ["Satisfying Nectar Icon"] = 0.29
,
    ["Motivating Nectar Icon"] = 0.29
,
    ["Refreshing Nectar Icon"] = 0.29
,
    ["Invigorating Nectar Icon"] = 0.29
,
    ["Comforting Nectar Icon"] = 0.29
,
    ["Wavy Festive Hive Skin"] = 0.29
,
    ["Clippers"] = 0.23
,
    ["Scooper"] = 0.23
,
    ["Palm Tree"] = 0.23
,
    ["Magnet"] = 0.23
,
    ["Shocked Hive Slot"] = 0.23
,
    ["Prehistoric Hand"] = 0.23
,
    ["Festive Pufferfish"] = 0.23
,
    ["Diamond Diamond Bee"] = 0.23
,
    ["Shining Star"] = 0.23
,
    ["Cyan Star"] = 0.23
,
    ["Vacuum"] = 0.23
,
    ["Super-Scooper"] = 0.23
,
    ["Spark Staff"] = 0.23
,
    ["Scythe"] = 0.23
,
    ["Scissors"] = 0.23
,
    ["Rake"] = 0.23
,
    ["Pulsar"] = 0.23
,
    ["Electro-Magnet"] = 0.23
,
    ["Ant Field Stamp"] = 0.23
,
    ["Sideways Spirit Bear"] = 0.2
,
    ["Walking Stick Nymph"] = 0.17
,
    ["Tabby Scratch"] = 0.17
,
    ["Standing Bean Bug"] = 0.17
,
    ["Round Green Critter"] = 0.17
,
    ["Purple Fleuron"] = 0.17
,
    ["Flying Rad Bee"] = 0.17
,
    ["Flying Ninja Bee"] = 0.17
,
    ["Flying Brave Bee"] = 0.17
,
    ["Blue Triangle Critter"] = 0.17
,
    ["Purple Pointed Critter"] = 0.17
,
    ["Orange Leg Critter"] = 0.17
,
    ["Shining Halo"] = 0.17
,
    ["Royal Bear"] = 0.17
,
    ["Orange Green Tri Deco"] = 0.17
,
    ["Mythic M"] = 0.17
,
    ["Shiitake Mushroom"] = 0.17
,
    ["Oiler Mushroom"] = 0.17
,
    ["Morel Mushroom"] = 0.17
,
    ["Chanterelle Mushroom"] = 0.17
,
    ["Honey Dipper"] = 0.17
,
    ["Blob Bumble Bee"] = 0.13
,
    ["Blue Beesmas Light"] = 0.13
,
    ["Green Beesmas Light"] = 0.13
,
    ["Red Beesmas Light"] = 0.13
,
    ["Yellow Beesmas Light"] = 0.13
,
    ["Prehistoric Boar"] = 0.13
,
    ["Orange Step Array"] = 0.13
,
    ["Black Truffle Mushroom"] = 0.13
,
    ["Golden Rake"] = 0.13
,
    ["Round Rascal Bee"] = 0.13
,
    ["Yellow Left Arrow"] = 0.07
,
    ["Waxing Crescent Moon"] = 0.07
,
    ["Tiny House"] = 0.07
,
    ["Small Shield"] = 0.07
,
    ["Saturn"] = 0.07
,
    ["Right Facing Stump Snail"] = 0.07
,
    ["Moai"] = 0.07
,
    ["Little Scorpion"] = 0.07
,
    ["Lightning"] = 0.07
,
    ["Forward Facing Spider"] = 0.07
,
    ["Flying Magenta Critter"] = 0.07
,
    ["Bomber Bee Bear"] = 0.07
,
    ["AFK"] = 0.07
,
    ["Squashed Head Bear"] = 0.07
,
    ["Wishbone"] = 0.07
,
    ["Stretched Head Bear"] = 0.07
,
    ["Cyan Decorative Border"] = 0.07
,
    ["Grey Raining Cloud"] = 0.07
,
    ["Porcini Mushroom"] = 0.07
,
    ["Fly Agaric Mushroom"] = 0.07
,
    ["Bubble Wand"] = 0.07
,
    ["Critter In A Stocking"] = 0.07
,
    ["Left Facing Ant"] = 0.07
,
    ["TNT"] = 0.06
,
    ["Standing Beekeeper"] = 0.06
,
    ["Fuzz Bomb"] = 0.06
,
    ["Shrugging Heart"] = 0.06
,
    ["Red Wailing Cry"] = 0.06
,
    ["Yellow Right Arrow"] = 0.04
,
    ["Window"] = 0.04
,
    ["Uplooking Bear"] = 0.04
,
    ["Thumbs Up Hand"] = 0.04
,
    ["Tadpole"] = 0.04
,
    ["Small Flame"] = 0.04
,
    ["Sitting Green Shirt Bear"] = 0.04
,
    ["Silly Tongue"] = 0.04
,
    ["Pink Cupcake"] = 0.04
,
    ["Peace Sign Hand"] = 0.04
,
    ["Panicked Science Bear"] = 0.04
,
    ["Pale Heart"] = 0.04
,
    ["Menacing Mantis"] = 0.04
,
    ["Honey Bee Bear"] = 0.04
,
    ["Fork And Knife"] = 0.04
,
    ["Eighth Note"] = 0.04
,
    ["Chef Hat Polar Bear"] = 0.04
,
    ["Barcode"] = 0.04
,
    ["Small White Daisy"] = 0.04
,
    ["Small Pink Tulip"] = 0.04
,
    ["Small Dandelion"] = 0.04
,
    ["Forward Facing Aphid"] = 0.04
,
    ["Doodle S"] = 0.04
,
    ["Grey Diamond Logo"] = 0.04
,
    ["Red Palm Hand"] = 0.04
,
    ["Theatrical Intruder"] = 0.04
,
    ["Triple Exclamation"] = 0.04
,
    ["Simple Mountain"] = 0.04
,
    ["Porcelain Dipper"] = 0.04
,
    ["White Flag"] = 0.04
,
    ["Standing Caterpillar"] = 0.04
,
    ["Pink Chair"] = 0.04
,
    ["White Button Mushroom"] = 0.04
,
    ["Tide Popper"] = 0.04
,
    ["Dark Scythe"] = 0.04
,
    ["Small Tickseed"] = 0.04
,
    ["Happy Fish"] = 0.04
,
    ["Coiled Snake"] = 0.04
,
    ["Diamond Cluster"] = 0.03
,
    ["Blue And Green Marble"] = 0.03
,
    ["Orange Swirled Marble"] = 0.03
,
    ["Waving Townsperson"] = 0.03
,
    ["Yellow Swirled Marble"] = 0.03
,
    ["Red Doodle Person"] = 0.03
,
    ["Diamond Trim"] = 0.03
,
    ["Traffic Light"] = 0.01
,
    ["Spore Covered Puffshroom"] = 0.01
,
    ["Pyramid"] = 0.01
,
    ["Launching Rocket"] = 0.01
,
    ["Green Plus Sign"] = 0.01
,
    ["Green Check Mark"] = 0.01
,
    ["Flying Bee Bear"] = 0.01
,
    ["Colorful Buttons"] = 0.01
,
    ["Blowing Leaf"] = 0.01
,
    ["Baseball Swing"] = 0.01
,
    ["Yellow Hi"] = 0.01
,
    ["Red X"] = 0.01
,
    ["Green SELL"] = 0.01
,
    ["Atom Symbol"] = 0.01
,
    ["Killroy With Hair"] = 0.01
,
    ["Alert Icon"] = 0.01
,
    ["Desperate Booth"] = 0.01
,
    ["Evil Pig"] = 0.01
,
    ["Yellow Coffee Mug"] = 0.01
,
    ["Grey Shape Companion"] = 0.01
,
    ["Interrobang Block"] = 0.01
,
    ["Orphan Dog"] = 0.01
,
    ["Pizza Delivery Man"] = 0.01
,
    ["Sprout"] = 0.01
,
    ["Tough Potato"] = 0.01
,
    ["Young Elf"] = 0.01
,
    ["Simple Skyscraper"] = 0.01
,
    ["Giraffe"] = 0.01
,
    ["Cop And Robber"] = 0.01
,
    ["Classic Killroy"] = 0.01
,
    ["Simple Sun"] = 0.01
,
    ["Rubber Duck"] = 0.01
,
    ["Rhubarb"] = 0.01
,
    ["Green Circle"] = 0.01
,
    ["Blue Square"] = 0.01
,
    ["Yellow Umbrella"] = 0.01
,
    ["Simple Cloud"] = 0.01
,
    ["Built Ship"] = 0.01
,
    ["Spatulate Leaf"] = 0.01
,
    ["Rhomboid Leaf"] = 0.01
,
    ["Reniform Leaf"] = 0.01
,
    ["Oblique Leaf"] = 0.01
,
    ["Lyrate Leaf"] = 0.01
,
    ["Lanceolate Leaf"] = 0.01
,
    ["Hastate Leaf"] = 0.01
,
    ["Elliptic Leaf"] = 0.01
,
    ["Cordate Leaf"] = 0.01
,
    ["Cunate Leaf"] = 0.01
,
    ["Petal Wand"] = 0.01
,
    ["BBM From Below"] = 0
,
    ["Camphor Lip Balm"] = 350
,
    ["Pink Shades"] = 330
,
    ["Whistle"] = 170
,
    ["Pinecone"] = 167.5
,
    ["Snow Tiara"] = 160
,
    ["Smiley Sticker"] = 155
,
    ["Paper Angel"] = 150
,
    ["Poinsettia"] = 127.5
,
    ["Kazoo"] = 125
,
    ["Reindeer Antlers"] = 107.5
,
    ["Candy Ring"] = 105
,
    ["Elf Cap"] = 100
,
    ["Festive Wreath"] = 100
,
    ["Paperclip"] = 90
,
    ["Sweatband"] = 87.5
,
    ["Rose Headband"] = 82.5
,
    ["Toy Drum"] = 82.5
,
    ["Charm Bracelet"] = 77.5
,
    ["Peppermint Antennas"] = 67.5
,
    ["Bead Lizard"] = 40
,
    ["Beret"] = 40
,
    ["Beesmas Tree Hat"] = 29
,
    ["Thumbtack"] = 12.5
,
    ["Beesmas Top"] = 12
,
    ["Autumn Sunhat"] = 11
,
    ["Single Mitten"] = 9
,
    ["Thimble"] = 7.5
,
    ["Bandage"] = 5.025
,
    ["Bang Snap"] = 4
,
    ["Lump Of Coal"] = 1.6
,
    ["Bottle Cap"] = 1.5
,
    ["Bubble Light"] = 1.5
,
    ["Camo Bandana"] = 1.5
,
    ["Icicles"] = 1.5
,
    ["Demon Talisman"] = 1
,
    ["Lei"] = 1
,
    ["Snowglobe"] = 0.415
,
    ["Warm Scarf"] = 0.25
,
    ["Pink Eraser"] = 0.0125
,
    ["Electric Candle"] = 0
,
}

-- Supplemental means for the few cosmetics that neither PRICES nor the generated
-- sticker module carry yet. Game name -> site mapping:
--   "Basic X Hive Skin" -> "X Hive Skin", "Wavy Yellow" -> "Wavy Gold",
--   "Wavy Doodle" -> "Doodle Hive Skin", "x2 Y Voucher" -> "Y Voucher".
-- Still unknown everywhere (shown as "?", 8 of them): Basic Hive Skin,
-- Black Cub Skin, Gamer Chat Icon, Play Button, Seeker, Test * stickers.
local SITE_PRICES = {
    ["Basic Black Hive Skin"] = 0.125,
    ["Basic White Hive Skin"] = 0.125,
    ["Basic Blue Hive Skin"] = 0.075,
    ["Basic Green Hive Skin"] = 0.075,
    ["Basic Pink Hive Skin"] = 0.075,
    ["Basic Red Hive Skin"] = 0.075,
    ["Wavy Doodle Hive Skin"] = 10.5,
    ["Wavy Yellow Hive Skin"] = 0.825,
    ["x2 Bee Gather Voucher"] = 6.625,
    ["x2 Convert Speed Voucher"] = 4.125,
    ["Yellow Walking Wiggly Person"] = 0.0125,
}

-- ===== data modules =====================================================
-- Two generated modules sit in Real's workspace folder (the loadfile root):
--   bss_index_values.luau   - OUR OWN beequip roll prices (snapshot of the
--                              site's beequips_prices.json). Beequips use this
--                              and only this.
--   bss_index_stickers.luau - OUR OWN sticker/cub/voucher prices (snapshot of
--                              the site's prices.tsv), source "bss-index".
-- Each is loaded lazily: a getgenv() injection first, then loadfile. A module
-- that is missing is retried every 10s instead of being cached as absent.
-- Sticker chain: PRICES -> SITE_PRICES -> bss_index_stickers -> "?".

-- mirrors normName below: lowercase, strip everything non-alphanumeric
local function dataKey(s)
    return (string.lower(tostring(s)):gsub("[^%w]", ""))
end

local function buildNameIdx(tbl)
    local idx = {}
    for k in pairs(tbl) do
        if string.sub(k, 1, 1) ~= "_" then
            local kk = dataKey(k)
            if idx[kk] == nil then idx[kk] = k end
        end
    end
    return idx
end

-- load a generated module by its getgenv token, then by file name
local function loadModule(token, file, field)
    local mod
    local okg, injected = pcall(function() return getgenv()[token] end)
    if okg and type(injected) == "table" then
        mod = injected
    else
        local okf, fn = pcall(function() return loadfile(file) end)
        if okf and type(fn) == "function" then
            local okr, m = pcall(fn)
            if okr then mod = m end
        end
    end
    if type(mod) ~= "table" or type(mod[field]) ~= "table" then return nil end
    return mod
end

-- name -> entry: exact match, known rename (nameMap), then normalized key
local function resolveName(tbl, idx, name, map)
    local hit = tbl[name]
    if hit ~= nil then return hit end
    if type(map) == "table" then
        local mapped = map[name]
        if mapped and tbl[mapped] ~= nil then return tbl[mapped] end
    end
    if idx then
        local k = idx[dataKey(name)]
        if k ~= nil and tbl[k] ~= nil then return tbl[k] end
    end
    return nil
end

-- ---- stickers: our own site snapshot (bss_index_stickers.luau) ----
local stickerMod, stickerAt, stickerIdx = nil, -1e9, nil

local function getStickerModule()
    if stickerMod then return stickerMod end
    if os.clock() - stickerAt < 10 then return nil end
    stickerAt = os.clock()
    local mod = loadModule("BSS_INDEX_STICKERS_DATA", "bss_index_stickers.luau", "stickers")
    if not mod then return nil end
    stickerMod = mod
    stickerIdx = buildNameIdx(mod.stickers)
    local n = 0
    for _ in pairs(mod.stickers) do n = n + 1 end
    print(("[TradeValueOverlay] own sticker data: %d (gen %s)"):format(n, tostring(mod.generated)))
    return stickerMod
end

-- siteStickerPrice: own-site sticker price, or nil. Entry shape is
-- {price=<Val>, source="bss-index"}; a bare number is tolerated for hand edits.
local function siteStickerPrice(name)
    local mod = getStickerModule()
    if not mod then return nil end
    local e = resolveName(mod.stickers, stickerIdx, name, mod.nameMap)
    if type(e) == "number" then return e end
    if type(e) == "table" and type(e.price) == "number" then return e.price end
    return nil
end

-- full sticker price chain: embedded table -> supplemental means -> own module
local function stickerPrice(name)
    return PRICES[name] or SITE_PRICES[name] or siteStickerPrice(name)
end

-- ---- beequips: our own site data ----
local bqMod, bqAt, bqRev, bqIdx = nil, -1e9, 0, nil
local siteBq = nil -- only filled when INDEX_API_URL is set (see below)

-- Optional endpoint of our own site, to be filled in once it serves the same
-- {beequips = {...}} JSON. nil today: the site exposes no public API (checked
-- 17.10.2026), so the local snapshot below is the only source and no request is
-- made at all.
local INDEX_API_URL = nil

local function getBqModule()
    if bqMod then return bqMod end
    if os.clock() - bqAt < 10 then return nil end
    bqAt = os.clock()
    local mod = loadModule("BSS_INDEX_VALUES_DATA", "bss_index_values.luau", "beequips")
    if not mod then return nil end
    bqMod = mod
    bqRev = bqRev + 1
    bqIdx = buildNameIdx(mod.beequips)
    local c = mod.generated_counts or {}
    print(("[TradeValueOverlay] own beequip data: %s beequips, %s groups, %s variants (gen %s)"):format(
        tostring(c.beequips), tostring(c.groups), tostring(c.variants), tostring(mod.generated)))
    return bqMod
end

-- beequip table + whether it came from the optional live endpoint
local function bqEntry(name)
    getBqModule()
    if siteBq then
        local e = resolveName(siteBq, nil, name, nil)
        if type(e) == "table" and type(e.stat_groups) == "table" then return e, true end
    end
    if not bqMod then return nil, false end
    local e = resolveName(bqMod.beequips, bqIdx, name, nil)
    if type(e) == "table" and type(e.stat_groups) == "table" then return e, false end
    return nil, false
end

-- image -> item (name + flat price); beequips are priced by roll, see beequipPriceFor
local imageInfo = {}
local priced, unpriced = 0, 0
for name, data in pairs(StickerTypes.Types) do
    if data.Image then
        local p = stickerPrice(name)
        imageInfo[data.Image] = { name = name, price = p, isBeequip = false }
        if p then priced = priced + 1 else unpriced = unpriced + 1 end
    end
end
for name, data in pairs(BeequipTypes.Types) do
    if data.Icon then
        -- No flat price for beequips: an item is priced per roll in
        -- beequipPriceFor, its index value would be a wrong number (Pinecone is
        -- worth 167.5 as an item but ~1 in this roll).
        imageInfo[data.Icon] = { name = name, price = nil, isBeequip = true }
        unpriced = unpriced + 1
    end
end

local MY_COLOR = Color3.fromRGB(255, 220, 80)
local THEIR_COLOR = Color3.fromRGB(120, 210, 255)
local OK_COLOR = Color3.fromRGB(90, 230, 120)
local BAD_COLOR = Color3.fromRGB(255, 95, 95)
local NEUTRAL_COLOR = Color3.fromRGB(200, 200, 200)
local BG = Color3.fromRGB(12, 12, 18)
local PANEL_BG = Color3.fromRGB(19, 19, 27)
local PANEL_STROKE = Color3.fromRGB(58, 60, 78)
local MUTED = Color3.fromRGB(138, 140, 156)
local ACCENT = Color3.fromRGB(255, 206, 84)

-- ===== settings =========================================================
-- Persisted in getgenv().BSS_INDEX_SETTINGS. Missing keys fall back to their
-- default, so a table left over from an older run keeps working. The gear next
-- to the brand label opens the panel that edits these.
local SETTING_DEFAULTS = {
    autoconvert = true, -- icon strip with the diff split into fixed-price items
    iconLimit = 6,      -- how many icons the strip may draw
    showApprox = true,  -- "~" prefix on nearest-variant beequip guesses
    showMeta = false,   -- demand / stability from bss_index_values.meta
    showBrand = true,   -- "BSS Index Tools" corner label + gear button
    compact = false,    -- smaller paddings and fonts everywhere
}
local SETTINGS = (function()
    local e = getgenv()
    local s = e.BSS_INDEX_SETTINGS
    if type(s) ~= "table" then s = {} end
    for k, v in pairs(SETTING_DEFAULTS) do
        if s[k] == nil then s[k] = v end
    end
    e.BSS_INDEX_SETTINGS = s
    return s
end)()

local function setSetting(key, value)
    if SETTING_DEFAULTS[key] == nil then return false end
    SETTINGS[key] = value
    return true
end

-- Forward declarations: the panel widgets call each other (switch -> syncPanel,
-- dimmer/gear -> togglePanel, strip -> getPanelGui) and the gear button needs the
-- liveness check that the single-instance guard binds at the very end.
local syncPanel, togglePanel, getPanelGui, getPanelHost
local alive

-- ===== auto-convert: split a Val sum into item icons ====================
-- Only items with a FIXED index price go into the pool: cub skins and vouchers.
-- Beequips are excluded on purpose - their price depends on the roll, so a split
-- by item value would be a confident lie.
-- Ticket Voucher (1 Val) is excluded on purpose too: it is worthless change and
-- it fills the split with junk that nobody wants to receive. What is left over
-- stays visible as "+N Val" instead of being hidden in a pile of vouchers.
local CVT_POOL_SRC = {
    { n = "Bee Cub Skin", p = 290 },
    { n = "Snow Cub Skin", p = 175 },
    { n = "Peppermint Robo Cub Skin", p = 165 },
    { n = "Gloomy Cub Skin", p = 73.5 },
    { n = "Noob Cub Skin", p = 58.5 },
    { n = "Gingerbread Cub Skin", p = 46.5 },
    { n = "Petal Cub Skin", p = 42 },
    { n = "Doodle Cub Skin", p = 29 },
    { n = "Offline Voucher", p = 27 },
    { n = "Brown Cub Skin", p = 23.5 },
    { n = "Stick Cub Skin", p = 15.5 },
    { n = "Bear Bee Voucher", p = 10 },
    { n = "Star Cub Skin", p = 9.75 },
    { n = "Robo Cub Skin", p = 9.25 },
    { n = "Cub Buddy Voucher", p = 7.38 },
}
local CVT_POOL = {}
for _, e in ipairs(CVT_POOL_SRC) do
    local d = StickerTypes.Types[e.n]
    if d and d.Image then -- no icon -> cannot be drawn -> out of the pool
        CVT_POOL[#CVT_POOL + 1] = { name = e.n, price = stickerPrice(e.n) or e.p, image = d.Image }
    end
end
table.sort(CVT_POOL, function(a, b)
    if a.price ~= b.price then return a.price > b.price end
    return a.name < b.name
end)

local CVT_EPS = 0.0005

-- Greedy split: walk the pool from the priciest item down and take
-- floor(rest / price) of each, capped by the icon budget. Whatever does not fit
-- stays as a "+N Val" remainder. 300 Val -> 1 Bee Cub + 1 Bear Bee Voucher.
local function autoconvert(val, limit)
    local parts, rest = {}, val
    local slots = math.floor(limit or SETTING_DEFAULTS.iconLimit)
    if slots < 1 then slots = 1 end
    for _, it in ipairs(CVT_POOL) do
        if slots <= 0 then break end
        if rest >= it.price - CVT_EPS then
            local take = math.floor(rest / it.price + 1e-6)
            if take > slots then take = slots end
            if take > 0 then
                parts[#parts + 1] = {
                    name = it.name, count = take, image = it.image, price = it.price,
                }
                slots = slots - take
                rest = rest - take * it.price
            end
        end
    end
    if rest < CVT_EPS then rest = 0 end
    return parts, rest
end

local function fmtVal(v)
    local s = string.format("%.2f", math.abs(v))
    s = string.gsub(s, "%.?0+$", "")
    if s == "" then s = "0" end
    return s
end

-- one-line text form of a split; used by the verification hook
local function autoconvertText(val, limit)
    local parts, rest = autoconvert(val, limit)
    local out = {}
    for i, p in ipairs(parts) do
        out[#out + 1] = ((i > 1 and " + " or "") .. "+" .. p.count .. " " .. p.name)
    end
    if rest > 0 then
        out[#out + 1] = ((#out > 0 and " + " or "") .. "+" .. fmtVal(rest) .. " Val")
    end
    return table.concat(out)
end

local function getTradeFrame()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local f = pg:FindFirstChild("TradeFrame", true)
    if f and f:IsA("GuiObject") then return f end
    return nil
end

-- ===== text metrics ======================================================
-- Every backing plate must be at least as wide as the text it carries, with the
-- same padding on both sides. TextService is the only honest way to know that
-- width ("+21.12 Val" and "EVEN" need very different plates), but measuring is
-- not free and the refresh loop runs 3x/second, so results are cached by
-- text + size + font and only re-measured when one of those changes.
local TEXT_W = {}
local TEXT_W_MAX = 512
local MEASURE_W = 10000 -- wide enough that nothing ever wraps while measuring

local function textWidth(text, size, font)
    text = tostring(text or "")
    local key = size .. "\1" .. tostring(font) .. "\1" .. text
    local cached = TEXT_W[key]
    if cached then return cached end
    local w
    -- NOTE: type(Vector2) is "userdata" on this client, so the result must never
    -- be branched on by type - read .X inside pcall and validate the number
    local ok, x = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(MEASURE_W, 0)).X
    end)
    if ok and type(x) == "number" and x > 0 then
        w = x
    else
        -- TextService unavailable or refused the font: rough estimate, still
        -- better than a fixed width
        w = #text * size * 0.58
    end
    local n = TEXT_W.count or 0
    if n >= TEXT_W_MAX then -- keep the cache bounded
        TEXT_W = {}
        n = 0
    end
    TEXT_W[key] = w
    TEXT_W.count = n + 1
    return w
end

-- Plate width that hugs the text: equal padding on both sides, never below minW.
local function plateWidth(text, size, font, pad, minW)
    return math.max(minW or 0, math.ceil(textWidth(text, size, font)) + (pad or 0) * 2)
end

-- Largest font size <= size at which the text still fits avail px. Used where the
-- plate is fixed by the layout (item tiles), so shrinking is the only way out.
local function fitFontSize(text, size, font, avail, floor)
    floor = floor or 8
    local w = textWidth(text, size, font)
    if w <= avail then return size, w end
    local s = size
    while s > floor do
        s = s - 1
        w = textWidth(text, s, font)
        if w <= avail then return s, w end
    end
    return floor, w
end

-- stack multiplier "xN" shown on the tile
local function tileMult(imgLabel)
    for _, child in ipairs(imgLabel:GetChildren()) do
        if child:IsA("TextLabel") then
            local n = string.match(child.Text or "", "^x(%d+)$")
            if n then
                return tonumber(n) or 1
            end
        end
    end
    return 1
end

-- ================= beequip roll pricing (own site data) =================
-- Data: bss_index_values.luau, our own site's beequips_prices.json snapshot.
-- entry.stat_groups[g][variantKey] = {value_min, value_max, demand}.
-- A variant key like "24 Red Gather Amount + {HB} 1 Red Pollen" is parsed into
-- numeric conditions and compared with the item's stat signature (built from the
-- BeeStatMods/StatModifiers descriptions). Our site stores one price per roll,
-- so value_min == value_max, and a roll with an unknown price carries no value
-- fields at all (it must never resolve to 0).
-- Groups named "Full Waxed" get priority when the item has all 5 wax attempts on
-- record, "Unwaxed" groups when it has fewer.
-- Scoring: smallest stat distance first, then wax-state relevance, then the
-- variant with more conditions actually backed by the item's stats, then the
-- cheaper price so an ambiguous match never inflates the overlay.
-- No flat price fallback anywhere: "?" beats a confident wrong number.

local LEQ, GEQ, STAR = "\226\137\164", "\226\137\165", "\226\152\133" -- <= >= star (utf-8 bytes)

local function dbg(...)
    local ok, f = pcall(function()
        local e = getgenv()
        return e.BSS_INDEX_DEBUG or e.BSSM_DEBUG
    end)
    if ok and f then print("[BQDBG]", ...) end
end

-- Optional fresh beequip data from our own site. Dead while INDEX_API_URL is
-- nil, which is the only reason this file ever talks to a network at all.
local siteFetchAt = -1e9

local function tryFetchSiteData(force)
    if not INDEX_API_URL or siteBq then return end
    local now = os.clock()
    if not force and now - siteFetchAt < 300 then return end
    siteFetchAt = now
    local ok, res = pcall(function() return request({ Url = INDEX_API_URL, Method = "GET" }) end)
    if not ok or type(res) ~= "table" or type(res.Body) ~= "string" then
        warn("[TradeValueOverlay] own site fetch failed")
        return
    end
    local ok2, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(res.Body)
    end)
    if ok2 and type(decoded) == "table" and type(decoded.beequips) == "table" then
        siteBq = decoded.beequips
        bqRev = bqRev + 1
        local n = 0
        for _ in pairs(siteBq) do n = n + 1 end
        print(("[TradeValueOverlay] own site beequip data: %d beequips"):format(n))
    end
end

-- site stat abbreviations -> full game stat names (word-initials matching
-- covers most of the rest, e.g. "Bfc" -> "Blue Field Capacity")
-- Only abbreviations whose in-game stat name was actually observed. Adding a guess
-- here is dangerous: sigLookup falls back from hb to mod, so a wrong alias can make
-- an hb-conditioned variant match a plain mod stat and invent a price (bap ->
-- "ability pollen" priced a Toy Horn at 225 Val). When unsure, leave it out.
local STAT_ALIASES = {
    -- ability / crit
    ar = "ability rate",
    bar = "ability rate",
    atl = "ability token lifespan",
    atta = "attack",
    crit = "critical power",
    ctp = "critical power",
    scp = "super-crit power",
    scc = "super-crit chance",
    bap = "bee ability pollen",
    bms = "bee movespeed",
    mark = "mark duration",
    md = "mark duration",
    -- convert
    conv = "convert rate",
    crah = "convert at hive",
    hft = "honey from tokens",
    -- honey
    hah = "honey at hive",
    hpg = "honey per goo",
    -- field capacity (note: bfc/wfc/gbc are the ones that unblock Beret / Snow Tiara /
    -- Autumn Sunhat, which used to fall through to "?" entirely)
    cap = "capacity",
    capa = "capacity",
    bfc = "blue field capacity",
    wfc = "white field capacity",
    gbc = "green field capacity",
    rfc = "red field capacity",
    ptc = "pine tree forest capacity",
    -- pollen
    ppp = "pine tree forest pollen",
    ptp = "pine tree forest pollen",
    pp = "pine tree forest pollen",
    peopp = "peppermint pollen",
    pepp = "pumpkin patch pollen",
    bubb = "bubble pollen",
    fp = "flame pollen",
    bp = "bomb pollen",
    bbp = "blue bomb pollen",
    whit = "white pollen",
    rp = "red pollen",
    dgf = "dandelion field pollen",
    mfp = "mushroom field pollen",
    rfp = "rose field pollen",
    sfp = "sunflower field pollen",
}

-- The site writes a colour on some field stats ("30 Red Gather Amount") while the
-- in-game description sometimes omits it ("+25 Gather Amount"). Fall back to the
-- colour-free name rather than never matching at all.
local FIELD_COLORS = {
    red = true, blue = true, white = true, pink = true, black = true,
    green = true, yellow = true, cyan = true, purple = true, orange = true,
}

local function normName(s)
    return (string.lower(tostring(s)):gsub("[^%w]", ""))
end

local function initials(s)
    local out = {}
    for w in string.gmatch(string.lower(tostring(s)), "[%w]+") do
        out[#out + 1] = string.sub(w, 1, 1)
    end
    return table.concat(out)
end

-- "+24% Red Gather Amount (19+5)" / "+25,000 Capacity" / "x1.05 Pepper Patch
-- Pollen (1.03+0.02)" -> {name=..., value=24}
local function parseStatDesc(desc)
    if type(desc) ~= "string" then return nil end
    local value, rest
    local xn, xr = string.match(desc, "^[xX]%s*([%d][%d%,%.]*)%s*(.*)$")
    if xn then
        value = tonumber((xn:gsub(",", "")))
        rest = xr
    else
        local nn, nr = string.match(desc, "^%s*([%+%-][%d][%d%,%.]*)%s*(.*)$")
        if not nn then
            nn, nr = string.match(desc, "^%s*([%d][%d%,%.]*)%s*(.*)$")
        end
        if not nn then return nil end
        value = tonumber((nn:gsub(",", "")))
        rest = nr
    end
    if not value then return nil end
    rest = string.gsub(rest, "^%%%s*", "")
    rest = string.gsub(rest, "%s*%b()$", "")
    rest = string.gsub(rest, "^%s+", "")
    rest = string.gsub(rest, "%s+$", "")
    if rest == "" then return nil end
    return { name = rest, value = value }
end

local function addStat(mapNorm, mapInit, parsed, isHb)
    local norm = normName(parsed.name)
    if mapNorm[norm] == nil then
        mapNorm[norm] = { value = parsed.value, hb = isHb }
    end
    local init = initials(parsed.name)
    if #init > 1 and mapInit[init] == nil then
        mapInit[init] = { value = parsed.value, hb = isHb }
    end
end

local function buildSignature(obj, stars)
    local sig = { modNorm = {}, modInit = {}, hbNorm = {}, hbInit = {}, stars = stars }
    local ok, mods, hb = pcall(function() return obj:GenerateModifiers() end)
    if not ok then return nil end
    if type(mods) == "table" then
        for _, m in ipairs(mods) do
            local okd, desc = pcall(function() return BeeStatMods.GetType(m.Stat).Desc(m) end)
            if okd then
                local parsed = parseStatDesc(desc)
                if parsed then addStat(sig.modNorm, sig.modInit, parsed, false) end
            end
        end
    end
    if type(hb) == "table" then
        for _, h in ipairs(hb) do
            local okd, desc = pcall(function() return StatModifiers.Description(h) end)
            if okd then
                local parsed = parseStatDesc(desc)
                if parsed then addStat(sig.hbNorm, sig.hbInit, parsed, true) end
            end
        end
    end
    return sig
end

-- find an item stat by a site stat name: exact normalized name, alias, word initials
local function sigLookup(sig, siteName, wantHb)
    local norm = normName(siteName)
    local alias = STAT_ALIASES[norm]
    local aliasNorm = alias and normName(alias) or nil
    local init = initials(siteName)
    local firstNorm, secondNorm, firstInit, secondInit
    if wantHb then
        firstNorm, secondNorm = sig.hbNorm, sig.modNorm
        firstInit, secondInit = sig.hbInit, sig.modInit
    else
        firstNorm, secondNorm = sig.modNorm, sig.hbNorm
        firstInit, secondInit = sig.modInit, sig.hbInit
    end
    local hit = firstNorm[norm] or (aliasNorm and firstNorm[aliasNorm])
    if hit then return hit end
    hit = secondNorm[norm] or (aliasNorm and secondNorm[aliasNorm])
    if hit then return hit end
    -- word initials only help for multi-word site names ("Red Gather Amount" -> "rga")
    if init and #init > 1 then
        hit = firstInit[init]
        if hit then return hit end
        hit = secondInit[init]
        if hit then return hit end
    end
    -- site keys are often single-token abbreviations ("Scp", "Scc"): match them via
    -- the alias' own initials ("super-crit power" -> "scp")
    if alias then
        local ai = initials(alias)
        if #ai > 1 then
            hit = firstInit[ai] or secondInit[ai]
            if hit then return hit end
        end
    end
    -- last resort: drop a leading colour word ("Red Gather Amount" -> "Gather Amount")
    local firstWord = string.match(string.lower(tostring(siteName)), "^(%a+)%s")
    if firstWord and FIELD_COLORS[firstWord] then
        local stripped = string.gsub(tostring(siteName), "^%a+%s+", "")
        local sn = normName(stripped)
        hit = firstNorm[sn] or secondNorm[sn]
        if hit then return hit end
        local si = initials(stripped)
        if si and #si > 1 then
            hit = firstInit[si] or secondInit[si]
            if hit then return hit end
        end
    end
    return nil
end

-- variant key -> conditions {kind=eq|leq|geq|range|present|nobase|any} + star rule
local function parseVariant(key)
    if type(key) ~= "string" then return nil end
    local segs, rest = {}, key
    while true do
        local i = string.find(rest, " + ", 1, true)
        if not i then
            segs[#segs + 1] = rest
            break
        end
        segs[#segs + 1] = string.sub(rest, 1, i - 1)
        rest = string.sub(rest, i + 3)
    end
    local conds = {}
    local starN, starLEQ = nil, false
    for _, seg in ipairs(segs) do
        seg = string.gsub(seg, "%s*%(Unwaxed%)%s*$", "")
        local hb = false
        while true do
            local marker, after = string.match(seg, "^%s*(%b{})%s*(.*)$")
            if not marker then break end
            if string.find(marker, "HB", 1, true) then hb = true end
            seg = after
        end
        local before, starPart = string.match(
            seg, "^(.-)([" .. LEQ .. "?]?%s*%d?%s*" .. STAR .. "%s*Pot)%s*$")
        if starPart then
            local n = string.match(starPart, "(%d)")
            if n then
                starN = tonumber(n)
                starLEQ = (string.find(starPart, LEQ, 1, true) ~= nil)
                    or (string.find(starPart, "?", 1, true) ~= nil)
            end
            seg = before
        end
        seg = string.gsub(seg, "%s+$", "")
        if seg ~= "" then
            local nb = string.match(seg, "^No base%s+(.*)$")
            if nb then
                conds[#conds + 1] = { kind = "nobase", name = nb, hb = hb }
            else
                local handled = false
                local v1, v2, namePart = string.match(seg, "^%s*([%d%.]+)%s*%-%s*([%d%.]+)%s*(.*)$")
                if v1 then
                    conds[#conds + 1] = { kind = "range", v1 = tonumber(v1), v2 = tonumber(v2), name = namePart, hb = hb }
                    handled = true
                end
                if not handled then
                    local lv, ln = string.match(seg, "^%s*[" .. LEQ .. "?]%s*([%d%.]+)%s*(.*)$")
                    if lv then
                        conds[#conds + 1] = { kind = "leq", v1 = tonumber(lv), name = ln, hb = hb }
                        handled = true
                    end
                end
                if not handled then
                    local gv, gn = string.match(seg, "^%s*[" .. GEQ .. "]%s*([%d%.]+)%s*(.*)$")
                    if gv then
                        conds[#conds + 1] = { kind = "geq", v1 = tonumber(gv), name = gn, hb = hb }
                        handled = true
                    end
                end
                if not handled then
                    -- "x1.01 Hft": a multiplier stat, compared on the x value
                    local mv, mn = string.match(seg, "^%s*[xX]%s*([%d%.]+)%s+(.+)$")
                    if mv then
                        conds[#conds + 1] = { kind = "eq", v1 = tonumber(mv), name = mn, hb = hb }
                        handled = true
                    end
                end
                if not handled then
                    local ev, en = string.match(seg, "^%s*([%d%.]+)%s*(.*)$")
                    if ev then
                        conds[#conds + 1] = { kind = "eq", v1 = tonumber(ev), name = en, hb = hb }
                        handled = true
                    end
                end
                if not handled then
                    if string.match(seg, "^%?%s*$") then
                        conds[#conds + 1] = { kind = "any" } -- "?" unknown value: weak pass
                    else
                        local nm = string.gsub(seg, "%s*[" .. LEQ .. GEQ .. "]%s*$", "")
                        nm = string.gsub(nm, "^%s+", "")
                        if nm ~= "" then
                            conds[#conds + 1] = { kind = "present", name = nm, hb = hb }
                        end
                    end
                end
            end
        end
    end
    if #conds == 0 and not starN then return nil end
    return { conds = conds, starN = starN, starLEQ = starLEQ }
end

-- Cost of one site condition against the item's signature.
-- 0 = exact, small = off by a little, COST_MISS = the item has no such stat at all.
-- The site only indexes some stat combinations, so "nearest variant" beats "no match".
local COST_MISS = 1e6

local function condCost(sig, c)
    if c.kind == "any" then return 0 end
    local hit = sigLookup(sig, c.name or "", c.hb)
    if c.kind == "nobase" then
        return hit and COST_MISS or 0
    end
    if not hit then return COST_MISS end
    local v = hit.value
    if c.kind == "present" then
        return 0
    elseif c.kind == "eq" then
        return math.abs(v - c.v1)
    elseif c.kind == "leq" then
        return v > c.v1 + 0.005 and (v - c.v1) or 0
    elseif c.kind == "geq" then
        return v < c.v1 - 0.005 and (c.v1 - v) or 0
    elseif c.kind == "range" then
        if v < c.v1 - 0.005 then return c.v1 - v end
        if v > c.v2 + 0.005 then return v - c.v2 end
        return 0
    end
    return 0
end

local function variantCost(sig, parsed)
    local cost = 0
    if parsed.starN then
        if parsed.starLEQ then
            if sig.stars > parsed.starN then cost = cost + (sig.stars - parsed.starN) * 3 end
        else
            cost = cost + math.abs(sig.stars - parsed.starN) * 3
        end
    end
    for _, c in ipairs(parsed.conds) do
        cost = cost + condCost(sig, c)
    end
    return cost
end

-- Our site stores a single price per roll: value_min == value_max. A cell
-- with an unknown price has no value fields at all, so it resolves to nil and
-- never to 0 (a 0 Val beequip would poison the trade diff).
local function priceOf(vd)
    local mn, mx = tonumber(vd.value_min), tonumber(vd.value_max)
    if mn and mx then return (mn + mx) / 2 end
    if mn then return mn end
    return nil
end

-- `entry` is one beequip table from our own site data. Returns price, demand,
-- approx, where approx means "nearest variant", not an exact roll match.
local function beequipSitePrice(obj, name, stars, waxCount, entry)
    if type(entry) ~= "table" or type(entry.stat_groups) ~= "table" then return nil end
    local sig = buildSignature(obj, stars)
    if not sig then
        dbg(name, "buildSignature FAILED")
        return nil
    end
    local sigDebug
    do
        local hn, mn, hi, mi = {}, {}, {}, {}
        for k in pairs(sig.hbNorm) do hn[#hn + 1] = k .. "=" .. tostring(sig.hbNorm[k].value) end
        for k in pairs(sig.modNorm) do mn[#mn + 1] = k .. "=" .. tostring(sig.modNorm[k].value) end
        for k in pairs(sig.hbInit) do hi[#hi + 1] = k .. "=" .. tostring(sig.hbInit[k].value) end
        for k in pairs(sig.modInit) do mi[#mi + 1] = k .. "=" .. tostring(sig.modInit[k].value) end
        table.sort(hn); table.sort(mn); table.sort(hi); table.sort(mi)
        sigDebug = "sigNorm hb=[" .. table.concat(hn, ",") .. "] mod=[" .. table.concat(mn, ",")
            .. "] sigInit hb=[" .. table.concat(hi, ",") .. "] mod=[" .. table.concat(mi, ",") .. "]"
    end

    -- one variant -> stat distance + how many of its conditions the item backs
    local function scoreVariant(vkey, vd)
        local parsed = parseVariant(vkey)
        if not parsed then return nil end
        local cost, matched = 0, 0
        if parsed.starN then
            -- a star rule is weak evidence and must NOT count as a matched stat:
            -- otherwise "4-star Pot" ties with an exactly-matching "{HB} 2 Bap" and
            -- the cheaper price wins, pricing a Toy Drum at 7.5 instead of 9.5.
            if parsed.starLEQ then
                if sig.stars > parsed.starN then cost = cost + (sig.stars - parsed.starN) * 3 end
            else
                cost = cost + math.abs(sig.stars - parsed.starN) * 3
            end
        end
        for _, c in ipairs(parsed.conds) do
            local cst = condCost(sig, c)
            cost = cost + cst
            if cst < COST_MISS then matched = matched + 1 end
        end
        return { cost = cost, matched = matched, vd = vd, vkey = vkey }
    end

    -- Strictly better match? distance, then wax state, then how much of the
    -- variant the item actually supports, then the cheaper price so an
    -- ambiguous tie never inflates the overlay. demand stays nil: our site
    -- stores a RU word ("Nizkiy" / low), not the 0..5 score the old third-party
    -- table had, and a string would only put garbage in the label.
    local function better(a, b)
        if a.cost < b.cost - 0.0001 then return true end
        if a.cost > b.cost + 0.0001 then return false end
        if a.state ~= b.state then return a.state > b.state end
        if a.matched ~= b.matched then return a.matched > b.matched end
        local pa, pb = priceOf(a.vd), priceOf(b.vd)
        if pa == nil then return false end
        if pb == nil then return true end
        if pa ~= pb then return pa < pb end
        return tostring(a.vkey) < tostring(b.vkey)
    end

    local best, bestAny = nil, nil
    for gname, variants in pairs(entry.stat_groups) do
        local state = 0
        if waxCount >= 5 and string.find(gname, "Full Waxed", 1, true) then
            state = 1
        elseif waxCount < 5 and string.find(gname, "Unwaxed", 1, true) then
            state = 1
        end
        for vkey, vd in pairs(variants) do
            local s = scoreVariant(vkey, vd)
            if s then
                s.state = state
                s.gname = gname
                if not bestAny or better(s, bestAny) then bestAny = s end
                -- `best` only ever holds priced variants, so an unpriced info
                -- cell (">=500", "+1% Ability Rate adds 10-15% ...") cannot shadow
                -- a real price just by matching at distance 0.
                if priceOf(vd) ~= nil and (not best or better(s, best)) then best = s end
            end
        end
    end

    if best then
        local approx = best.cost > 0.005
        dbg(name, "match", best.gname .. " / " .. tostring(best.vkey),
            "cost=" .. best.cost, "matched=" .. best.matched,
            approx and "approx" or "exact")
        return priceOf(best.vd), nil, approx
    end

    -- Nothing priced is reachable. If the roll itself is listed but unpriced,
    -- take the closest priced cell of the SAME group; do NOT average the group,
    -- that mixes a cheap cell with a legendary one and invents a value.
    if bestAny and bestAny.cost < COST_MISS then
        local sibCost, sibPrice
        for vkey2, vd2 in pairs(entry.stat_groups[bestAny.gname] or {}) do
            local p2 = parseVariant(vkey2)
            local pr2 = priceOf(vd2)
            if p2 and pr2 and pr2 > 0 then
                local c2 = variantCost(sig, p2)
                if sibCost == nil or c2 < sibCost then sibCost, sibPrice = c2, pr2 end
            end
        end
        dbg(name, "unpriced match", bestAny.gname .. " / " .. tostring(bestAny.vkey),
            "sibling=" .. tostring(sibPrice))
        if sibPrice then return sibPrice, nil, true end
    else
        dbg(name, "no usable variant", sigDebug)
    end
    return nil
end

local bqPriceCache = {}

-- demand / stability words for a beequip, from our own site meta (ru words, not
-- a 0..5 score), so they are only rendered when the user turns that toggle on.
local function bqMeta(name)
    if not bqMod then return nil end
    local m = bqMod.meta and bqMod.meta[name]
    if type(m) ~= "table" then return nil end
    return m
end

-- Re-read both generated modules and rebuild what is known about the catalog.
-- Used by the settings panel's "Refresh data" button; also drops the roll cache
-- so beequips are matched against the fresh data immediately.
local function refreshData()
    stickerMod, stickerAt, stickerIdx = nil, -1e9, nil
    bqMod, bqAt, bqIdx = nil, -1e9, nil
    bqPriceCache = {}
    getStickerModule()
    getBqModule()
    local known = 0
    for _, info in pairs(imageInfo) do
        if not info.isBeequip then
            info.price = stickerPrice(info.name)
            if info.price then known = known + 1 end
        end
    end
    return known
end

-- game name -> our site's name (the site keys beequips by their own name)
local BQ_NAME_ALIASES = {
    ["Horn Ornament"] = "Toy Horn",
    ["Snowglobe"] = "Snow Globe",
    ["Lump Of Coal"] = "Lump of Coal",
}

local function beequipPriceFor(t)
    local pack = t.Pack
    local id
    local okid, s = pcall(function() return t:GetIDString() end)
    if okid and type(s) == "string" and s ~= "" then
        id = s
    elseif type(pack) == "table" and type(pack.File) == "table" then
        id = "pack:" .. table.concat(pack.File, ",")
    end
    if id then
        local c = bqPriceCache[id]
        if c and c.rev == bqRev then return c end
    end
    local result
    local ok, err = pcall(function()
        local obj = BeequipFile.FromData(pack.File)
        local name = tostring(obj.T)
        local siteName = BQ_NAME_ALIASES[name] or name
        local stars = math.floor((obj.Q or 0) / 0.2 + 0.5)
        local waxCount = 0
        local okh, hist = pcall(function() return obj:GetWaxHistory() end)
        if okh and type(hist) == "table" then waxCount = #hist end
        local entry, fromSite = bqEntry(siteName)
        local price, demand, approx
        if entry then
            price, demand, approx = beequipSitePrice(obj, name, stars, waxCount, entry)
        end
        -- No flat PRICES fallback here on purpose: a beequip's index price is
        -- the whole item, not this roll, and it is wildly wrong (Pinecone showed
        -- 167.5 for a ~1 Val roll). Better to show "?" than a confident lie.
        local src = nil
        if price then
            src = fromSite and "site" or "mod"
        end
        local meta = bqMeta(siteName)
        result = { price = price, demand = demand, src = src, approx = approx, meta = meta }
        dbg(name, "stars=" .. tostring(stars), "wax=" .. tostring(waxCount),
            "entry=" .. tostring(entry ~= nil), "site=" .. tostring(fromSite),
            "price=" .. tostring(price), "src=" .. tostring(src))
    end)
    if not ok then
        warn("[TradeValueOverlay] beequip price error: " .. tostring(err))
        result = { price = nil }
    end
    result.rev = bqRev
    if id then bqPriceCache[id] = result end
    return result
end

local function priceForTradable(t)
    local ok, img = pcall(function() return t:GetImage() end)
    local info = ok and imageInfo[img] or nil
    if not info then return nil end
    if info.isBeequip then
        return beequipPriceFor(t)
    end
    return { price = info.price, src = "index" }
end

-- price label on every item slot; beequip tiles get the price of their real roll
local function labelTiles(container, tradables)
    local queues = {}
    if type(tradables) == "table" then
        for _, t in ipairs(tradables) do
            local ok, img = pcall(function() return t:GetImage() end)
            if ok and type(img) == "string" then
                local q = queues[img]
                if not q then
                    q = {}
                    queues[img] = q
                end
                q[#q + 1] = priceForTradable(t)
            end
        end
    end
    for _, d in ipairs(container:GetDescendants()) do
        if d:IsA("ImageLabel") then
            local info = imageInfo[d.Image]
            if info then
                local entry
                local q = queues[d.Image]
                if q and #q > 0 then
                    entry = table.remove(q, 1)
                end
                local price, demand, src, approx, meta
                if entry ~= nil then
                    price, demand, src, approx, meta =
                        entry.price, entry.demand, entry.src, entry.approx, entry.meta
                else
                    price, src = info.price, "index"
                end
                local text, color
                if price then
                    local mult = tileMult(d)
                    -- "~" marks a nearest-variant guess rather than an exact roll match
                    text = ((approx and SETTINGS.showApprox) and "~" or "") .. fmtVal(price * mult) .. " Val"
                    if mult > 1 then
                        text = text .. " (x" .. mult .. ")"
                    end
                    if SETTINGS.showMeta and type(meta) == "table" then
                        local w = meta.demand or meta.stability
                        if type(w) == "string" and w ~= "" then
                            text = text .. " | " .. w
                        end
                    end
                    color = MY_COLOR
                else
                    text = "?"
                    color = NEUTRAL_COLOR
                end
                local lbl = d:FindFirstChild("TradePriceLabel")
                -- the plate spans the tile, so the text has to shrink to fit it:
                -- never truncate and never let a long value spill onto the next tile
                local fs = SETTINGS.compact and 10 or 11
                local avail = math.max(14, d.AbsoluteSize.X - 5)
                fs = fitFontSize(text, fs, Enum.Font.GothamBold, avail, 7)
                if not lbl then
                    lbl = Instance.new("TextLabel")
                    lbl.Name = "TradePriceLabel"
                    lbl.AnchorPoint = Vector2.new(0, 1)
                    lbl.Position = UDim2.new(0, 1, 1, -1)
                    lbl.Size = UDim2.new(1, -2, 0, 14)
                    lbl.BackgroundColor3 = BG
                    lbl.BackgroundTransparency = 0.25
                    lbl.BorderSizePixel = 0
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = fs
                    lbl.TextColor3 = color
                    lbl.Text = text
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.TextYAlignment = Enum.TextYAlignment.Center
                    lbl.TextTruncate = Enum.TextTruncate.None
                    lbl.AutomaticSize = Enum.AutomaticSize.None
                    lbl.ZIndex = 25
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 4)
                    corner.Parent = lbl
                    lbl.Parent = d
                else
                    lbl.Text = text
                    lbl.TextColor3 = color
                    lbl.TextSize = fs
                    lbl.TextTruncate = Enum.TextTruncate.None
                end
                -- diagnostic: which price source produced this label (detects stale copies)
                lbl:SetAttribute("TVO", src or "none")
            end
        end
    end
end

-- per-side total strip under the offer box
local function ensureTotal(tradeFrame, boxName, name, value, unknown, color)
    local box = tradeFrame:FindFirstChild(boxName)
    if not box then return end
    local compact = SETTINGS.compact
    local h = compact and 15 or 18
    local lbl = tradeFrame:FindFirstChild(name)
    if not lbl then
        lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.AnchorPoint = Vector2.new(0, 0)
        lbl.BackgroundColor3 = BG
        lbl.BackgroundTransparency = 0.2
        lbl.BorderSizePixel = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.TextTruncate = Enum.TextTruncate.None
        lbl.AutomaticSize = Enum.AutomaticSize.None
        lbl.ZIndex = 25
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = lbl
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Transparency = 0.55
        stroke.Thickness = 1
        stroke.Parent = lbl
        lbl.Parent = tradeFrame
    end
    local suffix = ""
    if unknown > 0 then
        suffix = " (+" .. unknown .. " ?)"
    end
    local text = fmtVal(value) .. " Val" .. suffix
    local size = compact and 12 or 13
    -- the plate hugs the text with the same padding on both sides, and is never
    -- narrower than the offer box it sits under
    local boxW = box.Size.X.Offset
    if boxW <= 0 then boxW = box.AbsoluteSize.X end
    local w = math.max(boxW, plateWidth(text, size, Enum.Font.GothamBold, compact and 9 or 12, 4))
    lbl.Size = UDim2.fromOffset(w, h)
    lbl.Position = UDim2.fromOffset(
        box.Position.X.Offset - (w - boxW) / 2,
        box.Position.Y.Offset + box.Size.Y.Offset + 2)
    lbl.TextSize = size
    lbl.TextColor3 = color
    lbl.Text = text
end

-- side-to-side difference (centred on the trade icon). Returns the label so the
-- item split below can be aligned to it, or nil when nothing is shown.
local function ensureDiff(tradeFrame, mySum, theirSum, myUnknown, theirUnknown)
    local holder = tradeFrame:FindFirstChild("TradeImage")
    if not holder then return nil end
    local compact = SETTINGS.compact
    local lbl = holder:FindFirstChild("TradeValueDiff")
    if not lbl then
        lbl = Instance.new("TextLabel")
        lbl.Name = "TradeValueDiff"
        lbl.AnchorPoint = Vector2.new(0.5, 0.5)
        lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
        lbl.BackgroundColor3 = BG
        lbl.BackgroundTransparency = 0.2
        lbl.BorderSizePixel = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.TextTruncate = Enum.TextTruncate.None
        lbl.AutomaticSize = Enum.AutomaticSize.None
        lbl.ZIndex = 30
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = lbl
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Transparency = 0.5
        stroke.Thickness = 1
        stroke.Parent = lbl
        lbl.Parent = holder
    end
    if mySum == 0 and theirSum == 0 and myUnknown == 0 and theirUnknown == 0 then
        lbl.Visible = false
        return nil
    end
    lbl.Visible = true
    -- profit = received (their) - given (my): they give me more -> plus
    local diff = theirSum - mySum
    local color, text
    if math.abs(diff) < 0.005 then
        color, text = NEUTRAL_COLOR, "EVEN"
    elseif diff > 0 then
        color, text = OK_COLOR, "+" .. fmtVal(diff) .. " Val"
    else
        color, text = BAD_COLOR, "-" .. fmtVal(diff) .. " Val"
    end
    local size = compact and 16 or 18
    -- the plate is measured from the text, so it can never be too narrow;
    -- 46 px is the floor and covers the shortest label ("EVEN")
    local w = plateWidth(text, size, Enum.Font.GothamBold, compact and 10 or 13, 46)
    lbl.Size = UDim2.fromOffset(w, compact and 25 or 29)
    lbl.TextSize = size
    lbl.TextColor3 = color
    lbl.Text = text
    return lbl
end

-- ===== auto-convert panel ===============================================
-- "What the diff is worth in real items": a compact chip row shown right beside
-- the diff label, on the same horizontal line. It lives in our own ScreenGui and
-- is pinned to the empty column next to the trade window, because the window
-- itself has no free room: below the diff sit Accept / Cancel, and under the
-- window the inventory panel starts. So it never covers a button, an offer box
-- or the inventory, and it is centred on the diff label's own centre line.

-- Everything we draw outside the game's trade window shares one anchor: the
-- free column right of the window, so the chrome never covers Accept / Cancel
-- or an offer box. If the window sits against the right edge it flips left.
local CHROME_W = 210

local function viewportSize()
    local cam = workspace.CurrentCamera
    return (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
end

local function chromePos(tradeFrame, w, h)
    local vp = viewportSize()
    local tx, ty, tw = 40, 120, 0
    if tradeFrame then
        tx, ty = tradeFrame.AbsolutePosition.X, tradeFrame.AbsolutePosition.Y
        tw = tradeFrame.AbsoluteSize.X
    end
    local x = tx + tw + 14
    if x + w > vp.X - 12 then -- no room on the right, try the left
        x = tx - w - 14
        if x < 12 then x = math.max(12, tx) end
    end
    local y = math.min(ty, math.max(12, vp.Y - h - 12))
    return x, y
end

local function cvtFrame()
    local gui = getPanelGui()
    if not gui then return nil end
    local legacy = gui:FindFirstChild("Strip") -- older builds drew a big panel
    if legacy then legacy:Destroy() end
    local split = gui:FindFirstChild("SplitRow")
    if split then return split end

    split = Instance.new("Frame")
    split.Name = "SplitRow"
    split.Size = UDim2.fromOffset(120, 40)
    split.BackgroundColor3 = PANEL_BG
    split.BackgroundTransparency = 0.1
    split.BorderSizePixel = 0
    split.ZIndex = 2
    split.Visible = false
    split.Active = true
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 10)
    sc.Parent = split
    local ss = Instance.new("UIStroke")
    ss.Color = PANEL_STROKE
    ss.Transparency = 0.25
    ss.Thickness = 1
    ss.Parent = split

    local row = Instance.new("Frame")
    row.Name = "Row"
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Position = UDim2.fromOffset(5, 5)
    row.Size = UDim2.new(1, -10, 1, -10)
    row.ZIndex = 4
    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)
    layout.Parent = row
    row.Parent = split

    -- hover tooltip, hanging under the row; its plate follows its own text
    local tip = Instance.new("TextLabel")
    tip.Name = "Tip"
    tip.AnchorPoint = Vector2.new(0.5, 0)
    tip.Position = UDim2.new(0.5, 0, 1, 3)
    tip.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    tip.BackgroundTransparency = 0.05
    tip.BorderSizePixel = 0
    tip.Font = Enum.Font.Gotham
    tip.TextSize = 11
    tip.TextColor3 = Color3.fromRGB(238, 238, 248)
    tip.TextXAlignment = Enum.TextXAlignment.Center
    tip.TextYAlignment = Enum.TextYAlignment.Center
    tip.TextTruncate = Enum.TextTruncate.None
    tip.AutomaticSize = Enum.AutomaticSize.None
    tip.Size = UDim2.fromOffset(40, 19)
    tip.Visible = false
    tip.ZIndex = 12
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 6)
    tc.Parent = tip
    local ts = Instance.new("UIStroke")
    ts.Color = PANEL_STROKE
    ts.Transparency = 0.1
    ts.Thickness = 1
    ts.Parent = tip
    tip.Parent = split

    split.Parent = gui
    return split
end

local function cvtTip(split, show, text)
    local tip = split and split:FindFirstChild("Tip")
    if not tip then return end
    tip.Visible = show
    if text then
        tip.Text = text
        tip.Size = UDim2.fromOffset(
            math.ceil(textWidth(text, tip.TextSize, tip.Font)) + 18, 19)
    end
end

-- One item chip: rounded plate, the item icon, and a "+N" badge on the bottom
-- edge. Sits in the row; the plate around it is drawn by the split frame.
local function cvtChip(row, part, compact, order)
    local split = row.Parent
    local size = compact and 26 or 30
    local ico = compact and 16 or 20
    local tile = Instance.new("TextButton")
    tile.Name = "Chip"
    tile.AutoButtonColor = false
    tile.BackgroundColor3 = Color3.fromRGB(30, 31, 42)
    tile.BackgroundTransparency = 0.1
    tile.Size = UDim2.fromOffset(size, size)
    tile.LayoutOrder = order
    tile.ZIndex = 5
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = tile
    local s = Instance.new("UIStroke")
    s.Color = PANEL_STROKE
    s.Transparency = 0.35
    s.Thickness = 1
    s.Parent = tile
    local img = Instance.new("ImageLabel")
    img.Name = "Ico"
    img.Image = part.image
    img.BackgroundTransparency = 1
    img.Position = UDim2.fromOffset(
        math.floor((size - ico) / 2), math.floor((size - ico) / 2) - 1)
    img.Size = UDim2.fromOffset(ico, ico)
    img.ZIndex = 6
    img.Parent = tile
    local qty = Instance.new("TextLabel")
    qty.Name = "Qty"
    -- badge sits in the bottom-right corner so it never covers the icon
    qty.AnchorPoint = Vector2.new(1, 1)
    qty.Position = UDim2.new(1, 1, 1, 1)
    qty.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    qty.BackgroundTransparency = 0.35
    qty.BorderSizePixel = 0
    qty.Font = Enum.Font.GothamBold
    qty.TextSize = compact and 8 or 9
    qty.TextColor3 = Color3.fromRGB(245, 245, 255)
    qty.TextXAlignment = Enum.TextXAlignment.Center
    qty.TextYAlignment = Enum.TextYAlignment.Center
    qty.TextTruncate = Enum.TextTruncate.None
    qty.Text = "+" .. part.count
    -- badge hugs its own text instead of spanning the whole chip
    qty.Size = UDim2.fromOffset(
        math.max(14, math.ceil(textWidth(qty.Text, qty.TextSize, qty.Font)) + 7),
        compact and 10 or 11)
    qty.ZIndex = 7
    local qc = Instance.new("UICorner")
    qc.CornerRadius = UDim.new(0, 4)
    qc.Parent = qty
    qty.Parent = tile
    tile.MouseEnter:Connect(function()
        s.Transparency = 0.05
        cvtTip(split, true, part.name .. "  -  " .. fmtVal(part.price) .. " Val each")
    end)
    tile.MouseLeave:Connect(function()
        s.Transparency = 0.35
        -- always hide: moving to the next chip fires its MouseEnter right
        -- after this one, so the tip just swaps content
        cvtTip(split, false, nil)
    end)
    tile.Parent = row
    return tile
end

local function hideBreakdown()
    local gui = getPanelGui()
    if not gui then return end
    for _, n in ipairs({ "SplitRow", "Strip" }) do
        local w = gui:FindFirstChild(n)
        if w then w.Visible = false end
    end
end

-- The split itself. diffLabel is the diff plate, so the row can sit on exactly
-- the same centre line a few pixels to its right, in the free column.
local function ensureBreakdown(tradeFrame, diff, diffLabel)
    local split = cvtFrame()
    if not split then return end
    local compact = SETTINGS.compact
    if not SETTINGS.autoconvert or math.abs(diff) < 0.005 or not diffLabel then
        split.Visible = false
        return
    end
    local limit = math.min(math.max(1, math.floor(SETTINGS.iconLimit)), 10)
    local parts, rest = autoconvert(math.abs(diff), limit)
    local color = diff > 0 and OK_COLOR or BAD_COLOR
    local size = compact and 26 or 30
    local gap = 4
    local pad = 10

    -- rebuild the chips only when the split changed, otherwise this runs 3x/second
    local row = split:FindFirstChild("Row")
    local sig = ("%d|%.4f"):format(limit, diff)
    local restW = 0
    if row:GetAttribute("Sig") ~= sig then
        row:SetAttribute("Sig", sig)
        for _, child in ipairs(row:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        cvtTip(split, false, nil)
        for i, p in ipairs(parts) do
            cvtChip(row, p, compact, i)
        end
        if rest > 0 then
            local ts = compact and 10 or 11
            local rem = Instance.new("TextLabel")
            rem.Name = "Rest"
            rem.BackgroundColor3 = Color3.fromRGB(30, 31, 42)
            rem.BackgroundTransparency = 0.1
            rem.BorderSizePixel = 0
            rem.Font = Enum.Font.GothamBold
            rem.TextSize = ts
            rem.TextColor3 = color
            rem.TextXAlignment = Enum.TextXAlignment.Center
            rem.TextYAlignment = Enum.TextYAlignment.Center
            rem.TextTruncate = Enum.TextTruncate.None
            rem.AutomaticSize = Enum.AutomaticSize.None
            rem.LayoutOrder = 100
            rem.Text = "+" .. fmtVal(rest) .. " Val"
            -- measured plate, same padding rule as the diff label
            restW = plateWidth(rem.Text, ts, rem.Font, compact and 7 or 9, 30)
            rem.Size = UDim2.fromOffset(restW, size)
            rem.ZIndex = 5
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(0, 8)
            rc.Parent = rem
            local rs = Instance.new("UIStroke")
            rs.Color = PANEL_STROKE
            rs.Transparency = 0.35
            rs.Thickness = 1
            rs.Parent = rem
            rem.Parent = row
        end
    elseif rest > 0 then
        -- unchanged split: re-measure the remainder chip without rebuilding it
        local rem = row:FindFirstChild("Rest")
        restW = rem and rem.Size.X.Offset or 0
    end

    -- hug the content: padding + chips + gaps (+ the remainder chip)
    local count = #parts + (rest > 0 and 1 or 0)
    local w = pad + #parts * size + restW + math.max(0, count - 1) * gap
    local h = pad + size
    split.Size = UDim2.fromOffset(w, h)

    -- free column beside the trade window, on the diff label's own centre line
    local vp = viewportSize()
    local x = chromePos(tradeFrame, w, h)
    x = math.clamp(x, 10, math.max(10, vp.X - w - 10))
    local cy = diffLabel.AbsolutePosition.Y + diffLabel.AbsoluteSize.Y / 2
    local y = math.clamp(math.floor(cy - h / 2), 10, math.max(10, vp.Y - h - 10))
    split.Position = UDim2.fromOffset(x, y)
    split.Visible = true
end

local function sumOffer(tradables)
    local sum, unknown = 0, 0
    if type(tradables) ~= "table" then return sum, unknown end
    for _, t in ipairs(tradables) do
        local p = priceForTradable(t)
        if p and p.price then
            sum = sum + p.price
        else
            unknown = unknown + 1
        end
    end
    return sum, unknown
end

-- ===== settings panel ====================================================
-- Own ScreenGui on purpose: a Frame parented straight into PlayerGui is drawn
-- UNDER every game ScreenGui and stays invisible. DisplayOrder is high so the
-- panel also wins against the trade's Accept / Cancel buttons.
local UI = { open = false, frame = nil, switches = {}, iconVal = nil, footer = nil }

local PANEL_W = 300
local ROW_H = 30
local HEAD_H = 48
local PANEL_H = HEAD_H + 1 + 5 * (ROW_H - 6) + (ROW_H - 6) + 1 + 28 + 24

local SETTING_LABELS = {
    autoconvert = "Auto-convert",
    showApprox = "Show ~ (approx price)",
    showMeta = "Demand / stability",
    showBrand = "Brand label",
    compact = "Compact mode",
}

-- mutual references are forward declared near the settings block above

-- External image URLs do not render in this client (checked 17.10.2026: neither
-- the site CDN nor the Discord CDN produced a visible frame), so the logo is
-- opt-in: set getgenv().BSS_INDEX_LOGO to an rbxassetid and an ImageLabel is
-- drawn, otherwise a clean text wordmark is used.
local function logoAsset()
    local ok, v = pcall(function() return getgenv().BSS_INDEX_LOGO end)
    if ok and type(v) == "string" and v ~= "" then
        -- both schemes are accepted; "rbxassetid://" does NOT contain "rbxasset://"
        if string.find(v, "rbxassetid://", 1, true) or string.find(v, "rbxasset://", 1, true) then
            return v
        end
    end
    return nil
end

local function panelLabel(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = font or Enum.Font.Gotham
    l.TextSize = size or 12
    l.TextColor3 = color or Color3.fromRGB(226, 228, 238)
    l.Text = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function panelSeparator(parent, order)
    local s = Instance.new("Frame")
    s.Name = "Sep"
    s.LayoutOrder = order
    s.Size = UDim2.new(1, -20, 0, 1)
    s.Position = UDim2.new(0, 10, 0, 0)
    s.BackgroundColor3 = PANEL_STROKE
    s.BackgroundTransparency = 0.55
    s.BorderSizePixel = 0
    s.Parent = parent
    return s
end

-- switch track + knob; the knob is remembered so syncPanel can redraw it
local function makeSwitch(parent, key, order)
    local row = Instance.new("Frame")
    row.Name = "Row"
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -20, 0, ROW_H - 6)
    row.Position = UDim2.new(0, 10, 0, 0)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Parent = parent
    local name = panelLabel(row, SETTING_LABELS[key], 12, Color3.fromRGB(226, 228, 238), Enum.Font.Gotham)
    name.Size = UDim2.new(1, -60, 1, 0)
    name.TextYAlignment = Enum.TextYAlignment.Center
    local sw = Instance.new("TextButton")
    sw.Name = "Switch"
    sw.AnchorPoint = Vector2.new(1, 0.5)
    sw.Position = UDim2.new(1, 0, 0.5, 0)
    sw.Size = UDim2.fromOffset(38, 20)
    sw.AutoButtonColor = false
    sw.BackgroundColor3 = Color3.fromRGB(52, 54, 68)
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.Parent = row
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = sw
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.fromRGB(226, 228, 238)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    UI.switches[key] = { switch = sw, knob = knob }
    sw.MouseButton1Click:Connect(function()
        setSetting(key, not SETTINGS[key])
        syncPanel()
    end)
    return row
end

-- redraw every switch from SETTINGS (called after any change)
syncPanel = function()
    for key, w in pairs(UI.switches) do
        local on = SETTINGS[key] and true or false
        w.switch.BackgroundColor3 = on and ACCENT or Color3.fromRGB(52, 54, 68)
        w.knob.BackgroundColor3 = on and Color3.fromRGB(18, 18, 24) or Color3.fromRGB(226, 228, 238)
        w.knob.Position = UDim2.fromOffset(on and 20 or 2, 2)
    end
    if UI.iconVal then UI.iconVal.Text = tostring(SETTINGS.iconLimit) end
    if UI.footer then
        UI.footer.Text = ("data: stickers %s | beequips %s | %d priced, %d ?"):format(
            stickerMod and tostring(stickerMod.generated) or "-",
            bqMod and tostring(bqMod.generated) or "-",
            priced, unpriced)
    end
end

local function buildPanel(tradeFrame)
    local gui = getPanelHost()
    if not gui then return nil end
    local panel = gui:FindFirstChild("Panel")
    if panel then return panel end

    local dim = Instance.new("TextButton")
    dim.Name = "Dim"
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.45
    dim.BorderSizePixel = 0
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.ZIndex = 1
    dim.Parent = gui
    dim.MouseButton1Click:Connect(function() togglePanel(tradeFrame, false) end)

    local H = PANEL_H
    panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(PANEL_W, H)
    panel.BackgroundColor3 = PANEL_BG
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    panel.ZIndex = 2
    panel.Active = true
    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(0, 12)
    pc.Parent = panel
    local ps = Instance.new("UIStroke")
    ps.Color = PANEL_STROKE
    ps.Transparency = 0.15
    ps.Thickness = 1
    ps.Parent = panel
    panel.Parent = gui

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.fromScale(1, 1)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ZIndex = 3
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.FillDirection = Enum.FillDirection.Vertical
    list.Padding = UDim.new(0, 0)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left
    list.Parent = body
    body.Parent = panel

    -- header: logo + title + close
    local head = Instance.new("Frame")
    head.Name = "Head"
    head.LayoutOrder = 0
    head.Size = UDim2.new(1, 0, 0, HEAD_H)
    head.BackgroundTransparency = 1
    head.BorderSizePixel = 0
    head.ZIndex = 3
    head.Parent = body
    local asset = logoAsset()
    if asset then
        local li = Instance.new("ImageLabel")
        li.Name = "LogoImage"
        li.BackgroundTransparency = 1
        li.Image = asset
        li.Position = UDim2.fromOffset(12, 9)
        li.Size = UDim2.fromOffset(30, 30)
        li.ZIndex = 4
        li.Parent = head
        local word = panelLabel(head, "BSS INDEX", 13, ACCENT, Enum.Font.GothamBold)
        word.Position = UDim2.fromOffset(48, 7)
        word.Size = UDim2.fromOffset(120, 17)
        local sub = panelLabel(head, "Tools", 9, MUTED)
        sub.Position = UDim2.fromOffset(49, 24)
        sub.Size = UDim2.fromOffset(120, 14)
    else
        local word = panelLabel(head, "BSS INDEX", 14, ACCENT, Enum.Font.GothamBold)
        word.Position = UDim2.fromOffset(12, 7)
        word.Size = UDim2.fromOffset(130, 18)
        local sub = panelLabel(head, "Tools", 9, MUTED)
        sub.Position = UDim2.fromOffset(13, 24)
        sub.Size = UDim2.fromOffset(130, 14)
    end
    local title = panelLabel(head, "Settings", 11, MUTED)
    title.Name = "Title"
    title.AnchorPoint = Vector2.new(1, 0)
    title.Position = UDim2.new(1, -34, 0, 25)
    title.Size = UDim2.fromOffset(120, 16)
    title.TextXAlignment = Enum.TextXAlignment.Right
    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -8, 0, 8)
    close.Size = UDim2.fromOffset(20, 20)
    close.BackgroundColor3 = Color3.fromRGB(52, 54, 68)
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.TextColor3 = Color3.fromRGB(226, 228, 238)
    close.Text = "X"
    close.ZIndex = 5
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = close
    close.Parent = head
    close.MouseButton1Click:Connect(function() togglePanel(tradeFrame, false) end)
    local sep = panelSeparator(body, 1)
    sep.Size = UDim2.new(1, -20, 0, 1)

    -- toggles
    local order = 2
    local toggleKeys = { "autoconvert", "showApprox", "showMeta", "showBrand", "compact" }
    for _, key in ipairs(toggleKeys) do
        makeSwitch(body, key, order)
        order = order + 1
    end

    -- icon limit stepper
    local limRow = Instance.new("Frame")
    limRow.Name = "Row"
    limRow.LayoutOrder = order
    order = order + 1
    limRow.Size = UDim2.new(1, -20, 0, ROW_H - 6)
    limRow.Position = UDim2.fromOffset(10, 0)
    limRow.BackgroundTransparency = 1
    limRow.BorderSizePixel = 0
    limRow.Parent = body
    local limName = panelLabel(limRow, "Icon limit", 12, Color3.fromRGB(226, 228, 238))
    limName.Size = UDim2.new(1, -110, 1, 0)
    limName.TextYAlignment = Enum.TextYAlignment.Center
    local step = function(delta)
        local v = math.floor(SETTINGS.iconLimit) + delta
        if v < 1 then v = 1 end
        if v > 12 then v = 12 end
        setSetting("iconLimit", v)
        syncPanel()
    end
    local minus = Instance.new("TextButton")
    minus.Name = "Minus"
    minus.AnchorPoint = Vector2.new(1, 0.5)
    minus.Position = UDim2.new(1, -70, 0.5, 0)
    minus.Size = UDim2.fromOffset(20, 20)
    minus.BackgroundColor3 = Color3.fromRGB(52, 54, 68)
    minus.BorderSizePixel = 0
    minus.AutoButtonColor = false
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 12
    minus.TextColor3 = Color3.fromRGB(226, 228, 238)
    minus.Text = "-"
    minus.ZIndex = 4
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 6)
    mc.Parent = minus
    minus.Parent = limRow
    minus.MouseButton1Click:Connect(function() step(-1) end)
    local val = Instance.new("TextLabel")
    val.Name = "Val"
    val.AnchorPoint = Vector2.new(1, 0.5)
    val.Position = UDim2.new(1, -44, 0.5, 0)
    val.Size = UDim2.fromOffset(22, 20)
    val.BackgroundTransparency = 1
    val.BorderSizePixel = 0
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextColor3 = ACCENT
    val.Text = tostring(SETTINGS.iconLimit)
    val.ZIndex = 4
    val.Parent = limRow
    UI.iconVal = val
    local plus = Instance.new("TextButton")
    plus.Name = "Plus"
    plus.AnchorPoint = Vector2.new(1, 0.5)
    plus.Position = UDim2.new(1, -18, 0.5, 0)
    plus.Size = UDim2.fromOffset(20, 20)
    plus.BackgroundColor3 = Color3.fromRGB(52, 54, 68)
    plus.BorderSizePixel = 0
    plus.AutoButtonColor = false
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 12
    plus.TextColor3 = Color3.fromRGB(226, 228, 238)
    plus.Text = "+"
    plus.ZIndex = 4
    local pc2 = Instance.new("UICorner")
    pc2.CornerRadius = UDim.new(0, 6)
    pc2.Parent = plus
    plus.Parent = limRow
    plus.MouseButton1Click:Connect(function() step(1) end)

    local sep2 = panelSeparator(body, order)
    order = order + 1
    sep2.Size = UDim2.new(1, -20, 0, 1)

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Name = "Refresh"
    refreshBtn.LayoutOrder = order
    order = order + 1
    refreshBtn.Size = UDim2.new(1, -20, 0, 28)
    refreshBtn.Position = UDim2.fromOffset(10, 0)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(34, 46, 62)
    refreshBtn.BorderSizePixel = 0
    refreshBtn.AutoButtonColor = false
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 12
    refreshBtn.TextColor3 = Color3.fromRGB(226, 228, 238)
    refreshBtn.Text = "Refresh data"
    refreshBtn.ZIndex = 4
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = refreshBtn
    refreshBtn.Parent = body
    refreshBtn.MouseButton1Click:Connect(function()
        local known = refreshData()
        refreshBtn.Text = ("Reloaded (%d priced)"):format(known)
        syncPanel()
        task.delay(1.5, function()
            if refreshBtn.Parent then refreshBtn.Text = "Refresh data" end
        end)
    end)

    local footer = panelLabel(body, "", 9, MUTED)
    footer.Name = "Footer"
    footer.LayoutOrder = order
    footer.Size = UDim2.new(1, -20, 0, 18)
    footer.Position = UDim2.fromOffset(10, 6)
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.ZIndex = 4
    UI.footer = footer
    syncPanel()
    return panel
end

-- the ScreenGui a Frame cannot live in: PlayerGui child with a high DisplayOrder
getPanelGui = function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local gui = pg:FindFirstChild("BSSIndexGui")
    if gui then return gui end
    gui = Instance.new("ScreenGui")
    gui.Name = "BSSIndexGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    -- Never switched off: the auto-convert strip, the brand label and the gear
    -- button live here and must stay on screen while the settings are closed.
    -- The modal lives in its own gui (see getPanelHost) for exactly that reason.
    gui.Parent = pg
    return gui
end

-- separate ScreenGui for the modal panel. Toggling Enabled on it shows and hides
-- the panel without touching the strip, and the higher DisplayOrder makes the
-- dimmer + panel draw over every game gui (including Accept / Cancel).
getPanelHost = function()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local gui = pg:FindFirstChild("BSSIndexPanelGui")
    if gui then return gui end
    gui = Instance.new("ScreenGui")
    gui.Name = "BSSIndexPanelGui"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 6000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled = false
    gui.Parent = pg
    return gui
end

-- open/close; nil toggles. Clicking the dimmer or the X closes it.
togglePanel = function(tradeFrame, force)
    local host = getPanelHost()
    if not host then return end
    if tradeFrame then UI.frame = tradeFrame end
    UI.frame = getTradeFrame() or UI.frame
    local want
    if force == nil then want = not UI.open else want = force end
    UI.open = want
    host.Enabled = want -- only the modal gui flips: the strip keeps running
    if not want then return end
    local panel = buildPanel(UI.frame)
    if not panel then return end
    -- anchor under the gear, or the trade frame corner when the gear is gone
    local gx, gy
    local gui = getPanelGui()
    local gear = gui and gui:FindFirstChild("BSSIndexGear")
    if gear then
        gx, gy = gear.AbsolutePosition.X, gear.AbsolutePosition.Y
    elseif UI.frame then
        gx = UI.frame.AbsolutePosition.X + UI.frame.AbsoluteSize.X - 16
        gy = UI.frame.AbsolutePosition.Y + UI.frame.AbsoluteSize.Y
    end
    gx, gy = gx or 300, gy or 420
    -- sit under the gear, clamped so the panel never leaves the screen
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local x = math.clamp(gx - PANEL_W + 16, 8, math.max(8, vp.X - PANEL_W - 8))
    local y = math.clamp(gy + 26, 8, math.max(8, vp.Y - panel.Size.Y.Offset - 8))
    panel.Position = UDim2.fromOffset(x, y)
    syncPanel()
end

-- Brand label + gear. Both live in our own ScreenGui: inside the game's
-- TradeFrame the gear was clipped by the trade window edge and could end up
-- under the trade's own buttons, and it was never clickable while the trade was.
local function ensureBrand(tradeFrame)
    local gui = getPanelGui()
    if not gui then return end
    local lbl = gui:FindFirstChild("BSSIndexBrand")
    if not lbl then
        lbl = Instance.new("TextLabel")
        lbl.Name = "BSSIndexBrand"
        lbl.BackgroundTransparency = 1
        lbl.BorderSizePixel = 0
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(150, 150, 160)
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Text = "BSS Index Tools"
        lbl.Size = UDim2.fromOffset(CHROME_W - 24, 16)
        lbl.ZIndex = 6
        lbl.Parent = gui
    end
    -- the gear sits in the left half of the brand row, above the icon strip
    local gear = gui:FindFirstChild("BSSIndexGear")
    if not gear then
        gear = Instance.new("TextButton")
        gear.Name = "BSSIndexGear"
        gear.AutoButtonColor = false
        gear.AnchorPoint = Vector2.new(0, 0.5)
        gear.Size = UDim2.fromOffset(18, 18)
        gear.BackgroundColor3 = BG
        gear.BackgroundTransparency = 0.35
        gear.BorderSizePixel = 0
        gear.Font = Enum.Font.GothamBold
        gear.TextSize = 12
        gear.TextColor3 = Color3.fromRGB(178, 180, 196)
        gear.Text = "\226\152\133" -- star glyph used as the settings icon
        gear.ZIndex = 8
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = gear
        local s = Instance.new("UIStroke")
        s.Color = PANEL_STROKE
        s.Transparency = 0.4
        s.Thickness = 1
        s.Parent = gear
        gear.MouseEnter:Connect(function() gear.TextColor3 = ACCENT end)
        gear.MouseLeave:Connect(function() gear.TextColor3 = Color3.fromRGB(178, 180, 196) end)
        gear.MouseButton1Click:Connect(function()
            if type(alive) ~= "function" or alive() then togglePanel(tradeFrame) end
        end)
        gear.Parent = gui
    end
    local bx, by = chromePos(tradeFrame, CHROME_W, 16)
    lbl.Position = UDim2.fromOffset(bx + 24, by - 1)
    gear.Position = UDim2.fromOffset(bx, by + 6)
    -- the brand text follows the toggle, the gear never hides: it is the only
    -- way back into the settings once the brand is off
    lbl.Visible = SETTINGS.showBrand
    gear.Visible = true
    gear.BackgroundColor3 = UI.open and Color3.fromRGB(46, 40, 20) or BG
    lbl.TextColor3 = UI.open and MUTED or Color3.fromRGB(150, 150, 160)
end

-- drop every overlay widget when the trade window goes away
local function hideChrome()
    local gui = getPanelGui()
    if not gui then return end
    for _, n in ipairs({ "SplitRow", "Strip", "BSSIndexBrand", "BSSIndexGear" }) do
        local w = gui:FindFirstChild(n)
        if w then w.Visible = false end
    end
end

local function refresh()
    if not TradeGui.IsVisible() then
        -- nothing to show and nothing left on screen
        hideBreakdown()
        hideChrome()
        if UI.open then togglePanel(nil, false) end
        return
    end
    local tf = getTradeFrame()
    if not tf then return end

    local box1 = tf:FindFirstChild("TradeOfferBox1")
    local box2 = tf:FindFirstChild("TradeOfferBox2")

    local myOffer = TradeGui.GetMyOffer()
    local theirOffer = TradeGui.GetTheirOffer()

    if box1 then labelTiles(box1, myOffer) end
    if box2 then labelTiles(box2, theirOffer) end

    local mySum, myUnknown = sumOffer(myOffer)
    local theirSum, theirUnknown = sumOffer(theirOffer)

    ensureTotal(tf, "TradeOfferBox1", "MyOfferValue", mySum, myUnknown, MY_COLOR)
    ensureTotal(tf, "TradeOfferBox2", "TheirOfferValue", theirSum, theirUnknown, THEIR_COLOR)
    local diffLabel = ensureDiff(tf, mySum, theirSum, myUnknown, theirUnknown)
    -- sign convention is fixed: diff = theirSum - mySum, plus means "I gain"
    ensureBreakdown(tf, theirSum - mySum, diffLabel)
    ensureBrand(tf)
end

-- ==== single-instance guard ====================================================
-- live-reload does not stop the previous run, so without this several copies of
-- the overlay end up refreshing every 0.3s and overwriting each other's labels.
local env = getgenv()
local prevRun = env.BSS_INDEX_TOOLS_RUN
if type(prevRun) == "table" then
    pcall(function() prevRun.stopped = true end)
    pcall(function()
        for _, c in ipairs(prevRun.conns or {}) do
            c:Disconnect()
        end
    end)
    -- drop the previous run's own ScreenGui (panel + auto-convert strip) so a
    -- live-reload rebuilds the widgets from the current code instead of reusing
    -- instances shaped by the older one
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        for _, n in ipairs({ "BSSIndexGui", "BSSIndexPanelGui" }) do
            local old = pg and pg:FindFirstChild(n)
            if old then old:Destroy() end
        end
    end)
end
local RUN = { stopped = false, conns = {} }
env.BSS_INDEX_TOOLS_RUN = RUN

-- older builds put the gear / brand inside the game's TradeFrame. They would
-- survive the live-reload and sit on top of the trade window, so drop them once.
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    local tf = pg and pg:FindFirstChild("TradeFrame", true)
    if tf then
        for _, n in ipairs({ "BSSIndexGear", "BSSIndexBrand" }) do
            local old = tf:FindFirstChild(n)
            if old then old:Destroy() end
        end
    end
end)

-- verification hook (used by the tests, harmless in game): what the overlay
-- currently knows about the item catalog and which data revisions are loaded.
RUN.stats = function()
    local known, missing = 0, {}
    for _, info in pairs(imageInfo) do
        if not info.isBeequip then
            if info.price then
                known = known + 1
            else
                missing[#missing + 1] = info.name
            end
        end
    end
    table.sort(missing)
    return {
        priced = priced, unpriced = unpriced,
        stickerPriced = known, stickerMissing = #missing, missing = missing,
        stickerGen = stickerMod and tostring(stickerMod.generated) or "none",
        beequipGen = bqMod and tostring(bqMod.generated) or "none",
        poolSize = #CVT_POOL,
    }
end

-- more hooks for the tests: split a sum, read/write settings, drive the panel
RUN.autoconvert = function(v, lim) return autoconvertText(v, lim) end
RUN.settings = SETTINGS
RUN.setSetting = setSetting
RUN.refreshData = refreshData
RUN.panel = function(force) togglePanel(nil, force) end

-- live-reload only tears down what a run registered through STATE. A loop spawned
-- with a bare task.spawn is not tracked, so several copies would keep refreshing
-- every 0.3s and overwrite each other's labels. Prefer STATE.alive(), and keep the
-- getgenv token as a fallback for runs started outside live-reload.
if type(STATE) == "table" and type(STATE.alive) == "function" then
    alive = STATE.alive
else
    alive = function()
        return not RUN.stopped
    end
end

print(("[TradeValueOverlay] loaded: %d priced / %d unpriced items (BSS Index Tools)"):format(priced, unpriced))
print("[TradeValueOverlay] instance " .. math.random(100000, 999999))

-- Beequip data comes from the local module: no periodic network loop.
-- The optional own-site refresh above only runs when INDEX_API_URL is set.
getStickerModule()
getBqModule()

task.spawn(function()
    while alive() and task.wait(0.3) do
        local ok, err = pcall(refresh)
        if not ok then
            warn("[TradeValueOverlay] " .. tostring(err))
        end
    end
end)
