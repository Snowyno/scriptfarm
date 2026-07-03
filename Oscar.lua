-- quest_oscar.lua — Great Rod of Oscar
-- Uso: loadstring(readfile("quests/quest_oscar.lua"))(ctx)

return function(ctx)
  local Nav = ctx.Nav
  local S = ctx.S.oscar
  local C = ctx.C
  local ui = ctx.ui
  local helpers = ctx.helpers
  local PLAYER = ctx.PLAYER
  local HttpService = ctx.HttpService
  local refreshHud = ctx.refreshHud

  local function getOscarQuestCachePath()
    return string.format("%s/oscar_quest_%d.json", helpers.PINION_PROGRESS_CACHE_FOLDER, PLAYER.UserId)
  end

  local function loadOscarQuestStartedFromCache()
    if not helpers.canUsePinionFileCache() then return false end
    local path = getOscarQuestCachePath()
    if not isfile(path) then return false end

    local ok, decoded = pcall(function()
      return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(decoded) ~= "table" or decoded.started ~= true then return false end

    S.started = true
    return true
  end

  local function saveOscarQuestStartedToCache()
    if not helpers.canUsePinionFileCache() then return false end
    helpers.ensurePinionProgressCacheFolder()
    return pcall(function()
      writefile(getOscarQuestCachePath(), HttpService:JSONEncode({ started = true }))
    end)
  end

  local function getOscarMissionAvailability()
    if Nav.ownsOscarRod() then
      return {
        completed = true,
        ready = true,
        label = "Concluído",
        color = Color3.fromRGB(80, 200, 100),
      }
    end

    local level = Nav.getPlayerLevel()
    local coins = Nav.getPlayerCoins()
    local amulet = Nav.hasAmulet()

    local levelOkNpc = level and level >= C.POST_XP_MIN_LEVEL
    local coinsOkNpc = coins and coins >= C.POST_XP_MIN_COINS
    local levelOkRod = level and level >= C.OSCAR_ROD_MIN_LEVEL
    local coinsOkRod = coins and coins >= C.OSCAR_ROD_PRICE

    local parts = {}

    if levelOkNpc and coinsOkNpc then
      table.insert(parts, "P1 NPC: OK")
    else
      local lvMiss = level and math.max(C.POST_XP_MIN_LEVEL - level, 0) or C.POST_XP_MIN_LEVEL
      local cMiss = coins and math.max(C.POST_XP_MIN_COINS - coins, 0) or C.POST_XP_MIN_COINS
      table.insert(parts, string.format("P1: lv falta %d, C$ falta %s", lvMiss, Nav.formatCoins(cMiss)))
    end

    if amulet then
      table.insert(parts, "P2 Amulet: OK (tem)")
    else
      table.insert(parts, "P2 Amulet: não possui")
    end

    if levelOkRod and coinsOkRod then
      table.insert(parts, string.format("P3 Rod: OK (C$%s)", Nav.formatCoins(C.OSCAR_ROD_PRICE)))
    else
      local lvMiss = level and math.max(C.OSCAR_ROD_MIN_LEVEL - level, 0) or C.OSCAR_ROD_MIN_LEVEL
      local cMiss = coins and math.max(C.OSCAR_ROD_PRICE - coins, 0) or C.OSCAR_ROD_PRICE
      table.insert(parts, string.format("P3: lv falta %d, C$ falta %s", lvMiss, Nav.formatCoins(cMiss)))
    end

    local allReady = levelOkNpc and coinsOkNpc and amulet and levelOkRod and coinsOkRod
    return {
      ready = allReady,
      label = table.concat(parts, "\n"),
      color = allReady and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(220, 170, 80),
      step1Ready = levelOkNpc and coinsOkNpc,
      step2Ready = true,
      step3Ready = levelOkRod and coinsOkRod and amulet,
    }
  end

  local function getOscarQuestStartInfo()
    if Nav.ownsOscarRod() then
      return { completed = true, started = true, canStart = false, blockedReason = nil }
    end

    local level = Nav.getPlayerLevel()
    local coins = Nav.getPlayerCoins()
    local levelOkNpc = level and level >= C.POST_XP_MIN_LEVEL
    local coinsOkNpc = coins and coins >= C.POST_XP_MIN_COINS
    local canStart = levelOkNpc and coinsOkNpc and not S.started
    local blockedReason

    if not S.started and not canStart then
      if not levelOkNpc and not coinsOkNpc then
        blockedReason = string.format(
          "Requer level %d e C$%s para iniciar",
          C.POST_XP_MIN_LEVEL,
          Nav.formatCoins(C.POST_XP_MIN_COINS)
        )
      elseif not levelOkNpc then
        blockedReason = string.format(
          "Requer level %d para iniciar (atual: %s)",
          C.POST_XP_MIN_LEVEL,
          level and tostring(level) or "?"
        )
      else
        blockedReason = string.format("Requer C$%s para iniciar", Nav.formatCoins(C.POST_XP_MIN_COINS))
      end
    end

    return {
      completed = false,
      started = S.started,
      canStart = canStart,
      blockedReason = blockedReason,
    }
  end

  Nav.saveOscarQuestStartedToCache = saveOscarQuestStartedToCache
  Nav.getOscarMissionAvailability = getOscarMissionAvailability
  Nav.getOscarQuestStartInfo = getOscarQuestStartInfo

  Nav.startOscarQuest = function()
    local info = Nav.getOscarQuestStartInfo()
    if info.completed or info.started then return end
    if not info.canStart then
      print("[navegacao] Oscar:", info.blockedReason or "Requisitos não atendidos para iniciar.")
      return
    end
    S.started = true
    S.redoActive = false
    if Nav.saveOscarQuestStartedToCache then
      Nav.saveOscarQuestStartedToCache()
    end
    print("[navegacao] Missão Great Rod of Oscar iniciada.")
    if refreshHud then refreshHud(true) end
  end

  Nav.redoOscarQuest = function()
    S.redoActive = true
    S.started = true
    print("[navegacao] Missão Oscar — guia reaberto.")
    if refreshHud then refreshHud(true) end
  end

  Nav.updateOscarQuestLabels = function()
    local oscar = Nav.getOscarMissionAvailability()
    local startInfo = Nav.getOscarQuestStartInfo()
    local oscarComplete = oscar.completed == true
    local oscarStarted = startInfo.started == true

    Nav.updateQuestControlRow(ui.oscarStartRow, ui.oscarStartBtn, ui.oscarRedoBtn, startInfo, oscarComplete)

    for _, section in ipairs(ui.oscarStepSections) do
      section.Visible = (oscarStarted and not oscarComplete) or S.redoActive
    end

    if ui.statusLabels.oscar_overview then
      local overviewHeight = 16
      if oscarComplete then
        overviewHeight = 28
      elseif not oscarComplete then
        overviewHeight = oscarStarted and 52 or (startInfo.canStart and 64 or 72)
      end
      ui.statusLabels.oscar_overview.Size = UDim2.new(1, 0, 0, overviewHeight)
    end

    local overviewLabel = oscar.label
    local overviewColor = oscar.color
    if S.redoActive then
      overviewLabel = "Guia reaberto — referência dos passos"
      overviewColor = Color3.fromRGB(220, 170, 80)
    elseif not oscarComplete and not oscarStarted then
      if startInfo.blockedReason then
        overviewLabel = overviewLabel .. "\n" .. startInfo.blockedReason
        overviewColor = Color3.fromRGB(220, 170, 80)
      elseif startInfo.canStart then
        overviewLabel = overviewLabel .. "\nRequisitos OK — clique Iniciar"
        overviewColor = Color3.fromRGB(80, 200, 100)
      end
    end

    Nav.setLabelIfChanged(ui.statusLabels.oscar_overview, overviewLabel, overviewColor)

    if (oscarComplete and not S.redoActive) or not oscarStarted then return end

    Nav.setLabelIfChanged(
      ui.statusLabels[C.MODES.OSCAR_STEP1],
      oscar.step1Ready and "Requisitos P1: OK — lv 250 + C$2.500.000"
        or "Requisitos P1: lv 250 + C$2.500.000 necessários",
      oscar.step1Ready and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(220, 170, 80)
    )

    local hasAmuletNow = Nav.hasAmulet()
    Nav.setLabelIfChanged(
      ui.statusLabels[C.MODES.OSCAR_STEP2],
      hasAmuletNow and "Amulet no inventário" or "Ir coletar o Amulet no local",
      hasAmuletNow and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
    )

    Nav.setLabelIfChanged(
      ui.statusLabels[C.MODES.OSCAR_STEP3],
      oscar.step3Ready
        and string.format("Requisitos P3: OK — lv %d + C$%s + Amulet", C.OSCAR_ROD_MIN_LEVEL, Nav.formatCoins(C.OSCAR_ROD_PRICE))
        or string.format("Requisitos P3: lv %d + C$%s + Amulet", C.OSCAR_ROD_MIN_LEVEL, Nav.formatCoins(C.OSCAR_ROD_PRICE)),
      oscar.step3Ready and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(220, 170, 80)
    )
  end

  if ctx.loadCache ~= false then
    loadOscarQuestStartedFromCache()
  end
end
