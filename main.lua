-- ===== Navegação Manual (HUD) =====
-- Teleporte + Farm Inicial (Carrot Rod → XP) + progressão de varas.
--
-- ORGANIZAÇÃO (limite Luau: 200 locals por escopo, incluindo locals dentro de funções):
--   • Cada bloco `do -- nome` deve ter no máximo ~8 funções locais.
--   • Evitar `local fn = Nav.fn` em blocos grandes — usar Nav.fn() direto.
--   • API pública fica em `Nav`; estado compartilhado no escopo raiz.
--   • Novos módulos: criar bloco `do` próprio em vez de expandir um existente.
--
-- Execute no executor (UNICO loadstring):
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Snowyno/scriptfarm/refs/heads/main/main.lua"))()
--
-- Dentro deste script: loadstring de cada quest (Oscar, Pinion, Duskwire, TryHard) via HttpGet.
-- Suba no GitHub: main.lua + Oscar.lua + Pinion.lua + Duskwire.lua + TryHardRod.lua

print("[navegacao] main.lua v3 — carregando...")

local PLAYER = game.Players.LocalPlayer
local CHARACTER = PLAYER.Character or PLAYER.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")

-- ===== Posições e requisitos (extraídos do script original) =====
local FISHING_SPOT = Vector3.new(3703.91, -1126.86, -1093.63)
local XP_FARM_SPOT = Vector3.new(-2690.02, 164.74, 1731.67)
local CARROT_ROD_SHOP_SPOT = Vector3.new(3722.94, -1127.99, -1060.95)
local ENCHANT_ALTAR_SPOT = Vector3.new(1310.27, -802.43, -82.36)
local ENCHANT_RELIC_SHOP_SPOT = Vector3.new(-953.98, 222.16, -987.05)
local POST_XP_NPC_SPOT = Vector3.new(-2951, 184, 1623)
local POST_XP_MISSION_OBJECT_SPOT = Vector3.new(-3558, 145, 480)
local OSCAR_ROD_SHOP_SPOT = Vector3.new(272.33, -386.64, 3406.59)
local PINION_VERTIGO_UNLOCK_SPOT = Vector3.new(-103.43, -732.63, 1209.53)
local PINION_DEPTHS_KEY_SPOT = Vector3.new(13, -706, 1246.36)
local PINION_ENCHANT_RELIC_SPOT = Vector3.new(1379.14, -601.85, 2392.43)
local PINION_STEP6_SPOT = Vector3.new(2065.91, -640.8, 2471.5)
local PINION_STEP7_SPOT = Vector3.new(1375.46, -603.65, 2339.69)
local PINION_STEP9_SPOT = Vector3.new(636.36, 324.24, -2056.43)
local PINION_HEAVENLY_DOVE_SPOT = Vector3.new(1492.97, 2601.36, -1731.09)
local PINION_POST_QUEST_FISH_SPOT = Vector3.new(1375.34, -603.58, 2338.28)
local DUSKWIRE_STEP1_SPOT = Vector3.new(2038, -645, 2463)
local DUSKWIRE_STEP2_SPOT = Vector3.new(2478.29, 129.93, -678.22)
local TRYHARD_STEP1_SPOT = Vector3.new(-1921, 262, 119)
local TRYHARD_STEP2_SPOT = Vector3.new(-1954.72, 130.31, 58.57)
local PINION_HEAVENS_ROD_SPOTS = {
    Vector3.new(400, 135, 265),
    Vector3.new(5506, 147, -315),
    Vector3.new(2930, 281, 2594),
    Vector3.new(-1715, 149, 737),
    Vector3.new(-2566, 181, 1353),
    Vector3.new(19922, 1137, 5356),
}
local PINION_HEAVENS_FINAL_SPOT = Vector3.new(19986, 906, 5453)
local HEAVENS_STEP5_KEYS = { "heavens5_1", "heavens5_2", "heavens5_3", "heavens5_4", "heavens5_5", "heavens5_6" }
local PINION_QUEST_UNDO_ORDER = {
    "step1", "step2", "step3", "step4", "step5", "step6", "step7", "step8", "step9",
    "heavens1", "heavens2", "heavens3", "heavens4",
    "heavens5_1", "heavens5_2", "heavens5_3", "heavens5_4", "heavens5_5", "heavens5_6",
    "heavens6",
    "step10", "step11", "step12", "step13",
}
local DUSKWIRE_QUEST_UNDO_ORDER = { "step1", "step2", "step3" }
local TRYHARD_QUEST_UNDO_ORDER = { "step1", "step2" }

local FACE_YAW = math.rad(220)
local XP_FACE_YAW = math.rad(120)

local CARROT_ROD_PRICE = 75000
local ENCHANT_RELIC_PRICE = 11000
local ENCHANT_RELIC_MIN_LEVEL = 30
local POST_XP_MIN_LEVEL = 250
local POST_XP_MIN_COINS = 2500000
local OSCAR_ROD_MIN_LEVEL = 250
local OSCAR_ROD_PRICE = 2500000
local PINION_ARIA_MIN_LEVEL = 424
local DUSKWIRE_ROD_MIN_LEVEL = 275
local POST_XP_AMULET_NAME = "Amulet"
local PINION_ISONADE_NAME = "Isonade"
local PINION_DEPTHS_KEY_NAME = "The Depths Key"
local PINION_ENCHANT_RELIC_NAME = "Enchant Relic"
local PINION_ENCHANT_REQUIRED = "Chaotic"
local OSCAR_ROD_NAME = "Great Rod of Oscar"
local OSCAR_ROD_ALIASES = { "Great Rod of Oscar", "Great Rod Of Oscar" }
local FALLBACK_ROD = "Flimsy Rod"

-- Ordem de compra: Fast Rod -> Rapid Rod -> Lucky Rod -> Carrot Rod
local ROD_PURCHASE_QUEUE = {
    { name = "Fast Rod", price = 4000 },
    { name = "Rapid Rod", price = 12000 },
    { name = "Lucky Rod", price = 4500 },
    { name = "Carrot Rod", price = 75000 },
}

local ROD_EQUIP_PRIORITY = {
    "Great Rod of Oscar",
    "Carrot Rod",
    "Rapid Rod",
    "Fast Rod",
    "Flimsy Rod",
}

local ROD_SHOP_SPOT = Vector3.new(447.55, 150.5, 221.58)
local LUCKY_ROD_SHOP_SPOT = Vector3.new(446.05, 150.5, 222.36)
local RAPID_ROD_SHOP_SPOT = Vector3.new(-1498.85, 141.42, 754.59)

local POSITION_CHECK_INTERVAL = 4
local POSITION_CHECK_INTERVAL_FARM = 12
local POSITION_CHECK_INTERVAL_FARM_XP = 20
local SPOT_TOLERANCE = Vector3.new(5, 5, 5)
local SPOT_TOLERANCE_FARM = Vector3.new(10, 10, 10)
local HUD_UPDATE_INTERVAL = 20
local HUD_FAST_UPDATE_INTERVAL = 8
local HUD_UPDATE_INTERVAL_FARM = 180
local HUD_FAST_UPDATE_INTERVAL_FARM = 60
local LEVEL_CACHE_TTL = 15
local COINS_CACHE_TTL = 8
local COINS_CACHE_TTL_FARM = 30
local BESTIARY_CACHE_TTL = 120
local BESTIARY_REFRESH_INTERVAL = 120
local OWNED_ROD_CACHE_TTL = 60
local OWNED_ROD_CACHE_TTL_FARM = 300
local AMULET_CACHE_TTL = 15
local SELL_ALL_INTERVAL = 30
local AUTO_BUY_CHECK_INTERVAL = 25
local AUTO_BUY_CHECK_INTERVAL_XP = 120
local AUTO_BUY_FAIL_COOLDOWN = 20
local ROD_SYNC_COOLDOWN = 120
local ROD_SYNC_COOLDOWN_XP = 300
local FARM_ROD_STABLE_SKIP = 300
local FARM_ROD_EQUIP_FAIL_BACKOFF = 300
local CHARACTER_CACHE_TTL = 3
local HRP_CACHE_TTL = 2
local FARM_STRATEGY_CACHE_TTL = 30
local PURCHASE_HUD_REOPEN_INTERVAL = 2.5
local PURCHASE_RETRY_INTERVAL = 1.2
local HUD_CONTAINERS_CACHE_TTL = 15
local UI_SCAN_MAX_DEPTH = 8
local BESTIARY_UI_SCAN_DEPTH = 12
local ROD_INTERACTABLE_CACHE_TTL = 300

-- Remotes
local Net = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
local EquipRemote = Net:FindFirstChild("RE/Backpack/Equip")
local RodEquipRemote = Net:FindFirstChild("RF/Rod/Equip")
local SetHotbarRemote = Net:FindFirstChild("RE/Backpack/SetHotbar")
local DataController = ReplicatedStorage:FindFirstChild("client")
    and ReplicatedStorage.client:FindFirstChild("init")
    and ReplicatedStorage.client.init:FindFirstChild("DataController")
local ReplicatorInternal = ReplicatedStorage:FindFirstChild("__ReplicatorInternal")
local ReplicatorEvent = ReplicatorInternal and ReplicatorInternal:FindFirstChild("RemoteEvent")
local Events = ReplicatedStorage:WaitForChild("events", 10)
local PurchaseRemote = Events and Events:FindFirstChild("purchase")
local PromptRemote = Events and Events:FindFirstChild("prompt")
local AnnoEquipEvent = Events and Events:FindFirstChild("anno_equip")
local SellAllRemote = Events and Events:FindFirstChild("SellAll")
local DialogModule = ReplicatedStorage:FindFirstChild("client")
    and ReplicatedStorage.client:FindFirstChild("legacy")
    and ReplicatedStorage.client.legacy:FindFirstChild("StarterPlayerScripts")
    and ReplicatedStorage.client.legacy.StarterPlayerScripts:FindFirstChild("Dialog")

-- ===== Estado =====
local scriptAlive = true
local connections = {}
local hudGui = nil
local activeMode = nil
local positionHoldToken = nil
local shopHoldToken = nil
local purchasingRod = false
local autoSellEnabled = false
local lastAutoBuyAttemptAt = 0
local initialFarmPhase = nil
local lastBestiaryRefreshAt = 0
local lastRodSyncAt = 0
local farmCycleRunning = false
local farmCycleCounter = 0
local lastFarmHudUpdateAt = 0
local lastFarmRodOkAt = 0
local lastFarmRodEquipFailAt = 0
local selectedRodName = nil
local pinionQuestProgress = { step1 = false, step2 = false, step3 = false, step4 = false, step5 = false, step6 = false, step7 = false, step8 = false, step9 = false, step10 = false, step11 = false, step12 = false, step13 = false }
local duskwireQuestProgress = { step1 = false, step2 = false, step3 = false }
local tryhardQuestProgress = { step1 = false, step2 = false }
local pinionHeavensProgress = {
    heavens1 = false,
    heavens2 = false,
    heavens3 = false,
    heavens4 = false,
    heavens5_1 = false,
    heavens5_2 = false,
    heavens5_3 = false,
    heavens5_4 = false,
    heavens5_5 = false,
    heavens5_6 = false,
    heavens6 = false,
}
local questState = {
    oscar = { started = false, redoActive = false },
    pinion = {
        started = false,
        redoActive = false,
        progress = pinionQuestProgress,
        heavens = pinionHeavensProgress,
    },
    duskwire = {
        started = false,
        redoActive = false,
        progress = duskwireQuestProgress,
    },
    tryhard = {
        started = false,
        redoActive = false,
        progress = tryhardQuestProgress,
    },
}
local DUSKWIRE_PROGRESS_KEYS = { "step1", "step2", "step3" }
local TRYHARD_PROGRESS_KEYS = { "step1", "step2" }
local EquipRod
local Bag, Hotbar, Bestiary, RodEquipRF = {}, {}, {}, {}
local clickGuiButton
local ownsRod
local updateHudVisuals

local Nav = {}

-- Cache de quests (constantes/helpers compartilhados entre blocos de cache)
local PINION_PROGRESS_CACHE_FOLDER = "navegacao_cache"
local PINION_PROGRESS_WORKSPACE_FOLDER = "_NavegacaoCache"
local PINION_PROGRESS_KEYS = { "step1", "step2", "step3", "step4", "step5", "step6", "step7", "step8", "step9", "step10", "step11", "step12", "step13" }
local PINION_HEAVENS_PROGRESS_KEYS = {
    "heavens1", "heavens2", "heavens3", "heavens4",
    "heavens5_1", "heavens5_2", "heavens5_3", "heavens5_4", "heavens5_5", "heavens5_6",
    "heavens6",
}

local function canUsePinionFileCache()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function ensurePinionProgressCacheFolder()
    if type(makefolder) == "function" and type(isfolder) == "function" then
        if not isfolder(PINION_PROGRESS_CACHE_FOLDER) then
            pcall(makefolder, PINION_PROGRESS_CACHE_FOLDER)
        end
    end
end


local MODES = {
    INITIAL_FARM = "initial_farm",
    XP_FARM = "xp_farm",
    ENCHANT = "enchant",
    RELIC = "relic",
    OSCAR_STEP1 = "oscar_step1",
    OSCAR_STEP2 = "oscar_step2",
    OSCAR_STEP3 = "oscar_step3",
    PINION_STEP1 = "pinion_step1",
    PINION_STEP2 = "pinion_step2",
    PINION_STEP3 = "pinion_step3",
    PINION_STEP4 = "pinion_step4",
    PINION_STEP5 = "pinion_step5",
    PINION_STEP6 = "pinion_step6",
    PINION_STEP7 = "pinion_step7",
    PINION_STEP8 = "pinion_step8",
    PINION_STEP9 = "pinion_step9",
    PINION_STEP10 = "pinion_step10",
    PINION_STEP11 = "pinion_step11",
    PINION_STEP12 = "pinion_step12",
    PINION_STEP13 = "pinion_step13",
    PINION_HEAVENS_1 = "pinion_heavens_1",
    PINION_HEAVENS_2 = "pinion_heavens_2",
    PINION_HEAVENS_3 = "pinion_heavens_3",
    PINION_HEAVENS_4 = "pinion_heavens_4",
    PINION_HEAVENS_5 = "pinion_heavens_5",
    PINION_HEAVENS_6 = "pinion_heavens_6",
    PINION_HEAVENS_7 = "pinion_heavens_7",
    DUSKWIRE_STEP1 = "duskwire_step1",
    DUSKWIRE_STEP2 = "duskwire_step2",
    DUSKWIRE_STEP3 = "duskwire_step3",
    TRYHARD_STEP1 = "tryhard_step1",
    TRYHARD_STEP2 = "tryhard_step2",
    AUTO_SELL = "auto_sell",
}

local PINION_HEAVENS_MODE_LIST = {
    MODES.PINION_HEAVENS_1,
    MODES.PINION_HEAVENS_2,
    MODES.PINION_HEAVENS_3,
    MODES.PINION_HEAVENS_4,
    MODES.PINION_HEAVENS_5,
    MODES.PINION_HEAVENS_7,
}

local INITIAL_FARM_PHASE = {
    CARROT = "carrot",
    XP = "xp",
}

local FARM_TARGETS = {
    [INITIAL_FARM_PHASE.CARROT] = CFrame.new(FISHING_SPOT) * CFrame.Angles(0, FACE_YAW, 0),
    [INITIAL_FARM_PHASE.XP] = CFrame.new(XP_FARM_SPOT) * CFrame.Angles(0, XP_FACE_YAW, 0),
}

local TELEPORT_TARGETS = {
    [MODES.XP_FARM] = CFrame.new(XP_FARM_SPOT) * CFrame.Angles(0, XP_FACE_YAW, 0),
    [MODES.ENCHANT] = CFrame.new(ENCHANT_ALTAR_SPOT),
    [MODES.RELIC] = CFrame.new(ENCHANT_RELIC_SHOP_SPOT),
    [MODES.OSCAR_STEP1] = CFrame.new(POST_XP_NPC_SPOT),
    [MODES.OSCAR_STEP2] = CFrame.new(POST_XP_MISSION_OBJECT_SPOT),
    [MODES.OSCAR_STEP3] = CFrame.new(OSCAR_ROD_SHOP_SPOT),
    [MODES.PINION_STEP1] = CFrame.new(PINION_VERTIGO_UNLOCK_SPOT),
    [MODES.PINION_STEP4] = CFrame.new(PINION_DEPTHS_KEY_SPOT),
    [MODES.PINION_STEP5] = CFrame.new(PINION_ENCHANT_RELIC_SPOT),
    [MODES.PINION_STEP6] = CFrame.new(PINION_STEP6_SPOT),
    [MODES.PINION_STEP7] = CFrame.new(PINION_STEP7_SPOT),
    [MODES.PINION_STEP8] = CFrame.new(PINION_STEP6_SPOT),
    [MODES.PINION_STEP9] = CFrame.new(PINION_STEP9_SPOT),
    [MODES.PINION_STEP10] = CFrame.new(PINION_HEAVENLY_DOVE_SPOT),
    [MODES.PINION_STEP11] = CFrame.new(PINION_STEP6_SPOT),
    [MODES.PINION_STEP12] = CFrame.new(PINION_POST_QUEST_FISH_SPOT),
    [MODES.PINION_STEP13] = CFrame.new(PINION_STEP6_SPOT),
    [MODES.DUSKWIRE_STEP1] = CFrame.new(DUSKWIRE_STEP1_SPOT),
    [MODES.DUSKWIRE_STEP2] = CFrame.new(DUSKWIRE_STEP2_SPOT),
    [MODES.DUSKWIRE_STEP3] = CFrame.new(DUSKWIRE_STEP1_SPOT),
    [MODES.TRYHARD_STEP1] = CFrame.new(TRYHARD_STEP1_SPOT),
    [MODES.TRYHARD_STEP2] = CFrame.new(TRYHARD_STEP2_SPOT),
    [MODES.PINION_HEAVENS_1] = CFrame.new(PINION_HEAVENS_ROD_SPOTS[1]),
    [MODES.PINION_HEAVENS_2] = CFrame.new(PINION_HEAVENS_ROD_SPOTS[2]),
    [MODES.PINION_HEAVENS_3] = CFrame.new(PINION_HEAVENS_ROD_SPOTS[3]),
    [MODES.PINION_HEAVENS_4] = CFrame.new(PINION_HEAVENS_ROD_SPOTS[4]),
    [MODES.PINION_HEAVENS_5] = CFrame.new(PINION_HEAVENS_ROD_SPOTS[5]),
    [MODES.PINION_HEAVENS_7] = CFrame.new(PINION_HEAVENS_ROD_SPOTS[6]),
    [MODES.PINION_HEAVENS_6] = CFrame.new(PINION_HEAVENS_FINAL_SPOT),
}

local TELEPORT_MODE_LABELS = {
    [MODES.XP_FARM] = "Farm XP",
    [MODES.PINION_STEP1] = "Pinion Aria P1",
    [MODES.PINION_STEP4] = "Pinion Aria P4 — Depths Key",
    [MODES.PINION_STEP5] = "Pinion Aria P5 — Enchant Relic",
    [MODES.PINION_STEP6] = "Pinion Aria P6",
    [MODES.PINION_STEP7] = "Pinion Aria P7 — Pescar Dj Spinous",
    [MODES.PINION_STEP8] = "Pinion Aria P8 — Voltar quest Dj Spinous",
    [MODES.PINION_STEP9] = "Pinion Aria P9",
    [MODES.PINION_HEAVENS_1] = "Pinion P10.1 — Heaven's Rod",
    [MODES.PINION_HEAVENS_2] = "Pinion P10.2 — Heaven's Rod",
    [MODES.PINION_HEAVENS_3] = "Pinion P10.3 — Heaven's Rod",
    [MODES.PINION_HEAVENS_4] = "Pinion P10.4 — Heaven's Rod",
    [MODES.PINION_HEAVENS_5] = "Pinion P10.5.5 — Heaven's Rod",
    [MODES.PINION_HEAVENS_7] = "Pinion P10.5.6 — Heaven's Rod",
    [MODES.PINION_HEAVENS_6] = "Pinion P10.6 — Heaven's Rod final",
    [MODES.PINION_STEP10] = "Pinion Aria P11 — Heavenly Harmonic Dove",
    [MODES.PINION_STEP11] = "Pinion Aria P12 — Quest Dj Spinous",
    [MODES.PINION_STEP12] = "Pinion Aria P13 — Pescar Dj Spinous",
    [MODES.PINION_STEP13] = "Pinion Aria P14 — Voltar quest Dj Spinous",
    [MODES.DUSKWIRE_STEP1] = "Duskwire Rod P1 — Obter quest",
    [MODES.DUSKWIRE_STEP2] = "Duskwire Rod P2 — Pescar Catfish",
    [MODES.DUSKWIRE_STEP3] = "Duskwire Rod P3 — Entregar missão",
    [MODES.TRYHARD_STEP1] = "TryHard Rod P1 — Obter quest",
    [MODES.TRYHARD_STEP2] = "TryHard Rod P2 — Ir à pesca",
    [MODES.ENCHANT] = "Enchant (Altar)",
    [MODES.RELIC] = "Comprar Relíquia",
}

-- ===== Utilitários =====
local function trackConnection(conn)
    table.insert(connections, conn)
end

local function silentInvoke(remote, ...)
    local args = table.pack(...)
    return pcall(function()
        remote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local characterCache = { value = nil, expires = 0 }
local hrpCache = { part = nil, expires = 0 }

local function refreshCharacter()
    local now = tick()
    if characterCache.expires > now and characterCache.value and characterCache.value.Parent then
        CHARACTER = characterCache.value
        return CHARACTER
    end
    CHARACTER = PLAYER.Character or PLAYER.CharacterAdded:Wait()
    characterCache.value = CHARACTER
    characterCache.expires = now + CHARACTER_CACHE_TTL
    return CHARACTER
end

local function getHumanoidRootPart()
    local now = tick()
    if hrpCache.expires > now and hrpCache.part and hrpCache.part.Parent then
        return hrpCache.part
    end
    local char = refreshCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrpCache.part = hrp
        hrpCache.expires = now + HRP_CACHE_TTL
    end
    return hrp
end

local function forEachGuiNode(root, visitor, maxDepth, depth)
    if not root then return end
    maxDepth = maxDepth or UI_SCAN_MAX_DEPTH
    depth = depth or 0
    if depth > maxDepth then return end
    if visitor(root, depth) == false then return end
    for _, child in ipairs(root:GetChildren()) do
        forEachGuiNode(child, visitor, maxDepth, depth + 1)
    end
end

-- Caches compartilhados entre blocos core (core1/core2/core3)
local playerLevelCache = { value = nil, expires = 0 }
local playerCoinsCache = { value = nil, expires = 0 }
local amuletCache = { value = nil, expires = 0 }
local isonadeCache = { value = nil, expires = 0 }
local bestiaryCache = { value = nil, expires = 0 }
local bestiaryInstanceCache = { node = nil, expires = 0 }
local vertigoBestiaryCache = { value = nil, expires = 0 }
local vertigoInstanceCache = { node = nil, expires = 0 }
local farmStrategyCache = { rod = nil, expires = 0 }
local RodCache = {
    ui = { names = {}, expires = 0 },
    ownership = { values = {}, expires = 0 },
    bestOwned = { name = nil, expires = 0 },
}
local hudContainersCache = { list = {}, expires = 0 }
local rodInteractableCache = {}

do -- core1a_format

local function formatCoins(amount)
    amount = tonumber(amount)
    if amount == nil then return "?" end
    local n = math.floor(amount)
    local formatted = tostring(n)
    while true do
        local nextFormatted, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        formatted = nextFormatted
        if count == 0.0 then break end
    end
    return formatted
end

local function formatPercent(value)
    value = tonumber(value)
    if not value then return "?" end
    if math.abs(value - math.floor(value)) < 0.01 then
        return tostring(math.floor(value))
    end
    return string.format("%.1f", value)
end

local function isOscarRodName(name)
    if not name or name == "" then return false end
    if name == OSCAR_ROD_NAME then return true end
    local lowered = string.lower(name)
    return lowered:find("great rod of oscar", 1, true) ~= nil
        or (lowered:find("oscar", 1, true) and lowered:find("rod", 1, true))
end

Nav.formatCoins = formatCoins
Nav.formatPercent = formatPercent
Nav.isOscarRodName = isOscarRodName

end -- core1a_format

do -- core1a_stats

local function getPlayerLevel()
    local now = tick()
    if now < playerLevelCache.expires then
        return playerLevelCache.value
    end

    local leaderstats = PLAYER:FindFirstChild("leaderstats")
    if leaderstats then
        local levelStat = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("level")
        if levelStat and typeof(levelStat.Value) == "number" then
            playerLevelCache.value = math.floor(levelStat.Value)
            playerLevelCache.expires = now + LEVEL_CACHE_TTL
            return playerLevelCache.value
        end
    end

    local playerStats = ReplicatedStorage:FindFirstChild("playerstats")
    if playerStats then
        local data = playerStats:FindFirstChild(PLAYER.Name)
        local stats = data and data:FindFirstChild("Stats")
        local levelStat = stats and (stats:FindFirstChild("Level") or stats:FindFirstChild("level"))
        if levelStat and typeof(levelStat.Value) == "number" then
            playerLevelCache.value = math.floor(levelStat.Value)
            playerLevelCache.expires = now + LEVEL_CACHE_TTL
            return playerLevelCache.value
        end
    end

    playerLevelCache.value = nil
    playerLevelCache.expires = now + LEVEL_CACHE_TTL
    return nil
end

local function getPlayerCoins()
    local now = tick()
    local cacheTtl = activeMode == MODES.INITIAL_FARM and COINS_CACHE_TTL_FARM or COINS_CACHE_TTL
    if now < playerCoinsCache.expires then
        return playerCoinsCache.value
    end

    local playerStats = ReplicatedStorage:FindFirstChild("playerstats")
    if playerStats then
        local data = playerStats:FindFirstChild(PLAYER.Name)
        local stats = data and data:FindFirstChild("Stats")
        local coins = stats and stats:FindFirstChild("coins")
        if coins and typeof(coins.Value) == "number" then
            playerCoinsCache.value = coins.Value
            playerCoinsCache.expires = now + cacheTtl
            return playerCoinsCache.value
        end
    end

    local leaderstats = PLAYER:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs({ "C$", "Coins", "coins", "Cash" }) do
            local stat = leaderstats:FindFirstChild(name)
            if stat and typeof(stat.Value) == "number" then
                playerCoinsCache.value = stat.Value
                playerCoinsCache.expires = now + cacheTtl
                return playerCoinsCache.value
            end
        end
    end

    local hud = PLAYER:FindFirstChild("PlayerGui") and PLAYER.PlayerGui:FindFirstChild("hud")
    if hud and hud:FindFirstChild("safezone") then
        local coinsLabel = hud.safezone:FindFirstChild("coins")
        if coinsLabel and coinsLabel.Text then
            local parsed = tonumber(coinsLabel.Text:gsub("[^%d]", ""))
            if parsed then
                playerCoinsCache.value = parsed
                playerCoinsCache.expires = now + cacheTtl
                return playerCoinsCache.value
            end
        end
    end

    playerCoinsCache.value = nil
    playerCoinsCache.expires = now + cacheTtl
    return nil
end

Nav.getPlayerLevel = getPlayerLevel
Nav.getPlayerCoins = getPlayerCoins

end -- core1a_stats

do -- core1a_rods_ui

local function rodsMatchName(a, b)
    if not a or not b then return false end
    if a == b then return true end
    if Nav.isOscarRodName(a) and Nav.isOscarRodName(b) then return true end
    return false
end

local function rodNamesMatch(a, b)
    if not a or not b then return false end
    if a == b then return true end
    if string.lower(a) == string.lower(b) then return true end
    if Nav.isOscarRodName(a) and Nav.isOscarRodName(b) then return true end
    return false
end

local HUD_INVENTORY_NAMES = { "backpack", "equipmentbag", "equipment_bag", "equipment bag" }

local function getHudInventoryContainers()
    local now = tick()
    if now < hudContainersCache.expires and #hudContainersCache.list > 0 then
        local valid = true
        for _, inst in ipairs(hudContainersCache.list) do
            if not inst or not inst.Parent then
                valid = false
                break
            end
        end
        if valid then return hudContainersCache.list end
    end

    local containers = {}
    local seen = {}
    local function addContainer(inst)
        if inst and not seen[inst] then
            seen[inst] = true
            table.insert(containers, inst)
        end
    end
    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hud = playerGui and playerGui:FindFirstChild("hud")
    local safezone = hud and hud:FindFirstChild("safezone")
    if not safezone then
        hudContainersCache.list = containers
        hudContainersCache.expires = now + HUD_CONTAINERS_CACHE_TTL
        return containers
    end
    for _, name in ipairs(HUD_INVENTORY_NAMES) do
        addContainer(safezone:FindFirstChild(name))
    end
    for _, child in ipairs(safezone:GetChildren()) do
        local lowered = string.lower(child.Name)
        if lowered:find("backpack", 1, true) or lowered:find("equipment", 1, true) or lowered:find("bag", 1, true) then
            addContainer(child)
        end
    end
    hudContainersCache.list = containers
    hudContainersCache.expires = now + HUD_CONTAINERS_CACHE_TTL
    return containers
end

local UI_ROD_BLOCKLIST = {
    ["Rod Name"] = true, ["[Rod Name]"] = true, ["RodSkins"] = true,
    ["Rod Skins"] = true, ["AlertSkinRod"] = true, ["Enchant Rod"] = true,
    ["Fishing Rods"] = true, ["Rods"] = true, ["CurrentRod"] = true,
    ["RodImage"] = true, ["Rod Name Mastery"] = true,
}

local function invalidateRodCaches()
    RodCache.ui.expires = 0
    RodCache.ownership.expires = 0
    RodCache.bestOwned.expires = 0
    amuletCache.expires = 0
    playerCoinsCache.expires = 0
    bestiaryCache.expires = 0
    farmStrategyCache.expires = 0
    hudContainersCache.expires = 0
end

local function isRodSkinsPreview(inst)
    local current = inst
    while current and current ~= PLAYER do
        local lowered = string.lower(current.Name)
        if lowered:find("rodskin") or lowered:find("rod_skin") then return true end
        if lowered:find("skin") and lowered:find("rod") then return true end
        current = current.Parent
    end
    return false
end

local function isValidRodName(name)
    if not name or name == "" then return false end
    if UI_ROD_BLOCKLIST[name] then return false end
    if name:find("Skin") then return false end
    if name:find("Mastery") or name:find("Image") or name:find("Current") then return false end
    if not name:match(" Rod$") then return false end
    return #name:gsub(" Rod$", "") >= 2
end

Nav.rodsMatchName = rodsMatchName
Nav.rodNamesMatch = rodNamesMatch
Nav.invalidateRodCaches = invalidateRodCaches
Nav.getHudInventoryContainers = getHudInventoryContainers
Nav.isRodSkinsPreview = isRodSkinsPreview
Nav.isValidRodName = isValidRodName

end -- core1a_rods_ui

do -- core1a_rods_find

local function findRodToolByName(name)
    if name == OSCAR_ROD_NAME or Nav.isOscarRodName(name) then
        for _, alias in ipairs(OSCAR_ROD_ALIASES) do
            local char = refreshCharacter()
            local rod = char:FindFirstChild(alias)
            if rod and rod:IsA("Tool") then return rod end
            rod = PLAYER.Backpack:FindFirstChild(alias)
            if rod and rod:IsA("Tool") then return rod end
        end
    end
    local char = refreshCharacter()
    local rod = char:FindFirstChild(name)
    if rod and rod:IsA("Tool") then return rod end
    rod = PLAYER.Backpack:FindFirstChild(name)
    if rod and rod:IsA("Tool") then return rod end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item.Name == name then return item end
    end
    for _, item in ipairs(PLAYER.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name == name then return item end
    end
    return nil
end

local function findRodInPlayerStats(rodName)
    local playerStats = ReplicatedStorage:FindFirstChild("playerstats")
    if not playerStats then return false end
    for _, data in ipairs({
        playerStats:FindFirstChild(PLAYER.Name),
        playerStats:FindFirstChild(tostring(PLAYER.UserId)),
    }) do
        if data then
            local rods = data:FindFirstChild("Rods") or data:FindFirstChild("rods")
            if rods then
                if rods:FindFirstChild(rodName) then return true end
                for _, child in ipairs(rods:GetChildren()) do
                    if child.Name == rodName then return true end
                    if child:IsA("StringValue") and child.Value == rodName then return true end
                end
            end
        end
    end
    return false
end

local function scanOwnedRodsFromUi()
    local owned, seen = {}, {}
    local function consider(desc)
        if Nav.isRodSkinsPreview(desc) then return end
        local candidates = {}
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            table.insert(candidates, desc.Text)
        end
        table.insert(candidates, desc.Name)
        for _, candidate in ipairs(candidates) do
            if Nav.isValidRodName(candidate) and not seen[candidate] then
                seen[candidate] = true
                table.insert(owned, Nav.isOscarRodName(candidate) and OSCAR_ROD_NAME or candidate)
            end
        end
    end
    for _, container in ipairs(Nav.getHudInventoryContainers()) do
        forEachGuiNode(container, consider)
    end
    return owned
end

local function getUiOwnedRods()
    if tick() < RodCache.ui.expires then return RodCache.ui.names end
    local cacheTtl = activeMode == MODES.INITIAL_FARM and OWNED_ROD_CACHE_TTL_FARM or OWNED_ROD_CACHE_TTL
    RodCache.ui.names = scanOwnedRodsFromUi()
    RodCache.ui.expires = tick() + cacheTtl
    return RodCache.ui.names
end

Nav.findRodToolByName = findRodToolByName
Nav.findRodInPlayerStats = findRodInPlayerStats
Nav.getUiOwnedRods = getUiOwnedRods

end -- core1a_rods_find

do -- core1a_rods_oscar

local function findOscarRod()
    for _, alias in ipairs(OSCAR_ROD_ALIASES) do
        local tool = Nav.findRodToolByName(alias)
        if tool then return tool end
    end
    return nil
end

local function findOscarRodInHudInventory()
    local found = false
    local function consider(desc)
        if found or Nav.isRodSkinsPreview(desc) then return end
        local candidates = {}
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            table.insert(candidates, desc.Text)
        end
        table.insert(candidates, desc.Name)
        for _, candidate in ipairs(candidates) do
            if Nav.isOscarRodName(candidate) then
                found = true
                return false
            end
        end
    end
    for _, container in ipairs(Nav.getHudInventoryContainers()) do
        forEachGuiNode(container, consider)
        if found then return true end
    end
    return false
end

local function findOscarRodInPlayerStats()
    for _, alias in ipairs(OSCAR_ROD_ALIASES) do
        if Nav.findRodInPlayerStats(alias) then return true end
    end
    local playerStats = ReplicatedStorage:FindFirstChild("playerstats")
    if not playerStats then return false end
    for _, data in ipairs({
        playerStats:FindFirstChild(PLAYER.Name),
        playerStats:FindFirstChild(tostring(PLAYER.UserId)),
    }) do
        if not data then continue end
        local rods = data:FindFirstChild("Rods") or data:FindFirstChild("rods")
        if not rods then continue end
        for _, child in ipairs(rods:GetChildren()) do
            if Nav.isOscarRodName(child.Name) then return true end
            if child:IsA("StringValue") and Nav.isOscarRodName(child.Value) then return true end
        end
    end
    return false
end

local function scanOscarRodOwnership()
    if findOscarRod() then return true end
    if findOscarRodInHudInventory() then return true end
    if findOscarRodInPlayerStats() then return true end
    for _, name in ipairs(Nav.getUiOwnedRods()) do
        if Nav.isOscarRodName(name) then return true end
    end
    return false
end

local function refreshOwnershipCache()
    local now = tick()
    local cacheTtl = activeMode == MODES.INITIAL_FARM and OWNED_ROD_CACHE_TTL_FARM or OWNED_ROD_CACHE_TTL
    if now < RodCache.ownership.expires then return end

    local values = {}
    local oscarOwned = findOscarRod() or findOscarRodInPlayerStats()

    for _, rod in ipairs(ROD_PURCHASE_QUEUE) do
        if Nav.findRodToolByName(rod.name) or Nav.findRodInPlayerStats(rod.name) then
            values[rod.name] = true
        end
    end
    for _, name in ipairs(ROD_EQUIP_PRIORITY) do
        if Nav.findRodToolByName(name) or Nav.findRodInPlayerStats(name) then
            values[name] = true
        end
    end

    for _, name in ipairs(Nav.getUiOwnedRods()) do
        values[name] = true
        if Nav.isOscarRodName(name) then oscarOwned = true end
        for _, rod in ipairs(ROD_PURCHASE_QUEUE) do
            if Nav.rodNamesMatch(name, rod.name) then values[rod.name] = true end
        end
    end

    if not oscarOwned then
        oscarOwned = findOscarRodInHudInventory()
    end
    if oscarOwned then
        values[OSCAR_ROD_NAME] = true
    end

    RodCache.ownership.values = values
    RodCache.ownership.expires = now + cacheTtl
end

local function ownsOscarRod()
    refreshOwnershipCache()
    if RodCache.ownership.values[OSCAR_ROD_NAME] then return true end
    for key, owned in pairs(RodCache.ownership.values) do
        if owned and Nav.isOscarRodName(key) then return true end
    end
    return false
end

Nav.findOscarRod = findOscarRod
Nav.scanOscarRodOwnership = scanOscarRodOwnership
Nav.refreshOwnershipCache = refreshOwnershipCache
Nav.ownsOscarRod = ownsOscarRod

end -- core1a_rods_oscar

do -- core1a_own

local function findToolByName(name)
    return Nav.findRodToolByName(name)
end

ownsRod = function(rodName, bypassCache)
    if not rodName then return false end
    if Nav.isOscarRodName(rodName) then
        if bypassCache then return Nav.scanOscarRodOwnership() end
        Nav.refreshOwnershipCache()
        if RodCache.ownership.values[OSCAR_ROD_NAME] then return true end
        for key, owned in pairs(RodCache.ownership.values) do
            if owned and Nav.isOscarRodName(key) then return true end
        end
        return false
    end
    if not bypassCache then
        Nav.refreshOwnershipCache()
        if RodCache.ownership.values[rodName] then return true end
        for key, owned in pairs(RodCache.ownership.values) do
            if owned and Nav.rodNamesMatch(key, rodName) then return true end
        end
        return false
    end
    if Nav.findRodToolByName(rodName) then return true end
    if Nav.findRodInPlayerStats(rodName) then return true end
    for _, name in ipairs(Nav.getUiOwnedRods()) do
        if Nav.rodNamesMatch(name, rodName) then return true end
    end
    return false
end

local function ownsRodFresh(rodName)
    return ownsRod(rodName, true)
end

local function rodPurchasedForQueue(rodName)
    return ownsRod(rodName) or Nav.findRodInPlayerStats(rodName)
end

local function hasAmulet()
    local now = tick()
    if now < amuletCache.expires then
        return amuletCache.value
    end
    amuletCache.value = findToolByName(POST_XP_AMULET_NAME) ~= nil
    amuletCache.expires = now + AMULET_CACHE_TTL
    return amuletCache.value
end

local function hasIsonade()
    local now = tick()
    if now < isonadeCache.expires then
        return isonadeCache.value
    end
    isonadeCache.value = findToolByName(PINION_ISONADE_NAME) ~= nil
    isonadeCache.expires = now + AMULET_CACHE_TTL
    return isonadeCache.value
end

local function getNextRodToBuy()
    for _, rod in ipairs(ROD_PURCHASE_QUEUE) do
        if not rodPurchasedForQueue(rod.name) then return rod end
    end
    return nil
end

local function getBestOwnedRodName()
    local now = tick()
    if now < RodCache.bestOwned.expires and RodCache.bestOwned.name then
        return RodCache.bestOwned.name
    end
    if Nav.ownsOscarRod() then
        RodCache.bestOwned.name = OSCAR_ROD_NAME
        RodCache.bestOwned.expires = now + OWNED_ROD_CACHE_TTL
        return OSCAR_ROD_NAME
    end
    for _, name in ipairs(ROD_EQUIP_PRIORITY) do
        if Nav.isOscarRodName(name) then continue end
        if ownsRod(name) then
            RodCache.bestOwned.name = name
            RodCache.bestOwned.expires = now + OWNED_ROD_CACHE_TTL
            return name
        end
    end
    for _, name in ipairs(Nav.getUiOwnedRods()) do
        if ownsRod(name) and name ~= "Lucky Rod" and name ~= "Training Rod" then
            RodCache.bestOwned.name = name
            RodCache.bestOwned.expires = now + OWNED_ROD_CACHE_TTL
            return name
        end
    end
    if ownsRod(FALLBACK_ROD) then
        RodCache.bestOwned.name = FALLBACK_ROD
        RodCache.bestOwned.expires = now + OWNED_ROD_CACHE_TTL
        return FALLBACK_ROD
    end
    return FALLBACK_ROD
end

Nav.ownsRod = ownsRod
Nav.ownsRodFresh = ownsRodFresh
Nav.rodPurchasedForQueue = rodPurchasedForQueue
Nav.hasAmulet = hasAmulet
Nav.hasIsonade = hasIsonade
Nav.getNextRodToBuy = getNextRodToBuy
Nav.getBestOwnedRodName = getBestOwnedRodName

end -- core1a_own

do -- core1b_util

local function nameMatchesCarrotGarden(name)
    local lowered = string.lower(tostring(name or ""))
    return lowered:find("carrot", 1, true) and lowered:find("garden", 1, true)
end

local function nameMatchesVertigo(name)
    local lowered = string.lower(tostring(name or ""))
    return lowered:find("vertigo", 1, true) ~= nil
end

local function percentFromNumber(value)
    if typeof(value) ~= "number" then return nil end
    if value >= 0 and value <= 1 then return value * 100 end
    if value >= 0 and value <= 100 then return value end
    return nil
end

local function parsePercentText(text)
    local value = tostring(text or ""):match("(%d+%.?%d*)%s*%%")
    if not value then return nil end
    return percentFromNumber(tonumber(value))
end

local function getMainBestiaryGui()
    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hud = playerGui and playerGui:FindFirstChild("hud")
    local safezone = hud and hud:FindFirstChild("safezone")
    return safezone and safezone:FindFirstChild("bestiary")
end

local function summarizeBestiaryInstance(node)
    if not node then return nil end

    local progressResult = nil
    forEachGuiNode(node, function(desc)
        if progressResult then return false end
        if desc:IsA("NumberValue") or desc:IsA("IntValue") then
            local lowered = string.lower(desc.Name)
            if lowered:find("progress", 1, true)
                or lowered:find("percent", 1, true)
                or lowered:find("completion", 1, true)
            then
                local percent = percentFromNumber(desc.Value)
                if percent then
                    progressResult = { percent = percent, source = node.Name }
                    return false
                end
            end
        end
    end, 10)

    if progressResult then return progressResult end

    local total, done = 0, 0
    for _, entry in ipairs(node:GetChildren()) do
        if entry:IsA("Folder") or entry:IsA("Configuration") then
            local hasFlag, completed = false, false
            forEachGuiNode(entry, function(desc)
                if hasFlag and completed then return false end
                local lowered = string.lower(desc.Name)
                local relevant = lowered:find("caught", 1, true)
                    or lowered:find("discover", 1, true)
                    or lowered:find("unlock", 1, true)
                    or lowered:find("owned", 1, true)
                if relevant and (desc:IsA("BoolValue") or desc:IsA("NumberValue") or desc:IsA("IntValue")) then
                    hasFlag = true
                    completed = completed or desc.Value == true or tonumber(desc.Value) == 1
                end
            end, 6)
            if hasFlag then
                total += 1
                if completed then done += 1 end
            end
        end
    end

    if total > 0 then
        return {
            percent = done / total * 100,
            done = done,
            total = total,
            source = node.Name,
        }
    end

    return nil
end

local function getGuiRelativePath(inst, root)
    local parts = {}
    local current = inst
    while current and current ~= root and current ~= PLAYER do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, ".")
end

Nav.nameMatchesCarrotGarden = nameMatchesCarrotGarden
Nav.nameMatchesVertigo = nameMatchesVertigo
Nav.parsePercentText = parsePercentText
Nav.getMainBestiaryGui = getMainBestiaryGui
Nav.getGuiRelativePath = getGuiRelativePath
Nav.summarizeBestiaryInstance = summarizeBestiaryInstance

end -- core1b_util

do -- core1b_carrot

local function findCarrotGardenBestiaryInstance()
    local now = tick()
    if now < bestiaryInstanceCache.expires and bestiaryInstanceCache.node and bestiaryInstanceCache.node.Parent then
        return bestiaryInstanceCache.node
    end

    local playerStats = ReplicatedStorage:FindFirstChild("playerstats")
    local data = playerStats and (
        playerStats:FindFirstChild(PLAYER.Name)
        or playerStats:FindFirstChild(tostring(PLAYER.UserId))
    )
    if not data then return nil end

    local queue = { data }
    local head = 1
    while head <= #queue do
        local node = queue[head]
        head += 1
        if Nav.nameMatchesCarrotGarden(node.Name) then
            bestiaryInstanceCache.node = node
            bestiaryInstanceCache.expires = now + BESTIARY_CACHE_TTL
            return node
        end
        for _, child in ipairs(node:GetChildren()) do
            table.insert(queue, child)
        end
    end

    return nil
end

local function getCarrotGardenBestiaryProgressFromUi()
    local bestiary = Nav.getMainBestiaryGui()
    if not bestiary then return nil end
    if bestiary:IsA("GuiObject") and not bestiary.Visible then return nil end

    local hasCarrotGardenContext = false
    local hasCarrotFish = false
    local bestCandidate = nil

    forEachGuiNode(bestiary, function(desc)
        if not (desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")) then return end

        local text = desc.Text or ""
        local loweredText = string.lower(text)
        local loweredName = string.lower(desc.Name)

        if loweredText:find("carrot garden", 1, true)
            or loweredName:find("carrot garden", 1, true)
        then
            hasCarrotGardenContext = true
        end

        if loweredText:find("carrot", 1, true) then
            hasCarrotFish = true
        end

        local percent = Nav.parsePercentText(text)
        if percent then
            local loweredPath = string.lower(Nav.getGuiRelativePath(desc, bestiary))
            local score = 0
            if loweredName:find("percent", 1, true) then score += 3 end
            if loweredPath:find(".fish.percent", 1, true) then score += 5 end
            if loweredPath:find("timeevent", 1, true) then score -= 10 end
            if loweredPath:find("carrot garden", 1, true) then score += 8 end

            if not bestCandidate or score > bestCandidate.score then
                bestCandidate = {
                    percent = percent,
                    source = loweredPath,
                    score = score,
                }
            end
        end
    end, BESTIARY_UI_SCAN_DEPTH)

    if not (hasCarrotGardenContext or hasCarrotFish) then
        return nil
    end

    if bestCandidate then
        bestCandidate.score = nil
        return bestCandidate
    end

    return nil
end

local function getCarrotGardenBestiaryProgress(bypassCache)
    local now = tick()
    if not bypassCache and now < bestiaryCache.expires then
        return bestiaryCache.value
    end

    local uiSummary = getCarrotGardenBestiaryProgressFromUi()
    if uiSummary then
        bestiaryCache.value = uiSummary
        bestiaryCache.expires = now + BESTIARY_CACHE_TTL
        return uiSummary
    end

    local summary = Nav.summarizeBestiaryInstance(findCarrotGardenBestiaryInstance())
    if summary then
        bestiaryCache.value = summary
        bestiaryCache.expires = now + BESTIARY_CACHE_TTL
        return summary
    end

    bestiaryCache.value = nil
    bestiaryCache.expires = now + math.min(BESTIARY_CACHE_TTL, 10)
    return nil
end

local function isCarrotGardenComplete()
    local progress = getCarrotGardenBestiaryProgress()
    return progress ~= nil and (progress.percent or 0) >= 100
end

Nav.findCarrotGardenBestiaryInstance = findCarrotGardenBestiaryInstance
Nav.getCarrotGardenBestiaryProgressFromUi = getCarrotGardenBestiaryProgressFromUi
Nav.getCarrotGardenBestiaryProgress = getCarrotGardenBestiaryProgress
Nav.isCarrotGardenComplete = isCarrotGardenComplete

end -- core1b_carrot

do -- core1b_vertigo

local function findVertigoBestiaryInstance()
    local now = tick()
    if now < vertigoInstanceCache.expires and vertigoInstanceCache.node and vertigoInstanceCache.node.Parent then
        return vertigoInstanceCache.node
    end

    local playerStats = ReplicatedStorage:FindFirstChild("playerstats")
    local data = playerStats and (
        playerStats:FindFirstChild(PLAYER.Name)
        or playerStats:FindFirstChild(tostring(PLAYER.UserId))
    )
    if not data then return nil end

    local queue = { data }
    local head = 1
    while head <= #queue do
        local node = queue[head]
        head += 1
        if Nav.nameMatchesVertigo(node.Name) then
            vertigoInstanceCache.node = node
            vertigoInstanceCache.expires = now + BESTIARY_CACHE_TTL
            return node
        end
        for _, child in ipairs(node:GetChildren()) do
            table.insert(queue, child)
        end
    end

    return nil
end

local function getVertigoBestiaryProgressFromUi()
    local bestiary = Nav.getMainBestiaryGui()
    if not bestiary then return nil end
    if bestiary:IsA("GuiObject") and not bestiary.Visible then return nil end

    local hasVertigoContext = false
    local bestCandidate = nil

    forEachGuiNode(bestiary, function(desc)
        if not (desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")) then return end

        local text = desc.Text or ""
        local loweredText = string.lower(text)
        local loweredName = string.lower(desc.Name)

        if loweredText:find("vertigo", 1, true) or loweredName:find("vertigo", 1, true) then
            hasVertigoContext = true
        end

        local percent = Nav.parsePercentText(text)
        if percent then
            local loweredPath = string.lower(Nav.getGuiRelativePath(desc, bestiary))
            local score = 0
            if loweredName:find("percent", 1, true) then score += 3 end
            if loweredPath:find(".fish.percent", 1, true) then score += 5 end
            if loweredPath:find("timeevent", 1, true) then score -= 10 end
            if loweredPath:find("vertigo", 1, true) then score += 8 end

            if not bestCandidate or score > bestCandidate.score then
                bestCandidate = {
                    percent = percent,
                    source = loweredPath,
                    score = score,
                }
            end
        end
    end, BESTIARY_UI_SCAN_DEPTH)

    if not hasVertigoContext then
        return nil
    end

    if bestCandidate then
        bestCandidate.score = nil
        return bestCandidate
    end

    return nil
end

local function getVertigoBestiaryProgress(bypassCache)
    local now = tick()
    local bestiary = Nav.getMainBestiaryGui()
    local uiVisible = bestiary and bestiary:IsA("GuiObject") and bestiary.Visible

    if not bypassCache and not uiVisible and now < vertigoBestiaryCache.expires then
        return vertigoBestiaryCache.value
    end

    local uiSummary = getVertigoBestiaryProgressFromUi()
    if uiSummary then
        vertigoBestiaryCache.value = uiSummary
        vertigoBestiaryCache.expires = now + BESTIARY_CACHE_TTL
        return uiSummary
    end

    local summary = Nav.summarizeBestiaryInstance(findVertigoBestiaryInstance())
    if summary then
        vertigoBestiaryCache.value = summary
        vertigoBestiaryCache.expires = now + BESTIARY_CACHE_TTL
        return summary
    end

    vertigoBestiaryCache.value = nil
    vertigoBestiaryCache.expires = now + math.min(BESTIARY_CACHE_TTL, 10)
    return nil
end

local function isVertigoBestiaryComplete()
    local progress = getVertigoBestiaryProgress()
    return progress ~= nil and (progress.percent or 0) >= 100
end

Nav.findVertigoBestiaryInstance = findVertigoBestiaryInstance
Nav.getVertigoBestiaryProgressFromUi = getVertigoBestiaryProgressFromUi
Nav.getVertigoBestiaryProgress = getVertigoBestiaryProgress
Nav.isVertigoBestiaryComplete = isVertigoBestiaryComplete

end -- core1b_vertigo

do -- core1b_farm

local function shouldUseLuckyRodForBestiary()
    if not Nav.ownsRod("Lucky Rod") then return false end
    if Nav.ownsRod("Carrot Rod") then return false end

    local coins = Nav.getPlayerCoins()
    if not coins or coins < CARROT_ROD_PRICE then return false end

    return not Nav.isCarrotGardenComplete()
end

local function getPreferredFarmRodName()
    if activeMode == MODES.INITIAL_FARM and initialFarmPhase == INITIAL_FARM_PHASE.XP then
        return Nav.getBestOwnedRodName()
    end

    local now = tick()
    if now < farmStrategyCache.expires and farmStrategyCache.rod then
        return farmStrategyCache.rod
    end

    local preferred
    if shouldUseLuckyRodForBestiary() then
        preferred = "Lucky Rod"
    elseif Nav.ownsRod("Rapid Rod") then
        preferred = "Rapid Rod"
    elseif Nav.ownsRod("Fast Rod") then
        preferred = "Fast Rod"
    else
        preferred = Nav.getBestOwnedRodName()
    end

    farmStrategyCache.rod = preferred
    farmStrategyCache.expires = now + FARM_STRATEGY_CACHE_TTL
    return preferred
end

local function resolvePreferredRodName(explicitName)
    if explicitName then return explicitName end
    if activeMode == MODES.INITIAL_FARM and initialFarmPhase == INITIAL_FARM_PHASE.CARROT then
        return getPreferredFarmRodName()
    end
    return Nav.getBestOwnedRodName()
end

Nav.shouldUseLuckyRodForBestiary = shouldUseLuckyRodForBestiary
Nav.getPreferredFarmRodName = getPreferredFarmRodName
Nav.resolvePreferredRodName = resolvePreferredRodName

end -- core1b_farm

do -- core1b_avail

local function getCarrotRodAvailability()
    if Nav.ownsRod("Carrot Rod") then
        return { ready = true, label = "Carrot Rod obtida!", color = Color3.fromRGB(120, 200, 120) }
    end

    local nextRod = Nav.getNextRodToBuy()
    if nextRod and nextRod.name ~= "Carrot Rod" then
        local coins = Nav.getPlayerCoins()
        local missing = coins and math.max(nextRod.price - coins, 0) or nextRod.price
        return {
            ready = false,
            label = string.format("Compre antes: %s (falta C$%s)", nextRod.name, Nav.formatCoins(missing)),
            color = Color3.fromRGB(220, 170, 80),
        }
    end

    local coins = Nav.getPlayerCoins()
    local progress = Nav.getCarrotGardenBestiaryProgress()
    local bestiaryOk = progress and (progress.percent or 0) >= 100
    local coinsOk = coins and coins >= CARROT_ROD_PRICE

    local parts = {}
    if progress then
        table.insert(parts, string.format("Bestiary: %s%%", Nav.formatPercent(progress.percent)))
        if not bestiaryOk then
            table.insert(parts, string.format("(falta %s%%)", Nav.formatPercent(100 - progress.percent)))
        end
    else
        table.insert(parts, "Bestiary: ?")
    end

    if coinsOk then
        table.insert(parts, string.format("C$: OK (%s)", Nav.formatCoins(coins)))
    else
        local missing = coins and math.max(CARROT_ROD_PRICE - coins, 0) or CARROT_ROD_PRICE
        table.insert(parts, string.format("C$: falta %s", Nav.formatCoins(missing)))
    end

    if Nav.shouldUseLuckyRodForBestiary() then
        table.insert(parts, "Vara: Lucky Rod (bestiary)")
    elseif bestiaryOk and not coinsOk and Nav.ownsRod("Rapid Rod") then
        table.insert(parts, "Vara: Rapid Rod (farm C$)")
    end

    local ready = bestiaryOk and coinsOk
    return {
        ready = ready,
        label = table.concat(parts, " | "),
        color = ready and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(220, 170, 80),
    }
end

local function getRelicAvailability()
    local level = Nav.getPlayerLevel()
    local coins = Nav.getPlayerCoins()
    local levelOk = level and level >= ENCHANT_RELIC_MIN_LEVEL
    local coinsOk = coins and coins >= ENCHANT_RELIC_PRICE

    local parts = {}
    if levelOk then
        table.insert(parts, string.format("Lv: OK (%d)", level))
    else
        local missing = level and math.max(ENCHANT_RELIC_MIN_LEVEL - level, 0) or ENCHANT_RELIC_MIN_LEVEL
        table.insert(parts, string.format("Lv: falta %d (req %d)", missing, ENCHANT_RELIC_MIN_LEVEL))
    end

    if coinsOk then
        table.insert(parts, string.format("C$: OK (%s)", Nav.formatCoins(coins)))
    else
        local missing = coins and math.max(ENCHANT_RELIC_PRICE - coins, 0) or ENCHANT_RELIC_PRICE
        table.insert(parts, string.format("C$: falta %s (req %s)", Nav.formatCoins(missing), Nav.formatCoins(ENCHANT_RELIC_PRICE)))
    end

    return {
        ready = levelOk and coinsOk,
        label = table.concat(parts, " | "),
        color = (levelOk and coinsOk) and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(220, 170, 80),
    }
end

Nav.getCarrotRodAvailability = getCarrotRodAvailability
Nav.getRelicAvailability = getRelicAvailability

end -- core1b_avail


local questUi = {}

do -- quest_loader

local QUEST_BASE = "https://raw.githubusercontent.com/Snowyno/scriptfarm/refs/heads/main"
local QUEST_URLS = {
    oscar = QUEST_BASE .. "/Oscar.lua",
    pinion = QUEST_BASE .. "/Pinion.lua",
    duskwire = QUEST_BASE .. "/Duskwire.lua",
    tryhard = QUEST_BASE .. "/TryHardRod.lua",
}

local QUEST_LOCAL_PATHS = {
    oscar = "quests/quest_oscar.lua",
    pinion = "quests/quest_pinion.lua",
    duskwire = "quests/quest_duskwire.lua",
    tryhard = "quests/quest_tryhard.lua",
}

local function questHttpGet(url)
    if type(url) ~= "string" or url == "" then return nil end
    if syn and syn.request then
        local res = syn.request({ Url = url, Method = "GET" })
        if res and res.Body then return res.Body end
    end
    if http and http.request then
        local res = http.request({ Url = url, Method = "GET" })
        if res and res.Body then return res.Body end
    end
    if game and type(game.HttpGet) == "function" then
        return game:HttpGet(url)
    end
    if HttpService then
        return HttpService:GetAsync(url)
    end
    return nil
end

local function fetchQuestSource(name)
    local url = QUEST_URLS[name]
    if url and url ~= "" then
        local body = questHttpGet(url)
        if body then return body, url end
        warn("[navegacao] Falha ao baixar quest", name, "de", url)
        return nil
    end
    local path = QUEST_LOCAL_PATHS[name]
    if type(readfile) == "function" and (not isfile or isfile(path)) then
        return readfile(path), path
    end
    warn("[navegacao] Quest", name, "indisponível (sem URL e sem arquivo local:", path, ")")
    return nil
end

local function buildQuestCtx(loadCache)
    return {
        Nav = Nav,
        S = questState,
        ui = questUi,
        C = {
            POST_XP_MIN_LEVEL = POST_XP_MIN_LEVEL,
            POST_XP_MIN_COINS = POST_XP_MIN_COINS,
            OSCAR_ROD_MIN_LEVEL = OSCAR_ROD_MIN_LEVEL,
            OSCAR_ROD_PRICE = OSCAR_ROD_PRICE,
            PINION_ARIA_MIN_LEVEL = PINION_ARIA_MIN_LEVEL,
            DUSKWIRE_ROD_MIN_LEVEL = DUSKWIRE_ROD_MIN_LEVEL,
            MODES = MODES,
            PINION_PROGRESS_CACHE_FOLDER = PINION_PROGRESS_CACHE_FOLDER,
            PINION_PROGRESS_WORKSPACE_FOLDER = PINION_PROGRESS_WORKSPACE_FOLDER,
            PINION_PROGRESS_KEYS = PINION_PROGRESS_KEYS,
            PINION_HEAVENS_PROGRESS_KEYS = PINION_HEAVENS_PROGRESS_KEYS,
            PINION_QUEST_UNDO_ORDER = PINION_QUEST_UNDO_ORDER,
            DUSKWIRE_PROGRESS_KEYS = DUSKWIRE_PROGRESS_KEYS,
            TRYHARD_PROGRESS_KEYS = TRYHARD_PROGRESS_KEYS,
            DUSKWIRE_QUEST_UNDO_ORDER = DUSKWIRE_QUEST_UNDO_ORDER,
            TRYHARD_QUEST_UNDO_ORDER = TRYHARD_QUEST_UNDO_ORDER,
            HEAVENS_STEP5_KEYS = HEAVENS_STEP5_KEYS,
            PINION_HEAVENS_MODE_LIST = PINION_HEAVENS_MODE_LIST,
            PINION_HEAVENS_ROD_SPOTS = PINION_HEAVENS_ROD_SPOTS,
            PINION_VERTIGO_UNLOCK_SPOT = PINION_VERTIGO_UNLOCK_SPOT,
            PINION_DEPTHS_KEY_SPOT = PINION_DEPTHS_KEY_SPOT,
            PINION_ENCHANT_RELIC_SPOT = PINION_ENCHANT_RELIC_SPOT,
            PINION_STEP6_SPOT = PINION_STEP6_SPOT,
            PINION_STEP7_SPOT = PINION_STEP7_SPOT,
            PINION_STEP9_SPOT = PINION_STEP9_SPOT,
            PINION_HEAVENLY_DOVE_SPOT = PINION_HEAVENLY_DOVE_SPOT,
            PINION_POST_QUEST_FISH_SPOT = PINION_POST_QUEST_FISH_SPOT,
            DUSKWIRE_STEP1_SPOT = DUSKWIRE_STEP1_SPOT,
            DUSKWIRE_STEP2_SPOT = DUSKWIRE_STEP2_SPOT,
            TRYHARD_STEP1_SPOT = TRYHARD_STEP1_SPOT,
            TRYHARD_STEP2_SPOT = TRYHARD_STEP2_SPOT,
            FALLBACK_ROD = FALLBACK_ROD,
        },
        helpers = {
            canUsePinionFileCache = canUsePinionFileCache,
            ensurePinionProgressCacheFolder = ensurePinionProgressCacheFolder,
            PINION_PROGRESS_CACHE_FOLDER = PINION_PROGRESS_CACHE_FOLDER,
        },
        PLAYER = PLAYER,
        HttpService = HttpService,
        Workspace = Workspace,
        trackConnection = trackConnection,
        refreshHud = function(fast)
            if updateHudVisuals then updateHudVisuals(fast) end
        end,
        loadCache = loadCache,
    }
end

local function loadQuestModule(name, ctx)
    if type(loadstring) ~= "function" then
        warn("[navegacao] loadstring indisponível — quest", name, "não carregada")
        return false
    end
    local source, label = fetchQuestSource(name)
    if not source then return false end
    local chunk, compileErr = loadstring(source, "@" .. tostring(label))
    if not chunk then
        warn("[navegacao] Falha ao compilar quest", name, ":", compileErr)
        return false
    end
    local ok, err = pcall(chunk, ctx)
    if not ok then
        warn("[navegacao] Erro ao carregar quest", name, ":", err)
        return false
    end
    return true
end

local function loadAllQuestModules()
    local ctx = buildQuestCtx(true)
    local ok = true
    ok = loadQuestModule("oscar", ctx) and ok
    ok = loadQuestModule("pinion", ctx) and ok
    ok = loadQuestModule("duskwire", ctx) and ok
    ok = loadQuestModule("tryhard", ctx) and ok
    if ok then
        print("[navegacao] Quest rods carregadas (loadstring por módulo).")
    else
        warn("[navegacao] Algumas quest rods falharam — confira QUEST_URLS no script ou pasta quests/.")
    end
    return ok
end

loadAllQuestModules()

end -- quest_loader

do -- core2a: utilitários de GUI e equip básico

local findRodToolByName = Nav.findRodToolByName

local function isGuiActuallyVisible(inst)
    local current = inst
    while current and current ~= PLAYER do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

clickGuiButton = function(button)
    if not button or not isGuiActuallyVisible(button) then return false end
    return pcall(function()
        if button:IsA("GuiButton") and firesignal then
            pcall(function() firesignal(button.Activated) end)
            pcall(function() firesignal(button.MouseButton1Click) end)
        end
    end)
end

local function pressInteractKey(repeats)
    repeats = repeats or 1
    for _ = 1, repeats do
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.08)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        task.wait(0.25)
    end
end

local function unequipAllTools()
    local char = refreshCharacter()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then pcall(function() humanoid:UnequipTools() end) end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then child.Parent = PLAYER.Backpack end
    end
end

local function equipToolByName(toolName)
    local tool = findRodToolByName(toolName)
    if not tool then
        warn("[navegacao] Item não encontrado no inventário:", toolName)
        return false
    end
    unequipAllTools()
    if EquipRemote then
        pcall(function() EquipRemote:FireServer(tool) end)
    end
    task.wait(0.15)
    local char = refreshCharacter()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if tool.Parent ~= char then
        if humanoid then
            pcall(function() humanoid:EquipTool(tool) end)
        else
            tool.Parent = char
        end
    end
    return true
end

Nav.clickGuiButton = clickGuiButton
Nav.pressInteractKey = pressInteractKey
Nav.unequipAllTools = unequipAllTools
Nav.equipToolByName = equipToolByName

end -- core2a

do -- core2a_relic: enchant relic

local unequipAllTools = Nav.unequipAllTools

local function toolHasChaoticEnchant(tool)
    if not tool then return false end
    if string.lower(tool.Name):find("chaotic", 1, true) then return true end
    for _, attrName in ipairs({ "Enchant", "enchant", "Enchantment", "enchantment" }) do
        local val = tool:GetAttribute(attrName)
        if val and string.lower(tostring(val)):find("chaotic", 1, true) then return true end
    end
    for _, desc in ipairs(tool:GetDescendants()) do
        local text = ""
        if desc:IsA("StringValue") then
            text = desc.Value or ""
        elseif desc:IsA("TextLabel") or desc:IsA("TextBox") then
            text = desc.Text or ""
        end
        if text ~= "" and string.lower(text):find("chaotic", 1, true) then return true end
        if string.lower(desc.Name):find("chaotic", 1, true) then return true end
    end
    return false
end

local function isEnchantRelicTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local lowered = string.lower(tool.Name)
    return lowered == string.lower(PINION_ENCHANT_RELIC_NAME)
        or lowered:find("enchant relic", 1, true) ~= nil
end

local function findEnchantRelicWithChaotic()
    local char = refreshCharacter()
    for _, container in ipairs({ char, PLAYER.Backpack }) do
        for _, item in ipairs(container:GetChildren()) do
            if isEnchantRelicTool(item) and toolHasChaoticEnchant(item) then
                return item
            end
        end
    end
    return nil
end

local function equipEnchantRelicChaotic()
    local tool = findEnchantRelicWithChaotic()
    if not tool then
        warn("[navegacao] Enchant Relic com enchant Chaotic não encontrada no inventário.")
        return false
    end
    unequipAllTools()
    if EquipRemote then
        pcall(function() EquipRemote:FireServer(tool) end)
    end
    task.wait(0.15)
    local char = refreshCharacter()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if tool.Parent ~= char then
        if humanoid then
            pcall(function() humanoid:EquipTool(tool) end)
        else
            tool.Parent = char
        end
    end
    print("[navegacao] Equipado:", tool.Name, "(Chaotic)")
    return true
end

Nav.findEnchantRelicWithChaotic = findEnchantRelicWithChaotic
Nav.equipEnchantRelicChaotic = equipEnchantRelicChaotic

end -- core2a_relic

do -- core2a_rod: detecção de vara equipada

local rodsMatchName = Nav.rodsMatchName
local invalidateRodCaches = Nav.invalidateRodCaches
local ownsRodFresh = Nav.ownsRodFresh

local function getEquippedRod()
    local char = refreshCharacter()
    for _, name in ipairs(ROD_EQUIP_PRIORITY) do
        local rod = char:FindFirstChild(name)
        if rod and rod:IsA("Tool") then return rod end
    end
    for _, alias in ipairs(OSCAR_ROD_ALIASES) do
        local rod = char:FindFirstChild(alias)
        if rod and rod:IsA("Tool") then return rod end
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item.Name:find("Rod") then return item end
    end
    return nil
end

local function waitForEquippedRodName(rodName, timeout)
    local deadline = tick() + (timeout or 3)
    while tick() < deadline do
        local equipped = getEquippedRod()
        if equipped and rodsMatchName(equipped.Name, rodName) then return equipped end
        task.wait(0.15)
    end
    return getEquippedRod()
end

local function waitForRodOwnership(rodName, timeout)
    local deadline = tick() + (timeout or 6)
    local nextInvalidate = 0
    while tick() < deadline do
        if tick() >= nextInvalidate then
            invalidateRodCaches()
            nextInvalidate = tick() + 0.75
        end
        if ownsRodFresh(rodName) then return true end
        task.wait(0.25)
    end
    invalidateRodCaches()
    return ownsRodFresh(rodName)
end

Nav.getEquippedRod = getEquippedRod
Nav.waitForEquippedRodName = waitForEquippedRodName
Nav.waitForRodOwnership = waitForRodOwnership

end -- core2a_rod

do -- core2a_purchase

local function getShopTeleportCFrame(rodName)
    if rodName == "Fast Rod" then return CFrame.new(ROD_SHOP_SPOT) end
    if rodName == "Rapid Rod" then return CFrame.new(RAPID_ROD_SHOP_SPOT) end
    if rodName == "Lucky Rod" then return CFrame.new(LUCKY_ROD_SHOP_SPOT) end
    if rodName == "Carrot Rod" then return CFrame.new(CARROT_ROD_SHOP_SPOT) end
    return CFrame.new(ROD_SHOP_SPOT)
end

local function findRodInteractable(rodName)
    local now = tick()
    local cached = rodInteractableCache[rodName]
    if cached and now < cached.expires and cached.value and cached.value.Parent then
        return cached.value
    end

    local result = nil
    local world = workspace:FindFirstChild("world")
    local interactables = world and world:FindFirstChild("interactables")
    if interactables then
        local direct = interactables:FindFirstChild(rodName)
        if direct then
            result = direct
        else
            local token = string.lower((rodName or ""):gsub("%s+Rod$", ""))
            if token ~= "" then
                forEachGuiNode(interactables, function(inst)
                    if result then return false end
                    if string.lower(inst.Name):find(token, 1, true) then
                        local prompt = inst:IsA("ProximityPrompt") and inst or inst:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            result = prompt
                            return false
                        end
                        if inst:IsA("Model") or inst:IsA("BasePart") then
                            result = inst
                            return false
                        end
                    end
                end, 10)
            end
        end
    end

    if not result then
        local targetPos = nil
        if rodName == "Carrot Rod" then targetPos = CARROT_ROD_SHOP_SPOT
        elseif rodName == "Lucky Rod" then targetPos = LUCKY_ROD_SHOP_SPOT
        elseif rodName == "Rapid Rod" then targetPos = RAPID_ROD_SHOP_SPOT
        elseif rodName == "Fast Rod" then targetPos = ROD_SHOP_SPOT end
        if targetPos then
            local nearest, nearestDist = nil, 80
            for _, root in ipairs({ interactables, workspace }) do
                if root and not result then
                    forEachGuiNode(root, function(inst)
                        if result or not inst:IsA("ProximityPrompt") then return end
                        local parent = inst.Parent
                        local pos = parent and parent:IsA("BasePart") and parent.Position
                        if not pos and parent and parent:IsA("Attachment") then
                            pos = parent.WorldPosition
                        end
                        if not pos and parent and parent:IsA("Model") then
                            local ok, pivot = pcall(function() return parent:GetPivot() end)
                            if ok and pivot then pos = pivot.Position end
                        end
                        if pos then
                            local dist = (pos - targetPos).Magnitude
                            if dist < nearestDist then
                                nearest = inst
                                nearestDist = dist
                            end
                        end
                    end, 8)
                end
            end
            result = nearest
        end
    end

    if result then
        rodInteractableCache[rodName] = { value = result, expires = now + ROD_INTERACTABLE_CACHE_TTL }
    end
    return result
end

local function fireProximityOnInteractable(interactable)
    if not interactable then return false end
    local function firePrompt(prompt)
        pcall(function() prompt.Enabled = true end)
        pcall(function() prompt.HoldDuration = 0 end)
        if fireproximityprompt then fireproximityprompt(prompt)
        else
            pcall(function() prompt:InputHoldBegin() end)
            task.wait(0.1)
            pcall(function() prompt:InputHoldEnd() end)
        end
    end
    if interactable:IsA("ProximityPrompt") then firePrompt(interactable) return true end
    for _, desc in ipairs(interactable:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then firePrompt(desc) return true end
    end
    return false
end

local function getWorkspacePrompt(timeout)
    local deadline = tick() + (timeout or 5)
    while tick() < deadline do
        local folder = workspace:FindFirstChild(PLAYER.Name)
        local prompt = folder and folder:FindFirstChild("prompt")
        if prompt then return prompt end
        task.wait(0.1)
    end
    return nil
end

local function openPurchaseHud(rodName, rodPrice, interactable)
    interactable = interactable or findRodInteractable(rodName)
    if not interactable then
        warn("[navegacao] Interactable não encontrado para:", rodName)
        return false
    end

    print("[navegacao] Interactable de compra:", interactable:GetFullName())

    local opened = false
    if fireProximityOnInteractable(interactable) then
        opened = true
        task.wait(0.2)
    end

    if PromptRemote and firesignal then
        local eventTarget = interactable:IsA("ProximityPrompt") and interactable.Parent or interactable
        firesignal(PromptRemote.OnClientEvent, {
            [1] = rodName, [2] = rodPrice, [3] = "Rod", [5] = eventTarget,
        })
        return true
    end

    return opened
end

local function tryClickPurchaseHudButton()
    local gui = PLAYER:FindFirstChild("PlayerGui")
    if not gui then return false end
    local keywords = { "buy", "purchase", "comprar" }
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("ScreenGui") and child.Enabled and child.Name ~= "NavegacaoHUD" then
            local clicked = false
            forEachGuiNode(child, function(inst)
                if clicked then return false end
                if inst:IsA("TextButton") and inst.Visible then
                    local text = string.lower(inst.Text or "")
                    for _, keyword in ipairs(keywords) do
                        if text:find(keyword, 1, true) and clickGuiButton(inst) then
                            clicked = true
                            return false
                        end
                    end
                end
            end, 7)
            if clicked then return true end
        end
    end
    return false
end

Nav.getShopTeleportCFrame = getShopTeleportCFrame
Nav.findRodInteractable = findRodInteractable
Nav.openPurchaseHud = openPurchaseHud
Nav.fireProximityOnInteractable = fireProximityOnInteractable
Nav.tryClickPurchaseHudButton = tryClickPurchaseHudButton
Nav.getWorkspacePrompt = getWorkspacePrompt

end -- core2a_purchase

do -- core2a2_bag

Bag.findRodGuiButton = function(rodName)
    local loweredRod = string.lower(rodName or "")
    local function matchesRod(candidate)
        if not candidate or candidate == "" then return false end
        if candidate == rodName or string.lower(candidate) == loweredRod then return true end
        if Nav.isOscarRodName(rodName) and Nav.isOscarRodName(candidate) then return true end
        return false
    end
    local function pickClickable(inst)
        if inst:IsA("GuiButton") and inst.Visible then return inst end
        local ancestor = inst:FindFirstAncestorWhichIsA("GuiButton")
        if ancestor and ancestor.Visible then return ancestor end
        return nil
    end
    local foundBtn = nil
    for _, container in ipairs(Nav.getHudInventoryContainers()) do
        forEachGuiNode(container, function(desc)
            if foundBtn or Nav.isRodSkinsPreview(desc) then return end
            local text = desc:IsA("TextLabel") or desc:IsA("TextButton") and desc.Text or ""
            if matchesRod(desc.Name) or matchesRod(text) then
                foundBtn = pickClickable(desc)
                if foundBtn then return false end
            end
        end)
        if foundBtn then return foundBtn end
    end
    return nil
end

Bag.isEquipmentBagOpen = function()
    for _, container in ipairs(Nav.getHudInventoryContainers()) do
        if container.Visible and container.AbsoluteSize.X > 40 then return true end
    end
    return false
end

Bag.openEquipmentBagUi = function()
    if Bag.isEquipmentBagOpen() then return true end
    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hotbar = playerGui and playerGui:FindFirstChild("hud")
        and playerGui.hud:FindFirstChild("safezone")
        and playerGui.hud.safezone:FindFirstChild("hotbar")
    if hotbar then
        for _, slotName in ipairs({ "2", "slot2" }) do
            local slot = hotbar:FindFirstChild(slotName)
            local btn = slot and (slot:IsA("GuiButton") and slot or slot:FindFirstChildWhichIsA("GuiButton", true))
            if btn and Nav.clickGuiButton(btn) then
                task.wait(0.4)
                if Bag.isEquipmentBagOpen() then return true end
            end
        end
    end
    return Bag.isEquipmentBagOpen()
end

Bag.closeEquipmentBagUi = function()
    if not Bag.isEquipmentBagOpen() then return true end
    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hotbar = playerGui and playerGui:FindFirstChild("hud")
        and playerGui.hud:FindFirstChild("safezone")
        and playerGui.hud.safezone:FindFirstChild("hotbar")
    if hotbar then
        local slot = hotbar:FindFirstChild("2")
        local btn = slot and (slot:IsA("GuiButton") and slot or slot:FindFirstChildWhichIsA("GuiButton", true))
        if btn and Nav.clickGuiButton(btn) then task.wait(0.25) end
    end
    return not Bag.isEquipmentBagOpen()
end

Bag.clickRodInEquipmentBag = function(rodName)
    local btn = Bag.findRodGuiButton(rodName)
    return btn and Nav.clickGuiButton(btn)
end

Bag.prepareRodEquipViaBag = function(rodName)
    if not Bag.openEquipmentBagUi() then return false end
    task.wait(0.35)
    return Bag.clickRodInEquipmentBag(rodName)
end

local function buildHotbarPayload(rodName)
    local payload = {
        ["1"] = rodName, ["2"] = "Equipment Bag", ["3"] = "Bestiary",
        ["4"] = "Quest Book", ["5"] = "Magical Conch",
    }
    if DataController then
        local ok, data = pcall(require, DataController)
        if ok and type(data) == "table" and type(data.hotbar) == "table" then
            for key, value in pairs(data.hotbar) do
                if type(value) == "string" and tostring(key) ~= "1" then
                    payload[tostring(key)] = value
                end
            end
        end
    end
    payload["1"] = rodName
    return payload
end

Hotbar.syncHotbar = function(rodName)
    if not SetHotbarRemote then return false end
    return pcall(function() SetHotbarRemote:FireServer(buildHotbarPayload(rodName)) end)
end

Hotbar.equipHotbarRodSlot = function()
    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hotbar = playerGui and playerGui:FindFirstChild("hud")
        and playerGui.hud:FindFirstChild("safezone")
        and playerGui.hud.safezone:FindFirstChild("hotbar")
    if hotbar then
        local slot = hotbar:FindFirstChild("1") or hotbar:FindFirstChild("slot1")
        local btn = slot and (slot:IsA("GuiButton") and slot or slot:FindFirstChildWhichIsA("GuiButton", true))
        if btn then Nav.clickGuiButton(btn) end
    end
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end)
    task.wait(0.35)
    return Nav.getEquippedRod() ~= nil
end

Hotbar.finishRodEquipFromBag = function(rodName)
    selectedRodName = rodName
    Hotbar.syncHotbar(rodName)
    task.wait(0.15)
    Bag.closeEquipmentBagUi()
    task.wait(0.2)
    Hotbar.equipHotbarRodSlot()
end

end -- core2a2_bag

do -- core2a2_bestiary

local function isGuiObjectVisible(inst)
    if not inst or not inst:IsA("GuiObject") then return false end
    local current = inst
    while current and current ~= PLAYER do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return inst.Visible
end

Bestiary.isOpen = function()
    local gui = Nav.getMainBestiaryGui()
    return gui and isGuiObjectVisible(gui) and gui.AbsoluteSize.X > 50
end

local function pickClickableGui(inst)
    if inst:IsA("GuiButton") and isGuiObjectVisible(inst) then return inst end
    local ancestor = inst:FindFirstAncestorWhichIsA("GuiButton")
    if ancestor and isGuiObjectVisible(ancestor) then return ancestor end
    return nil
end

Bestiary.open = function()
    if Bestiary.isOpen() then return true end

    Bag.closeEquipmentBagUi()
    task.wait(0.15)

    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hotbar = playerGui and playerGui:FindFirstChild("hud")
        and playerGui.hud:FindFirstChild("safezone")
        and playerGui.hud.safezone:FindFirstChild("hotbar")

    if hotbar then
        for _, slotName in ipairs({ "3", "slot3" }) do
            local slot = hotbar:FindFirstChild(slotName)
            local btn = slot and (slot:IsA("GuiButton") and slot or slot:FindFirstChildWhichIsA("GuiButton", true))
            if btn and Nav.clickGuiButton(btn) then
                task.wait(0.45)
                if Bestiary.isOpen() then return true end
            end
        end
    end

    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
        task.wait(0.08)
        VIM:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
    end)
    task.wait(0.45)
    return Bestiary.isOpen()
end

Bestiary.close = function()
    if not Bestiary.isOpen() then return true end

    local playerGui = PLAYER:FindFirstChild("PlayerGui")
    local hotbar = playerGui and playerGui:FindFirstChild("hud")
        and playerGui.hud:FindFirstChild("safezone")
        and playerGui.hud.safezone:FindFirstChild("hotbar")

    if hotbar then
        for _, slotName in ipairs({ "3", "slot3" }) do
            local slot = hotbar:FindFirstChild(slotName)
            local btn = slot and (slot:IsA("GuiButton") and slot or slot:FindFirstChildWhichIsA("GuiButton", true))
            if btn and Nav.clickGuiButton(btn) then
                task.wait(0.35)
                if not Bestiary.isOpen() then return true end
            end
        end
    end

    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
        task.wait(0.08)
        VIM:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
    end)
    task.wait(0.35)
    return not Bestiary.isOpen()
end

local function getGuiDisplayText(inst)
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        return inst.Text or ""
    end
    if inst:IsA("GuiObject") then
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                local text = child.Text or ""
                if text ~= "" then return text end
            end
        end
    end
    return inst.Name or ""
end

Bestiary.openCarrotGarden = function()
    if not Bestiary.open() then
        warn("[navegacao] Não foi possível abrir o Bestiary (slot 3).")
        return false
    end

    task.wait(0.35)
    local bestiary = Nav.getMainBestiaryGui()
    if not bestiary then return false end

    local opened = false
    forEachGuiNode(bestiary, function(desc)
        if opened or string.lower(desc.Name):find("template", 1, true) then return end

        if (desc:IsA("TextButton") or desc:IsA("TextLabel") or desc:IsA("ImageButton"))
            and isGuiObjectVisible(desc)
        then
            local text = string.lower(getGuiDisplayText(desc))
            local loweredName = string.lower(desc.Name)
            if text:find("carrot garden", 1, true)
                or (text:find("carrot", 1, true) and text:find("garden", 1, true))
                or (loweredName:find("carrot", 1, true) and loweredName:find("garden", 1, true))
            then
                local btn = pickClickableGui(desc) or (desc:IsA("GuiButton") and desc or nil)
                if btn and Nav.clickGuiButton(btn) then
                    opened = true
                    return false
                end
            end
        end
    end, BESTIARY_UI_SCAN_DEPTH)

    if opened then
        task.wait(0.5)
        return true
    end

    warn("[navegacao] Aba Carrot Garden não encontrada no Bestiary.")
    return false
end

local function refreshCarrotGardenBestiary(force, openUi)
    local now = tick()
    if not force and (now - lastBestiaryRefreshAt) < BESTIARY_REFRESH_INTERVAL then
        return Nav.getCarrotGardenBestiaryProgress()
    end

    lastBestiaryRefreshAt = now
    bestiaryCache.expires = 0

    local statsSummary = Nav.summarizeBestiaryInstance(Nav.findCarrotGardenBestiaryInstance())
    if statsSummary and not force then
        bestiaryCache.value = statsSummary
        bestiaryCache.expires = now + BESTIARY_CACHE_TTL
        return statsSummary
    end

    if openUi == false then
        return Nav.getCarrotGardenBestiaryProgress(true)
    end

    if Bestiary.openCarrotGarden() then
        task.wait(0.35)
        local progress = Nav.getCarrotGardenBestiaryProgress(true)
        if progress then
            print(string.format(
                "[navegacao] Bestiary Carrot Garden: %s%%",
                Nav.formatPercent(progress.percent)
            ))
        end
        return progress
    end

    return Nav.getCarrotGardenBestiaryProgress(true)
end

Nav.refreshCarrotGardenBestiary = refreshCarrotGardenBestiary

end -- core2a2_bestiary

do -- core2a2_equip_core

local function closeBlockingUisForPurchase()
    Bag.closeEquipmentBagUi()
    Bestiary.close()
    task.wait(0.2)
end

local function rodEquipRemoteSucceeded(result)
    if result == nil or result == true then return true end
    if type(result) == "table" and (result[1] == true or result.success == true) then return true end
    return false
end

local function tryRodEquipInvoke(rodName)
    if not RodEquipRemote or not DataController then return false end
    local attempts = { { rodName }, { { rodName } } }
    local okReq, module = pcall(require, DataController)
    if okReq and module and module ~= DataController then
        table.insert(attempts, { module })
    end
    for _, args in ipairs(attempts) do
        local ok, result = pcall(function()
            local unpackArgs = table.unpack or unpack
            return RodEquipRemote:InvokeServer(unpackArgs(args))
        end)
        if ok and rodEquipRemoteSucceeded(result) then
            selectedRodName = rodName
            return true
        end
    end
    return false
end

RodEquipRF.invoke = function(rodName)
    local namesToTry = Nav.isOscarRodName(rodName) and OSCAR_ROD_ALIASES or { rodName }
    for _, tryName in ipairs(namesToTry) do
        if not Nav.ownsRod(tryName) then continue end
        Bag.prepareRodEquipViaBag(tryName)
        task.wait(0.1)
        if tryRodEquipInvoke(tryName) then
            Hotbar.finishRodEquipFromBag(tryName)
            return true
        end
        Hotbar.syncHotbar(tryName)
        task.wait(0.15)
        Bag.clickRodInEquipmentBag(tryName)
        task.wait(0.1)
        if tryRodEquipInvoke(tryName) then
            Hotbar.finishRodEquipFromBag(tryName)
            return true
        end
        Bag.closeEquipmentBagUi()
    end
    return false
end

EquipRod = function(targetRodName)
    local tryList, seen = {}, {}
    local function addTry(name)
        if name == "Lucky Rod" and targetRodName ~= "Lucky Rod" and not Nav.shouldUseLuckyRodForBestiary() then
            return
        end
        if name and not seen[name] and Nav.ownsRod(name) then
            seen[name] = true
            table.insert(tryList, name)
        end
    end
    if targetRodName and Nav.ownsRod(targetRodName) then addTry(targetRodName) end
    addTry(Nav.getBestOwnedRodName())
    for _, name in ipairs(ROD_EQUIP_PRIORITY) do addTry(name) end
    for _, name in ipairs(Nav.getUiOwnedRods()) do addTry(name) end
    if #tryList == 0 then return false end

    for _, desiredName in ipairs(tryList) do
        local equipped = Nav.getEquippedRod()
        if equipped and Nav.rodsMatchName(equipped.Name, desiredName) then
            selectedRodName = desiredName
            return true
        end
        local rodTool = Nav.findRodToolByName(desiredName)
        if rodTool then
            Nav.unequipAllTools()
            if EquipRemote then pcall(function() EquipRemote:FireServer(rodTool) end) task.wait(0.25) end
            local char = refreshCharacter()
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if rodTool.Parent ~= char then
                if humanoid then pcall(function() humanoid:EquipTool(rodTool) end)
                else rodTool.Parent = char end
                task.wait(0.25)
            end
            if Nav.waitForEquippedRodName(desiredName, 3) then
                selectedRodName = desiredName
                if updateHudVisuals then updateHudVisuals(true) end
                return true
            end
            Hotbar.syncHotbar(desiredName)
            task.wait(0.15)
            if Hotbar.equipHotbarRodSlot() and Nav.waitForEquippedRodName(desiredName, 2) then
                selectedRodName = desiredName
                if updateHudVisuals then updateHudVisuals(true) end
                return true
            end
        end
        if RodEquipRF.invoke(desiredName) then
            if Nav.waitForEquippedRodName(desiredName, 3) then
                selectedRodName = desiredName
                if updateHudVisuals then updateHudVisuals(true) end
                return true
            end
        end
    end
    return false
end

Nav.EquipRod = EquipRod
Nav.closeBlockingUisForPurchase = closeBlockingUisForPurchase

end -- core2a2_equip_core

do -- core2a2_equip_farm

local function equipPreferredRod(preferredName)
    preferredName = Nav.resolvePreferredRodName(preferredName)
    if not preferredName then return false end

    local equipped = Nav.getEquippedRod()
    if equipped and Nav.rodsMatchName(equipped.Name, preferredName) then
        selectedRodName = preferredName
        lastFarmRodOkAt = tick()
        return true
    end

    Nav.invalidateRodCaches()

    if Bestiary.isOpen() then
        Bestiary.close()
        task.wait(0.2)
    end

    equipped = Nav.getEquippedRod()
    if equipped and Nav.rodsMatchName(equipped.Name, preferredName) then
        selectedRodName = preferredName
        lastFarmRodOkAt = tick()
        return true
    end

    print("[navegacao] Equipando vara:", preferredName)
    Hotbar.syncHotbar(preferredName)
    task.wait(0.15)

    if EquipRod(preferredName) then
        equipped = Nav.getEquippedRod()
        if equipped and Nav.rodsMatchName(equipped.Name, preferredName) then
            selectedRodName = preferredName
            Hotbar.syncHotbar(preferredName)
            lastFarmRodOkAt = tick()
            return true
        end
    end

    if Nav.isOscarRodName(preferredName) and RodEquipRF.invoke(preferredName) then
        equipped = Nav.getEquippedRod()
        if equipped and Nav.rodsMatchName(equipped.Name, preferredName) then
            selectedRodName = preferredName
            Hotbar.syncHotbar(preferredName)
            lastFarmRodOkAt = tick()
            return true
        end
    end

    Hotbar.finishRodEquipFromBag(preferredName)
    equipped = Nav.getEquippedRod()
    if equipped and Nav.rodsMatchName(equipped.Name, preferredName) then
        selectedRodName = preferredName
        lastFarmRodOkAt = tick()
        return true
    end

    lastFarmRodEquipFailAt = tick()
    return false
end

local function syncInitialFarmRodIfNeeded()
    if activeMode ~= MODES.INITIAL_FARM then return end
    if purchasingRod then return end

    local now = tick()
    local preferred = Nav.getPreferredFarmRodName()
    local equippedNow = Nav.getEquippedRod()

    if equippedNow and preferred and Nav.rodsMatchName(equippedNow.Name, preferred) then
        selectedRodName = preferred
        lastFarmRodOkAt = now
        lastRodSyncAt = now
        return
    end

    if initialFarmPhase == INITIAL_FARM_PHASE.XP
        and now - lastFarmRodOkAt < FARM_ROD_STABLE_SKIP then
        return
    end

    if now - lastFarmRodEquipFailAt < FARM_ROD_EQUIP_FAIL_BACKOFF then
        return
    end

    local cooldown = initialFarmPhase == INITIAL_FARM_PHASE.XP and ROD_SYNC_COOLDOWN_XP or ROD_SYNC_COOLDOWN
    if now - lastRodSyncAt < cooldown then return end

    if preferred then
        print("[navegacao] Ajustando vara do farm para:", preferred)
        if equipPreferredRod(preferred) then
            farmStrategyCache.expires = 0
        end
    end
    lastRodSyncAt = now
end

local function isPreCarrotRod(rodName)
    return rodName == "Fast Rod" or rodName == "Rapid Rod" or rodName == "Lucky Rod"
end

local function canPurchaseRodNow(rod)
    if not rod then return false end
    if rod.name == "Carrot Rod" then
        return Nav.isCarrotGardenComplete()
    end
    return true
end

Nav.equipPreferredRod = equipPreferredRod
Nav.syncInitialFarmRodIfNeeded = syncInitialFarmRodIfNeeded
Nav.isPreCarrotRod = isPreCarrotRod
Nav.canPurchaseRodNow = canPurchaseRodNow

end -- core2a2_equip_farm

do -- core2b: status de farm e teleporte

local function getRodProgressionStatus()
    local nextRod = Nav.getNextRodToBuy()
    local equipped = Nav.getEquippedRod()
    local best = Nav.getBestOwnedRodName()
    local owned = {}
    for _, rod in ipairs(ROD_PURCHASE_QUEUE) do
        if Nav.rodPurchasedForQueue(rod.name) then table.insert(owned, rod.name) end
    end
    local lines = {}
    if #owned == 0 then
        table.insert(lines, "Nenhuma vara da fila ainda")
    else
        table.insert(lines, "Possui: " .. table.concat(owned, ", "))
    end
    if nextRod then
        local coins = Nav.getPlayerCoins()
        local missing = coins and math.max(nextRod.price - coins, 0) or nextRod.price
        table.insert(lines, string.format("Próxima: %s (C$%s, falta %s)", nextRod.name, Nav.formatCoins(nextRod.price), Nav.formatCoins(missing)))
        if Nav.isPreCarrotRod(nextRod.name) and activeMode == MODES.INITIAL_FARM and initialFarmPhase == INITIAL_FARM_PHASE.CARROT then
            if coins and coins >= nextRod.price then
                table.insert(lines, "Auto-compra: aguardando ciclo...")
            else
                table.insert(lines, "Auto-compra: ativa (Farm Inicial)")
            end
        end
        if nextRod.name == "Carrot Rod" and activeMode == MODES.INITIAL_FARM and initialFarmPhase == INITIAL_FARM_PHASE.CARROT then
            if Nav.canPurchaseRodNow(nextRod) and coins and coins >= nextRod.price then
                table.insert(lines, "Auto-compra Carrot: aguardando ciclo...")
            end
        end
        if nextRod.name == "Carrot Rod" then
            local progress = Nav.getCarrotGardenBestiaryProgress()
            if progress then table.insert(lines, string.format("Bestiary: %s%%", Nav.formatPercent(progress.percent))) end
        end
    else
        table.insert(lines, "Fila completa!")
    end
    if equipped then
        table.insert(lines, "Equipada: " .. equipped.Name)
    elseif best then
        table.insert(lines, "Melhor: " .. best)
    end
    local color = nextRod and Color3.fromRGB(220, 170, 80) or Color3.fromRGB(80, 200, 100)
    return table.concat(lines, "\n"), color
end

local function getModeTargetCFrame(mode)
    if mode == MODES.INITIAL_FARM then
        local phase = initialFarmPhase or INITIAL_FARM_PHASE.CARROT
        return FARM_TARGETS[phase]
    end
    return TELEPORT_TARGETS[mode]
end

local function getInitialFarmStatus()
    local carrot = Nav.getCarrotRodAvailability()

    if activeMode == MODES.INITIAL_FARM then
        return {
            label = "Farm Carrot Rod (ativo)\n" .. carrot.label,
            color = carrot.color,
        }
    end

    if Nav.ownsRod("Carrot Rod") then
        return {
            label = "Desligado — Carrot Rod obtida!\nUse o botão Farm XP p/ teleportar",
            color = Color3.fromRGB(80, 200, 100),
        }
    end

    return {
        label = "Farm Carrot Rod\n" .. carrot.label,
        color = carrot.color,
    }
end

Nav.getRodProgressionStatus = getRodProgressionStatus
Nav.getInitialFarmStatus = getInitialFarmStatus
Nav.getModeTargetCFrame = getModeTargetCFrame

end -- core2b

do -- core3a_hold

-- ===== Teleporte (posição) =====
local function restoreCharacterMovement()
    local char = refreshCharacter()
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid.AutoRotate = true end)
    end
end

local function teleportToCFrame(targetCFrame, lockRotation)
    local hrp = getHumanoidRootPart()
    if not hrp or not targetCFrame then return false end

    local char = hrp.Parent
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if lockRotation then
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = targetCFrame
        if humanoid then
            pcall(function() humanoid.AutoRotate = false end)
        end
    else
        local delta = hrp.Position - targetCFrame.Position
        if math.abs(delta.X) > 1 or math.abs(delta.Y) > 1 or math.abs(delta.Z) > 1 then
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        hrp.CFrame = targetCFrame
    end
    return true
end

local function isDriftedFromTarget(targetCFrame, tolerance)
    local hrp = getHumanoidRootPart()
    if not hrp or not targetCFrame then return false end
    tolerance = tolerance or SPOT_TOLERANCE
    local delta = hrp.Position - targetCFrame.Position
    return math.abs(delta.X) > tolerance.X
        or math.abs(delta.Y) > tolerance.Y
        or math.abs(delta.Z) > tolerance.Z
end

local function stopPositionHold()
    positionHoldToken = nil
    restoreCharacterMovement()
end

local function stopShopPositionHold()
    shopHoldToken = nil
end

local function startShopPositionHold(targetCFrame)
    stopShopPositionHold()
    local token = {}
    shopHoldToken = token

    task.spawn(function()
        teleportToCFrame(targetCFrame, true)
        while shopHoldToken == token do
            if isDriftedFromTarget(targetCFrame) then
                teleportToCFrame(targetCFrame, false)
            end
            task.wait(POSITION_CHECK_INTERVAL)
        end
    end)
end

local function unequipRodBeforeTeleport(label)
    if not Nav.getEquippedRod() then return false end
    print("[navegacao] Guardando vara antes do teleporte:", label or "compra")
    Nav.unequipAllTools()
    task.wait(0.3)
    return true
end

local function startPositionHold(mode)
    stopPositionHold()
    local target = Nav.getModeTargetCFrame(mode)
    if not target then return end

    local token = {}
    positionHoldToken = token
    local cachedTarget = target
    local isFarm = mode == MODES.INITIAL_FARM

    task.spawn(function()
        teleportToCFrame(cachedTarget, isFarm)
        local lastTargetRefresh = tick()
        while positionHoldToken == token and activeMode == mode do
            local interval = POSITION_CHECK_INTERVAL
            local tolerance = SPOT_TOLERANCE

            if isFarm then
                if initialFarmPhase == INITIAL_FARM_PHASE.XP then
                    interval = POSITION_CHECK_INTERVAL_FARM_XP
                else
                    interval = POSITION_CHECK_INTERVAL_FARM
                end
                tolerance = SPOT_TOLERANCE_FARM
                if tick() - lastTargetRefresh >= 30 then
                    cachedTarget = Nav.getModeTargetCFrame(mode) or cachedTarget
                    lastTargetRefresh = tick()
                end
            else
                cachedTarget = Nav.getModeTargetCFrame(mode) or cachedTarget
            end

            if cachedTarget and isDriftedFromTarget(cachedTarget, tolerance) then
                teleportToCFrame(cachedTarget, isFarm)
            end
            task.wait(interval)
        end
    end)
end

Nav.teleportToCFrame = teleportToCFrame
Nav.unequipRodBeforeTeleport = unequipRodBeforeTeleport
Nav.startPositionHold = startPositionHold
Nav.stopPositionHold = stopPositionHold
Nav.stopShopPositionHold = stopShopPositionHold
Nav.isDriftedFromTarget = isDriftedFromTarget

end -- core3a_hold

do -- core3a_modes

local function teleportOnceToMode(mode)
    local target = Nav.getModeTargetCFrame(mode)
    if not target then
        warn("[navegacao] Destino não encontrado:", tostring(mode))
        return false
    end

    local label = TELEPORT_MODE_LABELS[mode] or tostring(mode)
    print(string.format(
        "[navegacao] Teleporte — %s (%.2f, %.2f, %.2f)",
        label,
        target.Position.X,
        target.Position.Y,
        target.Position.Z
    ))
    return teleportToCFrame(target, true)
end

local function teleportPinionStep4()
    local pinion = Nav.getPinionAriaQuestAvailability()
    if not pinion.step3Done then
        warn("[navegacao] Passo 4: complete o bestiário Vertigo (100%) primeiro.")
        return false
    end

    print("[navegacao] Passo 4 — equipando The Depths Key e teleportando...")
    local equipped = Nav.equipToolByName(PINION_DEPTHS_KEY_NAME)
    if not equipped then
        warn("[navegacao] Passo 4: The Depths Key não encontrada — teleportando mesmo assim.")
    end
    task.wait(0.2)
    return teleportOnceToMode(MODES.PINION_STEP4)
end

local function teleportPinionStep5()
    local pinion = Nav.getPinionAriaQuestAvailability()
    if not pinion.step4Done then
        warn("[navegacao] Passo 5: marque o Passo 4 como concluído primeiro.")
        return false
    end
    return teleportOnceToMode(MODES.PINION_STEP5)
end

local function teleportTryhardStep2()
    print("[navegacao] TryHard Rod P2 — equipando Flimsy Rod e teleportando...")
    local equipped = EquipRod(FALLBACK_ROD)
    if not equipped then
        warn("[navegacao] TryHard Rod P2: Flimsy Rod não encontrada — teleportando mesmo assim.")
    end
    task.wait(0.2)
    return teleportOnceToMode(MODES.TRYHARD_STEP2)
end

local function setActiveMode(mode)
    if activeMode == mode then
        activeMode = nil
        initialFarmPhase = nil
        stopPositionHold()
    else
        activeMode = mode
        if mode == MODES.INITIAL_FARM then
            selectedRodName = nil
            farmStrategyCache.expires = 0
            lastRodSyncAt = 0
            lastFarmRodOkAt = 0
            lastFarmRodEquipFailAt = 0
            initialFarmPhase = INITIAL_FARM_PHASE.CARROT
            print("[navegacao] Farm Inicial: mapa Carrot Rod.")
        end
        startPositionHold(mode)
        if mode == MODES.INITIAL_FARM then
            task.spawn(function()
                task.wait(0.6)
                if activeMode ~= mode or purchasingRod then return end
                local preferred = Nav.getPreferredFarmRodName()
                if Nav.equipPreferredRod(preferred) then
                    lastRodSyncAt = tick()
                else
                    task.wait(1.5)
                    if activeMode == mode and not purchasingRod then
                        Nav.equipPreferredRod(Nav.getPreferredFarmRodName())
                    end
                end
                if initialFarmPhase == INITIAL_FARM_PHASE.CARROT then
                    task.spawn(function()
                        Nav.refreshCarrotGardenBestiary(true, false)
                    end)
                end
                if updateHudVisuals then updateHudVisuals(true) end
            end)
        end
    end
end

Nav.setActiveMode = setActiveMode
Nav.teleportOnceToMode = teleportOnceToMode
Nav.teleportPinionStep4 = teleportPinionStep4
Nav.teleportPinionStep5 = teleportPinionStep5
Nav.teleportTryhardStep2 = teleportTryhardStep2

end -- core3a_modes

do -- core3a2_purchase

local function confirmPurchaseOnce(rodName, rodPrice, interactable)
    interactable = interactable or Nav.findRodInteractable(rodName)

    local promptObj = Nav.getWorkspacePrompt(3)
    if promptObj and PurchaseRemote then
        PurchaseRemote:FireServer(promptObj)
        if Nav.waitForRodOwnership(rodName, 2) then return true end
    end

    if PurchaseRemote then
        PurchaseRemote:FireServer(rodName, "Rod", rodPrice, 1)
        if Nav.waitForRodOwnership(rodName, 2) then return true end
    end

    if interactable and PurchaseRemote then
        PurchaseRemote:FireServer(interactable)
        if Nav.waitForRodOwnership(rodName, 2) then return true end
    end

    if Nav.tryClickPurchaseHudButton() then
        if Nav.waitForRodOwnership(rodName, 2) then return true end
    end

    return Nav.ownsRodFresh(rodName)
end

local function purchaseRodUntilOwned(rodName, rodPrice, shopCFrame)
    local interactable = nil
    local lastHudOpenAt = 0

    print(string.format("[navegacao] Aguardando compra de %s — permanecendo na loja.", rodName))

    while scriptAlive do
        if Nav.ownsRodFresh(rodName) then
            print("[navegacao]", rodName, "confirmada no inventário!")
            return true
        end

        if Nav.isDriftedFromTarget(shopCFrame) then
            Nav.teleportToCFrame(shopCFrame, false)
        end

        local now = tick()
        if now - lastHudOpenAt >= PURCHASE_HUD_REOPEN_INTERVAL then
            Nav.invalidateRodCaches()
            Nav.closeBlockingUisForPurchase()
            interactable = Nav.findRodInteractable(rodName)
            if Nav.openPurchaseHud(rodName, rodPrice, interactable) then
                task.wait(0.5)
            else
                Nav.fireProximityOnInteractable(interactable)
                Nav.pressInteractKey(2)
                task.wait(0.3)
            end
            lastHudOpenAt = now
        end

        confirmPurchaseOnce(rodName, rodPrice, interactable)
        task.wait(PURCHASE_RETRY_INTERVAL)
    end

    return false
end

local function tryPurchaseRod(rodName, rodPrice)
    if not PurchaseRemote then
        warn("[navegacao] Remote purchase não encontrado.")
        return false
    end

    playerCoinsCache.expires = 0
    local coins = Nav.getPlayerCoins()
    if not coins or coins < rodPrice then
        print(string.format("[navegacao] Saldo insuficiente para %s — %d / %d C$.", rodName, coins or 0, rodPrice))
        return false
    end
    if rodName == "Carrot Rod" then
        Nav.refreshCarrotGardenBestiary(true, false)
        if not Nav.isCarrotGardenComplete() then
            local progress = Nav.getCarrotGardenBestiaryProgress()
            print(string.format("[navegacao] Carrot Rod exige Bestiary 100%% — atual: %s%%.",
                Nav.formatPercent(progress and progress.percent or 0)))
            return false
        end
    end

    local hrp = getHumanoidRootPart()
    if not hrp then return false end

    local returnCFrame = (activeMode and Nav.getModeTargetCFrame(activeMode)) or hrp.CFrame
    local previousMode = activeMode
    local shopCFrame = Nav.getShopTeleportCFrame(rodName)

    if activeMode then
        activeMode = nil
        Nav.stopPositionHold()
    end

    purchasingRod = true

    Nav.closeBlockingUisForPurchase()
    Nav.unequipRodBeforeTeleport(rodName)
    Nav.startShopPositionHold(shopCFrame)
    Nav.teleportToCFrame(shopCFrame, true)

    print(string.format(
        "[navegacao] Indo à loja para %s — %.2f, %.2f, %.2f (saldo: %d C$).",
        rodName,
        shopCFrame.Position.X,
        shopCFrame.Position.Y,
        shopCFrame.Position.Z,
        coins
    ))

    task.wait(0.5)

    local interactable = Nav.findRodInteractable(rodName)
    if not Nav.openPurchaseHud(rodName, rodPrice, interactable) then
        warn("[navegacao] HUD de compra não abriu; tentando novamente na loja.")
    end
    task.wait(0.8)

    local purchased = false
    local ok, err = pcall(function()
        purchased = purchaseRodUntilOwned(rodName, rodPrice, shopCFrame)
    end)

    if not ok then
        warn("[navegacao] Erro durante compra de " .. rodName .. ":", tostring(err))
    end

    if not purchased then
        Nav.stopShopPositionHold()
        purchasingRod = false
        if previousMode then
            activeMode = previousMode
            Nav.startPositionHold(previousMode)
        end
        return false
    end

    Nav.stopShopPositionHold()
    purchasingRod = false

    print("[navegacao]", rodName, "adquirida!")
    Nav.invalidateRodCaches()
    playerCoinsCache.expires = 0
    print(string.format(
        "[navegacao] Voltando ao farm — %.2f, %.2f, %.2f",
        returnCFrame.Position.X,
        returnCFrame.Position.Y,
        returnCFrame.Position.Z
    ))
    Nav.teleportToCFrame(returnCFrame, true)
    task.wait(0.5)
    if previousMode then
        activeMode = previousMode
        if previousMode == MODES.INITIAL_FARM then
            initialFarmPhase = INITIAL_FARM_PHASE.CARROT
        end
        Nav.startPositionHold(previousMode)
        task.wait(0.6)
        Nav.equipPreferredRod(rodName)
        task.delay(1.2, function()
            if not scriptAlive or purchasingRod then return end
            if activeMode ~= previousMode then return end
            local equipped = Nav.getEquippedRod()
            if equipped and Nav.rodsMatchName(equipped.Name, rodName) then return end
            Nav.equipPreferredRod(rodName)
        end)
    end
    if updateHudVisuals then updateHudVisuals(true) end
    return true
end

Nav.tryPurchaseRod = tryPurchaseRod

end -- core3a2_purchase

do -- core3a2_autobuy

local function purchaseNextRod()
    if purchasingRod then return false end
    local target = Nav.getNextRodToBuy()
    if not target then
        print("[navegacao] Todas as varas da fila já foram obtidas.")
        return false
    end
    return Nav.tryPurchaseRod(target.name, target.price)
end

local function tryAutoPurchaseForInitialFarm()
    if activeMode ~= MODES.INITIAL_FARM then return false end
    if initialFarmPhase ~= INITIAL_FARM_PHASE.CARROT then return false end
    if purchasingRod then return false end
    if shopHoldToken then return false end
    if tick() - lastAutoBuyAttemptAt < AUTO_BUY_FAIL_COOLDOWN then return false end

    playerCoinsCache.expires = 0

    local target = Nav.getNextRodToBuy()
    if not target then return false end
    if not Nav.canPurchaseRodNow(target) then return false end

    local coins = Nav.getPlayerCoins()
    if not coins or coins < target.price then return false end

    print(string.format(
        "[navegacao] Auto-compra (Farm Inicial): %s — C$%s",
        target.name,
        Nav.formatCoins(coins)
    ))

    task.spawn(function()
        local ok = Nav.tryPurchaseRod(target.name, target.price)
        if not ok then
            lastAutoBuyAttemptAt = tick()
        end
        if updateHudVisuals then updateHudVisuals(false) end
    end)
    return true
end

local function runInitialFarmCarrotCycle()
    if activeMode ~= MODES.INITIAL_FARM or initialFarmPhase ~= INITIAL_FARM_PHASE.CARROT then
        return
    end
    if purchasingRod or farmCycleRunning then return end

    farmCycleRunning = true
    farmCycleCounter += 1

    if farmCycleCounter % 12 == 1 then
        Nav.refreshCarrotGardenBestiary(false, false)
    end

    if farmCycleCounter % 3 == 0 then
        tryAutoPurchaseForInitialFarm()
    end

    if farmCycleCounter % 5 == 0 then
        Nav.syncInitialFarmRodIfNeeded()
    end
    farmCycleRunning = false
end

local function startAutoBuyLoop()
    task.spawn(function()
        print("[navegacao] Farm Inicial: ciclo leve — menos CPU durante pesca.")
        while scriptAlive do
            local waitTime = AUTO_BUY_CHECK_INTERVAL
            task.wait(waitTime)
            if not scriptAlive or purchasingRod then continue end
            if activeMode ~= MODES.INITIAL_FARM then continue end
            runInitialFarmCarrotCycle()
        end
    end)
end

Nav.purchaseNextRod = purchaseNextRod
Nav.startAutoBuyLoop = startAutoBuyLoop

end -- core3a2_autobuy

do -- core3b: autosell, cleanup

local equipPreferredRod = Nav.equipPreferredRod
local stopPositionHold = Nav.stopPositionHold
local stopShopPositionHold = Nav.stopShopPositionHold

local function equipBestRod()
    local ok = equipPreferredRod()
    if updateHudVisuals then updateHudVisuals(true) end
    return ok
end

-- ===== Auto Sell =====
local function performSellAll()
    if not SellAllRemote then
        warn("[navegacao] Remote SellAll não encontrado.")
        return false
    end

    local ok
    if DialogModule then
        ok = silentInvoke(SellAllRemote, DialogModule)
    else
        ok = silentInvoke(SellAllRemote)
    end

    if ok then
        playerCoinsCache.expires = 0
        print("[navegacao] SellAll OK")
        return true
    end

    warn("[navegacao] SellAll falhou")
    return false
end

local function toggleAutoSell()
    autoSellEnabled = not autoSellEnabled
    print("[navegacao] Auto Sell:", autoSellEnabled and "ATIVO" or "INATIVO")
    if updateHudVisuals then updateHudVisuals(false) end
end

local function startSellAllLoop()
    task.spawn(function()
        print(string.format("[navegacao] Auto Sell disponível (intervalo %ds).", SELL_ALL_INTERVAL))
        while scriptAlive do
            task.wait(SELL_ALL_INTERVAL)
            if autoSellEnabled and not purchasingRod then
                performSellAll()
            end
        end
    end)
end

local function destroyScript()
    if not scriptAlive then return end
    scriptAlive = false
    activeMode = nil
    initialFarmPhase = nil
    autoSellEnabled = false
    stopPositionHold()
    stopShopPositionHold()
    purchasingRod = false

    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    table.clear(rodInteractableCache)
    hudContainersCache.expires = 0
    table.clear(hudContainersCache.list)

    if hudGui then
        pcall(function() hudGui:Destroy() end)
        hudGui = nil
    end

    print("[navegacao] Script encerrado.")
end

Nav.toggleAutoSell = toggleAutoSell
Nav.equipBestRod = equipBestRod
Nav.startSellAllLoop = startSellAllLoop
Nav.destroyScript = destroyScript

end -- core3b

do -- hud

local bindQuestUiRefs

-- ===== HUD (estado compartilhado — 1 local, evita limite 200) =====
local hudRefs = {
    toggleButtons = {},
    statusLabels = {},
    oscarStepSections = {},
    pinionStepSections = {},
    pinionCompleteButtons = {},
    pinionUndoButtons = {},
    duskwireCompleteButtons = {},
    duskwireUndoButtons = {},
    tryhardCompleteButtons = {},
    tryhardUndoButtons = {},
    pinionHeader = nil,
    duskwireHeader = nil,
    tryhardHeader = nil,
    oscarStartRow = nil,
    oscarStartBtn = nil,
    oscarRedoBtn = nil,
    pinionStartRow = nil,
    pinionStartBtn = nil,
    pinionRedoBtn = nil,
    duskwireStartRow = nil,
    duskwireStartBtn = nil,
    duskwireRedoBtn = nil,
    tryhardStartRow = nil,
    tryhardStartBtn = nil,
    tryhardRedoBtn = nil,
    duskwireStepSections = {},
    tryhardStepSections = {},
    activeHudTab = "home",
    scrollHome = nil,
    scrollQuest = nil,
    tabBtnHome = nil,
    tabBtnQuest = nil,
}

local TAB_ACTIVE = Color3.fromRGB(46, 120, 180)
local TAB_INACTIVE = Color3.fromRGB(40, 44, 54)
local TAB_TEXT_ACTIVE = Color3.new(1, 1, 1)
local TAB_TEXT_INACTIVE = Color3.fromRGB(150, 158, 175)

do -- hud_ui

Nav.setHudTab = function(tabName)
    hudRefs.activeHudTab = tabName
    if hudRefs.scrollHome then hudRefs.scrollHome.Visible = tabName == "home" end
    if hudRefs.scrollQuest then hudRefs.scrollQuest.Visible = tabName == "quest" end
    if hudRefs.tabBtnHome then
        hudRefs.tabBtnHome.BackgroundColor3 = tabName == "home" and TAB_ACTIVE or TAB_INACTIVE
        hudRefs.tabBtnHome.TextColor3 = tabName == "home" and TAB_TEXT_ACTIVE or TAB_TEXT_INACTIVE
    end
    if hudRefs.tabBtnQuest then
        hudRefs.tabBtnQuest.BackgroundColor3 = tabName == "quest" and TAB_ACTIVE or TAB_INACTIVE
        hudRefs.tabBtnQuest.TextColor3 = tabName == "quest" and TAB_TEXT_ACTIVE or TAB_TEXT_INACTIVE
    end
end

Nav.makeTabButton = function(parent, text, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -3, 1, 0)
    btn.BackgroundColor3 = TAB_INACTIVE
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = TAB_TEXT_INACTIVE
    btn.Text = text
    btn.LayoutOrder = layoutOrder
    btn.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    return btn
end

Nav.makeTabScroll = function(parent)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.fromScale(1, 1)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    return scroll
end

Nav.makeQuestControlRow = function(parent, layoutOrder, questId)
    local row = Instance.new("Frame")
    row.Name = "ControlRow_" .. questId
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = layoutOrder
    row.Visible = false
    row.Parent = parent

    local startBtn = Instance.new("TextButton")
    startBtn.Name = "StartBtn"
    startBtn.Size = UDim2.new(0, 90, 0, 24)
    startBtn.Position = UDim2.fromOffset(0, 0)
    startBtn.BackgroundColor3 = Color3.fromRGB(46, 120, 180)
    startBtn.BorderSizePixel = 0
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 11
    startBtn.TextColor3 = Color3.new(1, 1, 1)
    startBtn.Text = "Iniciar"
    startBtn.Parent = row

    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 6)
    startCorner.Parent = startBtn

    local redoBtn = Instance.new("TextButton")
    redoBtn.Name = "RedoBtn"
    redoBtn.Size = UDim2.new(0, 90, 0, 24)
    redoBtn.Position = UDim2.fromOffset(0, 0)
    redoBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 180)
    redoBtn.BorderSizePixel = 0
    redoBtn.Font = Enum.Font.GothamBold
    redoBtn.TextSize = 11
    redoBtn.TextColor3 = Color3.new(1, 1, 1)
    redoBtn.Text = "Refazer"
    redoBtn.Visible = false
    redoBtn.Parent = row

    local redoCorner = Instance.new("UICorner")
    redoCorner.CornerRadius = UDim.new(0, 6)
    redoCorner.Parent = redoBtn

    trackConnection(startBtn.MouseButton1Click:Connect(function()
        if questId == "oscar" then
            Nav.startOscarQuest()
        elseif questId == "pinion" then
            Nav.startPinionQuest()
        elseif questId == "duskwire" then
            Nav.startDuskwireQuest()
        elseif questId == "tryhard" then
            Nav.startTryhardQuest()
        end
    end))

    trackConnection(redoBtn.MouseButton1Click:Connect(function()
        if questId == "oscar" then
            Nav.redoOscarQuest()
        elseif questId == "pinion" then
            Nav.redoPinionQuest()
        elseif questId == "duskwire" then
            Nav.redoDuskwireQuest()
        elseif questId == "tryhard" then
            Nav.redoTryhardQuest()
        end
    end))

    return row, startBtn, redoBtn
end

Nav.makeQuestStartButton = Nav.makeQuestControlRow

Nav.makeToggleButton = function(parent, text, layoutOrder, mode, yOffset)
    local btn = Instance.new("TextButton")
    btn.Name = "Toggle_" .. mode
    btn.Size = UDim2.new(0, 90, 0, 24)
    btn.Position = UDim2.new(1, -98, 0, yOffset or 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 65, 78)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "INATIVO"
    btn.LayoutOrder = layoutOrder
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    hudRefs.toggleButtons[mode] = btn

    if mode == MODES.AUTO_SELL then
        trackConnection(btn.MouseButton1Click:Connect(Nav.toggleAutoSell))
    else
        trackConnection(btn.MouseButton1Click:Connect(function()
            Nav.setActiveMode(mode)
            if updateHudVisuals then updateHudVisuals(true) end
        end))
    end

    return btn
end

Nav.makeAutoSellSection = function(parent, layoutOrder)
    local section = Instance.new("Frame")
    section.Name = "Section_auto_sell"
    section.Size = UDim2.new(1, 0, 0, 56)
    section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 16)
    title.Position = UDim2.fromOffset(8, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(200, 210, 225)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Auto Sell"
    title.Parent = section

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -100, 0, 32)
    status.Position = UDim2.fromOffset(8, 20)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(170, 178, 195)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = string.format("Vende inventário a cada %ds", SELL_ALL_INTERVAL)
    status.Parent = section
    hudRefs.statusLabels[MODES.AUTO_SELL] = status

    Nav.makeToggleButton(section, "", layoutOrder, MODES.AUTO_SELL, 16)
    return section
end

Nav.makeSection = function(parent, titleText, statusText, layoutOrder, mode, sectionHeight)
    sectionHeight = sectionHeight or 56
    local statusHeight = sectionHeight - 24

    local section = Instance.new("Frame")
    section.Name = "Section_" .. mode
    section.Size = UDim2.new(1, 0, 0, sectionHeight)
    section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 16)
    title.Position = UDim2.fromOffset(8, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(200, 210, 225)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = titleText
    title.Parent = section

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -100, 0, statusHeight)
    status.Position = UDim2.fromOffset(8, 20)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(170, 178, 195)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = statusText or "—"
    status.Parent = section

    hudRefs.statusLabels[mode] = status
    Nav.makeToggleButton(section, "", layoutOrder, mode, 16)

    return section
end

Nav.makeTeleportSection = function(parent, titleText, statusText, layoutOrder, mode, sectionHeight)
    sectionHeight = sectionHeight or 56
    local statusHeight = sectionHeight - 24

    local section = Instance.new("Frame")
    section.Name = "Section_" .. mode
    section.Size = UDim2.new(1, 0, 0, sectionHeight)
    section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 16)
    title.Position = UDim2.fromOffset(8, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(200, 210, 225)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = titleText
    title.Parent = section

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -100, 0, statusHeight)
    status.Position = UDim2.fromOffset(8, 20)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(170, 178, 195)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = statusText or "—"
    status.Parent = section

    hudRefs.statusLabels[mode] = status

    local btn = Instance.new("TextButton")
    btn.Name = "Teleport_" .. mode
    btn.Size = UDim2.new(0, 90, 0, 24)
    btn.Position = UDim2.new(1, -98, 0, 16)
    btn.BackgroundColor3 = Color3.fromRGB(46, 120, 180)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Teleportar"
    btn.Parent = section

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    trackConnection(btn.MouseButton1Click:Connect(function()
        Nav.teleportOnceToMode(mode)
    end))

    return section
end

end -- hud_ui

do -- hud_quest_actions

Nav.updateQuestControlRow = function(row, startBtn, redoBtn, startInfo, showRedo)
    if not row or not startBtn or not redoBtn then return end
    if showRedo then
        row.Visible = true
        startBtn.Visible = false
        redoBtn.Visible = true
        return
    end
    if startInfo.completed or startInfo.started then
        row.Visible = false
        return
    end
    row.Visible = true
    startBtn.Visible = true
    redoBtn.Visible = false
    startBtn.Text = "Iniciar"
    startBtn.Active = startInfo.canStart == true
    startBtn.AutoButtonColor = startInfo.canStart == true
    startBtn.BackgroundColor3 = startInfo.canStart
        and Color3.fromRGB(46, 120, 180)
        or Color3.fromRGB(70, 75, 88)
end

Nav.updateQuestStartButton = Nav.updateQuestControlRow

Nav.updateQuestRedoButton = function(row, btn, show)
    if not row or not btn then return end
    local startBtn = row:FindFirstChild("StartBtn")
    local redoBtn = row:FindFirstChild("RedoBtn") or btn
    if show then
        row.Visible = true
        if startBtn then startBtn.Visible = false end
        redoBtn.Visible = true
    else
        redoBtn.Visible = false
    end
end

end -- hud_quest_actions

do -- hud_quest_widgets

Nav.makeQuestUndoButton = function(parent, stepKey, undoButtons, position, onUndo)
    local undoBtn = Instance.new("TextButton")
    undoBtn.Name = "Undo_" .. stepKey
    undoBtn.Size = UDim2.fromOffset(72, 24)
    undoBtn.Position = position
    undoBtn.BackgroundColor3 = Color3.fromRGB(55, 58, 68)
    undoBtn.BorderSizePixel = 0
    undoBtn.Font = Enum.Font.GothamBold
    undoBtn.TextSize = 10
    undoBtn.TextColor3 = Color3.new(1, 1, 1)
    undoBtn.Text = "Voltar"
    undoBtn.Active = false
    undoBtn.AutoButtonColor = false
    undoBtn.Parent = parent

    local undoCorner = Instance.new("UICorner")
    undoCorner.CornerRadius = UDim.new(0, 6)
    undoCorner.Parent = undoBtn

    undoButtons[stepKey] = undoBtn

    trackConnection(undoBtn.MouseButton1Click:Connect(function()
        onUndo(stepKey)
    end))

    return undoBtn
end

Nav.makePinionQuestStepSection = function(parent, titleText, layoutOrder, mode, stepKey, withTeleport, withCompleteButton, teleportHandler, questNamespace)
    questNamespace = questNamespace or "pinion"
    withCompleteButton = withCompleteButton ~= false
    local sectionHeight = 56
    local statusHeight = sectionHeight - 24

    local rightPad = 8
    if withTeleport and withCompleteButton then
        rightPad = 242
    elseif withCompleteButton then
        rightPad = 166
    elseif withTeleport then
        rightPad = 92
    end

    local section = Instance.new("Frame")
    section.Name = "Section_" .. mode
    section.Size = UDim2.new(1, 0, 0, sectionHeight)
    section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -rightPad, 0, 16)
    title.Position = UDim2.fromOffset(8, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(200, 210, 225)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = titleText
    title.Parent = section

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -rightPad, 0, statusHeight)
    status.Position = UDim2.fromOffset(8, 20)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(170, 178, 195)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = "—"
    status.Parent = section

    hudRefs.statusLabels[mode] = status

    if withTeleport then
        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "Teleport_" .. mode
        tpBtn.Size = UDim2.fromOffset(72, 24)
        tpBtn.Position = UDim2.new(1, -234, 0, 16)
        tpBtn.BackgroundColor3 = Color3.fromRGB(46, 120, 180)
        tpBtn.BorderSizePixel = 0
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 10
        tpBtn.TextColor3 = Color3.new(1, 1, 1)
        tpBtn.Text = "Teleportar"
        tpBtn.Parent = section

        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 6)
        tpCorner.Parent = tpBtn

        trackConnection(tpBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                if teleportHandler then
                    teleportHandler()
                else
                    Nav.teleportOnceToMode(mode)
                end
            end)
        end))
    end

    if withCompleteButton then
        local doneBtn = Instance.new("TextButton")
        doneBtn.Name = "Done_" .. stepKey
        doneBtn.Size = UDim2.fromOffset(72, 24)
        doneBtn.Position = UDim2.new(1, -82, 0, 16)
        doneBtn.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
        doneBtn.BorderSizePixel = 0
        doneBtn.Font = Enum.Font.GothamBold
        doneBtn.TextSize = 10
        doneBtn.TextColor3 = Color3.new(1, 1, 1)
        doneBtn.Text = "Concluído"
        doneBtn.Parent = section

        local doneCorner = Instance.new("UICorner")
        doneCorner.CornerRadius = UDim.new(0, 6)
        doneCorner.Parent = doneBtn

        local completeButtons = questNamespace == "duskwire" and hudRefs.duskwireCompleteButtons
            or questNamespace == "tryhard" and hudRefs.tryhardCompleteButtons
            or hudRefs.pinionCompleteButtons
        completeButtons[stepKey] = doneBtn

        trackConnection(doneBtn.MouseButton1Click:Connect(function()
            if questNamespace == "duskwire" then
                Nav.markDuskwireQuestStepComplete(stepKey)
                if Nav.updateDuskwireCompleteButton then
                    Nav.updateDuskwireCompleteButton(stepKey, duskwireQuestProgress[stepKey] == true)
                end
            elseif questNamespace == "tryhard" then
                Nav.markTryhardQuestStepComplete(stepKey)
                if Nav.updateTryhardCompleteButton then
                    Nav.updateTryhardCompleteButton(stepKey, tryhardQuestProgress[stepKey] == true)
                end
            elseif stepKey:sub(1, 7) == "heavens" then
                if Nav.markHeavensStepComplete then
                    Nav.markHeavensStepComplete(stepKey)
                end
                if Nav.updatePinionCompleteButton then
                    Nav.updatePinionCompleteButton(stepKey, pinionHeavensProgress[stepKey] == true)
                end
            else
                Nav.markPinionQuestStepComplete(stepKey)
                if Nav.updatePinionCompleteButton then
                    Nav.updatePinionCompleteButton(stepKey, pinionQuestProgress[stepKey] == true)
                end
            end
        end))

        local undoButtons = questNamespace == "duskwire" and hudRefs.duskwireUndoButtons
            or questNamespace == "tryhard" and hudRefs.tryhardUndoButtons
            or hudRefs.pinionUndoButtons
        local function undoStep(key)
            if questNamespace == "duskwire" then
                Nav.unmarkDuskwireQuestStepComplete(key)
            elseif questNamespace == "tryhard" then
                Nav.unmarkTryhardQuestStepComplete(key)
            else
                Nav.unmarkPinionQuestStepComplete(key)
            end
        end
        Nav.makeQuestUndoButton(
            section,
            stepKey,
            undoButtons,
            UDim2.new(1, -158, 0, 16),
            undoStep
        )
    end

    return section
end

Nav.makeRodProgressionSection = function(parent, layoutOrder)
    local section = Instance.new("Frame")
    section.Name = "Section_rod_progression"
    section.Size = UDim2.new(1, 0, 0, 88)
    section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
    section.BorderSizePixel = 0
    section.LayoutOrder = layoutOrder
    section.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 16)
    title.Position = UDim2.fromOffset(8, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(200, 210, 225)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Progressão Varas (→ Carrot Rod)"
    title.Parent = section

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -16, 0, 40)
    status.Position = UDim2.fromOffset(8, 20)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(170, 178, 195)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = "—"
    status.Parent = section
    hudRefs.statusLabels.rod_progression = status

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.fromOffset(88, 22)
    buyBtn.Position = UDim2.new(1, -184, 0, 62)
    buyBtn.BackgroundColor3 = Color3.fromRGB(55, 110, 200)
    buyBtn.BorderSizePixel = 0
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 10
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Text = "Comprar"
    buyBtn.Parent = section

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyBtn

    local equipBtn = Instance.new("TextButton")
    equipBtn.Size = UDim2.fromOffset(88, 22)
    equipBtn.Position = UDim2.new(1, -92, 0, 62)
    equipBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
    equipBtn.BorderSizePixel = 0
    equipBtn.Font = Enum.Font.GothamBold
    equipBtn.TextSize = 10
    equipBtn.TextColor3 = Color3.new(1, 1, 1)
    equipBtn.Text = "Equipar"
    equipBtn.Parent = section

    local equipCorner = Instance.new("UICorner")
    equipCorner.CornerRadius = UDim.new(0, 6)
    equipCorner.Parent = equipBtn

    trackConnection(buyBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            Nav.purchaseNextRod()
            if updateHudVisuals then updateHudVisuals(true) end
        end)
    end))

    trackConnection(equipBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            Nav.equipBestRod()
        end)
    end))

    return section
end

end -- hud_quest_widgets

do -- hud_create

Nav.createHud = function()
    Nav._hudRefs = hudRefs
    local playerGui = PLAYER:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("NavegacaoHUD")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NavegacaoHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    hudGui = screenGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(360, 590)
    panel.Position = UDim2.fromOffset(16, 80)
    panel.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(55, 60, 72)
    panelStroke.Thickness = 1
    panelStroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 20)
    title.Position = UDim2.fromOffset(8, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(170, 178, 195)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Navegação Manual"
    title.Active = true
    title.Parent = panel

    local destroyBtn = Instance.new("TextButton")
    destroyBtn.Size = UDim2.fromOffset(56, 22)
    destroyBtn.Position = UDim2.new(1, -64, 0, 6)
    destroyBtn.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
    destroyBtn.BorderSizePixel = 0
    destroyBtn.Font = Enum.Font.GothamBold
    destroyBtn.TextSize = 10
    destroyBtn.TextColor3 = Color3.new(1, 1, 1)
    destroyBtn.Text = "Fechar"
    destroyBtn.Parent = panel

    local destroyCorner = Instance.new("UICorner")
    destroyCorner.CornerRadius = UDim.new(0, 6)
    destroyCorner.Parent = destroyBtn

    trackConnection(destroyBtn.MouseButton1Click:Connect(Nav.destroyScript))

    local playerStatus = Instance.new("TextLabel")
    playerStatus.Name = "PlayerStatus"
    playerStatus.Size = UDim2.new(1, -16, 0, 16)
    playerStatus.Position = UDim2.fromOffset(8, 28)
    playerStatus.BackgroundTransparency = 1
    playerStatus.Font = Enum.Font.Gotham
    playerStatus.TextSize = 11
    playerStatus.TextColor3 = Color3.fromRGB(140, 200, 255)
    playerStatus.TextXAlignment = Enum.TextXAlignment.Left
    playerStatus.Text = "Carregando..."
    playerStatus.Parent = panel
    hudRefs.statusLabels.player = playerStatus

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -16, 0, 1)
    divider.Position = UDim2.fromOffset(8, 48)
    divider.BackgroundColor3 = Color3.fromRGB(55, 60, 72)
    divider.BorderSizePixel = 0
    divider.Parent = panel

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -16, 0, 30)
    tabBar.Position = UDim2.fromOffset(8, 52)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = panel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    hudRefs.tabBtnHome = Nav.makeTabButton(tabBar, "HOME", 1)
    hudRefs.tabBtnQuest = Nav.makeTabButton(tabBar, "Quest Rods", 2)

    trackConnection(hudRefs.tabBtnHome.MouseButton1Click:Connect(function()
        Nav.setHudTab("home")
        if updateHudVisuals then updateHudVisuals(true) end
    end))
    trackConnection(hudRefs.tabBtnQuest.MouseButton1Click:Connect(function()
        Nav.setHudTab("quest")
        if updateHudVisuals then updateHudVisuals(true) end
    end))

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -88)
    content.Position = UDim2.fromOffset(8, 86)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = panel

    hudRefs.scrollHome = Nav.makeTabScroll(content)
    hudRefs.scrollHome.Name = "ScrollHome"
    hudRefs.scrollHome.Visible = true

    hudRefs.scrollQuest = Nav.makeTabScroll(content)
    hudRefs.scrollQuest.Name = "ScrollQuest"
    hudRefs.scrollQuest.Visible = false

    -- Aba HOME
    Nav.makeAutoSellSection(hudRefs.scrollHome, 1)
    Nav.makeSection(hudRefs.scrollHome, "FARM", "—", 2, MODES.INITIAL_FARM, 72)
    Nav.makeTeleportSection(hudRefs.scrollHome, "Farm XP", "Apenas teleporte — última área de farm", 3, MODES.XP_FARM)
    Nav.makeTeleportSection(hudRefs.scrollHome, "Enchant (Altar)", "Apenas teleporte ao altar", 4, MODES.ENCHANT)
    Nav.makeTeleportSection(hudRefs.scrollHome, "Comprar Relíquia", "—", 5, MODES.RELIC)

    -- Aba Quest Rods
    Nav.makeRodProgressionSection(hudRefs.scrollQuest, 1)

    local oscarHeader = Instance.new("TextLabel")
    oscarHeader.Size = UDim2.new(1, 0, 0, 18)
    oscarHeader.BackgroundTransparency = 1
    oscarHeader.Font = Enum.Font.GothamBold
    oscarHeader.TextSize = 11
    oscarHeader.TextColor3 = Color3.fromRGB(140, 148, 165)
    oscarHeader.TextXAlignment = Enum.TextXAlignment.Left
    oscarHeader.Text = "Missão Great Rod of Oscar"
    oscarHeader.LayoutOrder = 2
    oscarHeader.Parent = hudRefs.scrollQuest

    local oscarStatus = Instance.new("TextLabel")
    oscarStatus.Name = "OscarStatus"
    oscarStatus.Size = UDim2.new(1, 0, 0, 52)
    oscarStatus.BackgroundTransparency = 1
    oscarStatus.Font = Enum.Font.Gotham
    oscarStatus.TextSize = 10
    oscarStatus.TextColor3 = Color3.fromRGB(170, 178, 195)
    oscarStatus.TextXAlignment = Enum.TextXAlignment.Left
    oscarStatus.TextYAlignment = Enum.TextYAlignment.Top
    oscarStatus.TextWrapped = true
    oscarStatus.Text = "—"
    oscarStatus.LayoutOrder = 3
    oscarStatus.Parent = hudRefs.scrollQuest
    hudRefs.statusLabels.oscar_overview = oscarStatus

    hudRefs.oscarStartRow, hudRefs.oscarStartBtn, hudRefs.oscarRedoBtn = Nav.makeQuestControlRow(hudRefs.scrollQuest, 4, "oscar")

    hudRefs.oscarStepSections[1] = Nav.makeSection(hudRefs.scrollQuest, "Passo 1 — Ir ao NPC", "—", 5, MODES.OSCAR_STEP1)
    hudRefs.oscarStepSections[2] = Nav.makeSection(hudRefs.scrollQuest, "Passo 2 — Ir ao Amulet", "—", 6, MODES.OSCAR_STEP2)
    hudRefs.oscarStepSections[3] = Nav.makeSection(hudRefs.scrollQuest, "Passo 3 — Ir à ROD", "—", 7, MODES.OSCAR_STEP3)

    hudRefs.pinionHeader = Instance.new("TextLabel")
    hudRefs.pinionHeader.Size = UDim2.new(1, 0, 0, 18)
    hudRefs.pinionHeader.BackgroundTransparency = 1
    hudRefs.pinionHeader.Font = Enum.Font.GothamBold
    hudRefs.pinionHeader.TextSize = 11
    hudRefs.pinionHeader.TextColor3 = Color3.fromRGB(140, 148, 165)
    hudRefs.pinionHeader.TextXAlignment = Enum.TextXAlignment.Left
    hudRefs.pinionHeader.Text = "Pinion Aria Rod Quest"
    hudRefs.pinionHeader.LayoutOrder = 7
    hudRefs.pinionHeader.Parent = hudRefs.scrollQuest

    local pinionStatus = Instance.new("TextLabel")
    pinionStatus.Name = "PinionStatus"
    pinionStatus.Size = UDim2.new(1, 0, 0, 36)
    pinionStatus.BackgroundTransparency = 1
    pinionStatus.Font = Enum.Font.Gotham
    pinionStatus.TextSize = 10
    pinionStatus.TextColor3 = Color3.fromRGB(170, 178, 195)
    pinionStatus.TextXAlignment = Enum.TextXAlignment.Left
    pinionStatus.TextYAlignment = Enum.TextYAlignment.Top
    pinionStatus.TextWrapped = true
    pinionStatus.Text = "—"
    pinionStatus.LayoutOrder = 8
    pinionStatus.Parent = hudRefs.scrollQuest
    hudRefs.statusLabels.pinion_overview = pinionStatus

    hudRefs.pinionStartRow, hudRefs.pinionStartBtn, hudRefs.pinionRedoBtn = Nav.makeQuestControlRow(hudRefs.scrollQuest, 9, "pinion")

    hudRefs.pinionStepSections[1] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 1 — Desbloquear Vertigo",
        10,
        MODES.PINION_STEP1,
        "step1",
        true,
        true
    )
    hudRefs.pinionStepSections[2] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 2 — Pegar Isonade",
        11,
        MODES.PINION_STEP2,
        "step2",
        false,
        true
    )
    hudRefs.pinionStepSections[3] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 3 — Completar Bestiário",
        12,
        MODES.PINION_STEP3,
        "step3",
        false,
        true
    )
    hudRefs.pinionStepSections[4] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 4 — The Depths Key",
        13,
        MODES.PINION_STEP4,
        "step4",
        true,
        true,
        Nav.teleportPinionStep4
    )
    hudRefs.pinionStepSections[5] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 5 — Enchant Relic (Chaotic)",
        14,
        MODES.PINION_STEP5,
        "step5",
        true,
        true,
        Nav.teleportPinionStep5
    )
    hudRefs.pinionStepSections[6] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 6 — Quest Dj Spinous",
        15,
        MODES.PINION_STEP6,
        "step6",
        true,
        true
    )
    hudRefs.pinionStepSections[7] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 7 — Pescar Dj Spinous",
        16,
        MODES.PINION_STEP7,
        "step7",
        true,
        true
    )
    hudRefs.pinionStepSections[8] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 8 — Voltar quest Dj Spinous",
        17,
        MODES.PINION_STEP8,
        "step8",
        true,
        true
    )
    hudRefs.pinionStepSections[9] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 9",
        18,
        MODES.PINION_STEP9,
        "step9",
        true,
        true
    )
    hudRefs.pinionStepSections[10] = Nav.makePinionHeavensSteps1to4Section(hudRefs.scrollQuest, 19)
    hudRefs.pinionStepSections[11] = Nav.makePinionHeavensStep5Section(hudRefs.scrollQuest, 20)
    hudRefs.pinionStepSections[12] = Nav.makePinionHeavensStep6Section(hudRefs.scrollQuest, 21)
    hudRefs.pinionStepSections[13] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 11 — Obter Heavenly Harmonic Dove",
        22,
        MODES.PINION_STEP10,
        "step10",
        true,
        true
    )
    hudRefs.pinionStepSections[14] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 12 — Quest Dj Spinous",
        23,
        MODES.PINION_STEP11,
        "step11",
        true,
        true
    )
    hudRefs.pinionStepSections[15] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 13 — Pescar Dj Spinous",
        24,
        MODES.PINION_STEP12,
        "step12",
        true,
        true
    )
    hudRefs.pinionStepSections[16] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 14 — Voltar quest Dj Spinous",
        25,
        MODES.PINION_STEP13,
        "step13",
        true,
        true
    )

    hudRefs.duskwireHeader = Instance.new("TextLabel")
    hudRefs.duskwireHeader.Size = UDim2.new(1, 0, 0, 18)
    hudRefs.duskwireHeader.BackgroundTransparency = 1
    hudRefs.duskwireHeader.Font = Enum.Font.GothamBold
    hudRefs.duskwireHeader.TextSize = 11
    hudRefs.duskwireHeader.TextColor3 = Color3.fromRGB(140, 148, 165)
    hudRefs.duskwireHeader.TextXAlignment = Enum.TextXAlignment.Left
    hudRefs.duskwireHeader.Text = "Duskwire Rod Quest"
    hudRefs.duskwireHeader.LayoutOrder = 26
    hudRefs.duskwireHeader.Parent = hudRefs.scrollQuest

    local duskwireStatus = Instance.new("TextLabel")
    duskwireStatus.Name = "DuskwireStatus"
    duskwireStatus.Size = UDim2.new(1, 0, 0, 36)
    duskwireStatus.BackgroundTransparency = 1
    duskwireStatus.Font = Enum.Font.Gotham
    duskwireStatus.TextSize = 10
    duskwireStatus.TextColor3 = Color3.fromRGB(170, 178, 195)
    duskwireStatus.TextXAlignment = Enum.TextXAlignment.Left
    duskwireStatus.TextYAlignment = Enum.TextYAlignment.Top
    duskwireStatus.TextWrapped = true
    duskwireStatus.Text = "—"
    duskwireStatus.LayoutOrder = 27
    duskwireStatus.Parent = hudRefs.scrollQuest
    hudRefs.statusLabels.duskwire_overview = duskwireStatus

    hudRefs.duskwireStartRow, hudRefs.duskwireStartBtn, hudRefs.duskwireRedoBtn = Nav.makeQuestControlRow(hudRefs.scrollQuest, 28, "duskwire")

    hudRefs.duskwireStepSections[1] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 1 — Obter quest Duskwire",
        29,
        MODES.DUSKWIRE_STEP1,
        "step1",
        true,
        true,
        nil,
        "duskwire"
    )
    hudRefs.duskwireStepSections[2] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 2 — Pescar Catfish",
        30,
        MODES.DUSKWIRE_STEP2,
        "step2",
        true,
        true,
        nil,
        "duskwire"
    )
    hudRefs.duskwireStepSections[3] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 3 — Entregar missão e obter Duskwire",
        31,
        MODES.DUSKWIRE_STEP3,
        "step3",
        true,
        true,
        nil,
        "duskwire"
    )

    hudRefs.tryhardHeader = Instance.new("TextLabel")
    hudRefs.tryhardHeader.Size = UDim2.new(1, 0, 0, 18)
    hudRefs.tryhardHeader.BackgroundTransparency = 1
    hudRefs.tryhardHeader.Font = Enum.Font.GothamBold
    hudRefs.tryhardHeader.TextSize = 11
    hudRefs.tryhardHeader.TextColor3 = Color3.fromRGB(140, 148, 165)
    hudRefs.tryhardHeader.TextXAlignment = Enum.TextXAlignment.Left
    hudRefs.tryhardHeader.Text = "TryHard Rod Quest"
    hudRefs.tryhardHeader.LayoutOrder = 32
    hudRefs.tryhardHeader.Parent = hudRefs.scrollQuest

    local tryhardStatus = Instance.new("TextLabel")
    tryhardStatus.Name = "TryhardStatus"
    tryhardStatus.Size = UDim2.new(1, 0, 0, 36)
    tryhardStatus.BackgroundTransparency = 1
    tryhardStatus.Font = Enum.Font.Gotham
    tryhardStatus.TextSize = 10
    tryhardStatus.TextColor3 = Color3.fromRGB(170, 178, 195)
    tryhardStatus.TextXAlignment = Enum.TextXAlignment.Left
    tryhardStatus.TextYAlignment = Enum.TextYAlignment.Top
    tryhardStatus.TextWrapped = true
    tryhardStatus.Text = "—"
    tryhardStatus.LayoutOrder = 33
    tryhardStatus.Parent = hudRefs.scrollQuest
    hudRefs.statusLabels.tryhard_overview = tryhardStatus

    hudRefs.tryhardStartRow, hudRefs.tryhardStartBtn, hudRefs.tryhardRedoBtn = Nav.makeQuestControlRow(hudRefs.scrollQuest, 34, "tryhard")

    hudRefs.tryhardStepSections[1] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 1 — Obter quest TryHard",
        35,
        MODES.TRYHARD_STEP1,
        "step1",
        true,
        true,
        nil,
        "tryhard"
    )
    hudRefs.tryhardStepSections[2] = Nav.makePinionQuestStepSection(
        hudRefs.scrollQuest,
        "Passo 2 — Ir à pesca (Flimsy Rod)",
        36,
        MODES.TRYHARD_STEP2,
        "step2",
        true,
        true,
        Nav.teleportTryhardStep2,
        "tryhard"
    )

    Nav.setHudTab("home")

    -- Arrastar painel (sem listener global — evita leak e CPU por frame)
    trackConnection(title.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local dragStart = input.Position
        local startPos = panel.Position

        local moveConn
        moveConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                moveConn:Disconnect()
                return
            end
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end)
    end))

    updateHudVisuals(true)

    task.spawn(function()
        local fastTicks = 0
        while scriptAlive and hudGui and hudGui.Parent do
            local farmActive = activeMode == MODES.INITIAL_FARM
            local fastInterval = farmActive and HUD_FAST_UPDATE_INTERVAL_FARM or HUD_FAST_UPDATE_INTERVAL
            local fullInterval = farmActive and HUD_UPDATE_INTERVAL_FARM or HUD_UPDATE_INTERVAL

            fastTicks += 1
            local doFull = fastTicks * fastInterval >= fullInterval
            if doFull then
                fastTicks = 0
                updateHudVisuals(true)
            else
                updateHudVisuals(false)
            end
            task.wait(fastInterval)
        end
    end)

    print("[navegacao] HUD carregado — apenas teleporte, sem ações automáticas.")
    bindQuestUiRefs()
end

end -- hud_create

do -- hud_labels_core

Nav.updateToggleVisuals = function()
    for mode, btn in pairs(hudRefs.toggleButtons) do
        local isActive = mode == MODES.AUTO_SELL and autoSellEnabled or activeMode == mode
        if isActive then
            btn.Text = "ATIVO"
            btn.BackgroundColor3 = Color3.fromRGB(46, 160, 67)
        else
            btn.Text = "INATIVO"
            btn.BackgroundColor3 = Color3.fromRGB(60, 65, 78)
        end
    end
end

Nav.setLabelIfChanged = function(label, text, color)
    if not label then return end
    if label.Text ~= text then label.Text = text end
    if color and label.TextColor3 ~= color then label.TextColor3 = color end
end

Nav.updateStatusLabelsFast = function()
    local level = Nav.getPlayerLevel()
    local coins = Nav.getPlayerCoins()

    Nav.setLabelIfChanged(hudRefs.statusLabels.player, string.format(
        "Level: %s  |  C$: %s",
        level and tostring(level) or "?",
        coins and Nav.formatCoins(coins) or "?"
    ))

    Nav.setLabelIfChanged(
        hudRefs.statusLabels[MODES.AUTO_SELL],
        autoSellEnabled
            and string.format("Vendendo a cada %ds", SELL_ALL_INTERVAL)
            or string.format("Inativo — vende a cada %ds quando ativado", SELL_ALL_INTERVAL),
        autoSellEnabled and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
    )
end

Nav.updateStatusLabelsFarmLight = function()
    Nav.updateStatusLabelsFast()
    local farm = Nav.getInitialFarmStatus()
    Nav.setLabelIfChanged(hudRefs.statusLabels[MODES.INITIAL_FARM], farm.label, farm.color)
end

Nav.updateHomeTabLabels = function()
    local farm = Nav.getInitialFarmStatus()
    Nav.setLabelIfChanged(hudRefs.statusLabels[MODES.INITIAL_FARM], farm.label, farm.color)

    local relic = Nav.getRelicAvailability()
    Nav.setLabelIfChanged(hudRefs.statusLabels[MODES.RELIC], relic.label, relic.color)

    Nav.setLabelIfChanged(
        hudRefs.statusLabels[MODES.ENCHANT],
        "Clique em Teleportar para ir ao altar",
        Color3.fromRGB(170, 178, 195)
    )

    Nav.setLabelIfChanged(
        hudRefs.statusLabels[MODES.XP_FARM],
        "Apenas teleporte — última área de farm (XP)",
        Color3.fromRGB(170, 178, 195)
    )
end

end -- hud_labels_core

do -- hud_labels_quest

Nav.updateQuestRodsTabLabels = function()
    local progText, progColor = Nav.getRodProgressionStatus()
    Nav.setLabelIfChanged(hudRefs.statusLabels.rod_progression, progText, progColor)

    if Nav.updateOscarQuestLabels then Nav.updateOscarQuestLabels() end
    if Nav.updatePinionQuestLabels then Nav.updatePinionQuestLabels() end
    if Nav.updateDuskwireQuestLabels then Nav.updateDuskwireQuestLabels() end
    if Nav.updateTryhardQuestLabels then Nav.updateTryhardQuestLabels() end
end

end -- hud_labels_quest

do -- hud_labels_refresh

updateHudVisuals = function(fullScan)
    Nav.updateToggleVisuals()
    if activeMode == MODES.INITIAL_FARM then
        if not fullScan then return end
        local now = tick()
        if now - lastFarmHudUpdateAt < HUD_UPDATE_INTERVAL_FARM then
            return
        end
        lastFarmHudUpdateAt = now
        Nav.updateStatusLabelsFarmLight()
        if hudRefs.activeHudTab == "quest" then
            Nav.updateQuestRodsTabLabels()
        end
        return
    end
    if fullScan then
        Nav.updateStatusLabelsFull()
    else
        Nav.updateStatusLabelsFast()
    end
end

Nav.updateStatusLabelsFull = function()
    if activeMode == MODES.INITIAL_FARM then
        Nav.updateStatusLabelsFarmLight()
        if hudRefs.activeHudTab == "quest" then
            Nav.updateQuestRodsTabLabels()
        end
        return
    end

    Nav.updateStatusLabelsFast()
    Nav.updateHomeTabLabels()
    Nav.updateQuestRodsTabLabels()
end

end -- hud_labels_refresh

bindQuestUiRefs = function()
    questUi.oscarStartRow = hudRefs.oscarStartRow
    questUi.oscarStartBtn = hudRefs.oscarStartBtn
    questUi.oscarRedoBtn = hudRefs.oscarRedoBtn
    questUi.oscarStepSections = hudRefs.oscarStepSections
    questUi.pinionStartRow = hudRefs.pinionStartRow
    questUi.pinionStartBtn = hudRefs.pinionStartBtn
    questUi.pinionRedoBtn = hudRefs.pinionRedoBtn
    questUi.pinionHeader = hudRefs.pinionHeader
    questUi.pinionStepSections = hudRefs.pinionStepSections
    questUi.pinionCompleteButtons = hudRefs.pinionCompleteButtons
    questUi.pinionUndoButtons = hudRefs.pinionUndoButtons
    questUi.duskwireStartRow = hudRefs.duskwireStartRow
    questUi.duskwireStartBtn = hudRefs.duskwireStartBtn
    questUi.duskwireRedoBtn = hudRefs.duskwireRedoBtn
    questUi.duskwireHeader = hudRefs.duskwireHeader
    questUi.duskwireStepSections = hudRefs.duskwireStepSections
    questUi.duskwireCompleteButtons = hudRefs.duskwireCompleteButtons
    questUi.duskwireUndoButtons = hudRefs.duskwireUndoButtons
    questUi.tryhardStartRow = hudRefs.tryhardStartRow
    questUi.tryhardStartBtn = hudRefs.tryhardStartBtn
    questUi.tryhardRedoBtn = hudRefs.tryhardRedoBtn
    questUi.tryhardHeader = hudRefs.tryhardHeader
    questUi.tryhardStepSections = hudRefs.tryhardStepSections
    questUi.tryhardCompleteButtons = hudRefs.tryhardCompleteButtons
    questUi.tryhardUndoButtons = hudRefs.tryhardUndoButtons
    questUi.statusLabels = hudRefs.statusLabels
end

end -- hud


-- ===== Inicialização =====
Nav.createHud()
Nav.startSellAllLoop()
Nav.startAutoBuyLoop()

trackConnection(PLAYER.CharacterAdded:Connect(function(char)
    CHARACTER = char
    characterCache.value = char
    characterCache.expires = tick() + CHARACTER_CACHE_TTL
    hrpCache.expires = 0
    if activeMode then
        task.defer(function()
            if activeMode then
                Nav.startPositionHold(activeMode)
            end
        end)
    end
end))
