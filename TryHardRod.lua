-- quest_tryhard.lua — TryHard Rod
-- Uso: loadstring(readfile("quests/quest_tryhard.lua"))(ctx)

return function(ctx)
    local Nav = ctx.Nav
    local S = ctx.S.tryhard
    local ui = ctx.ui
    local C = ctx.C
    local PLAYER = ctx.PLAYER
    local HttpService = ctx.HttpService
    local Workspace = ctx.Workspace
    local canUsePinionFileCache = ctx.helpers.canUsePinionFileCache
    local ensurePinionProgressCacheFolder = ctx.helpers.ensurePinionProgressCacheFolder
    local refreshHud = ctx.refreshHud

    -- quest_cache_tryhard

    local function getTryhardQuestCachePath()
        return string.format("%s/tryhard_quest_%d.json", C.PINION_PROGRESS_CACHE_FOLDER, PLAYER.UserId)
    end

    local function applyTryhardQuestProgressFromTable(source)
        if type(source) ~= "table" then return end
        for _, key in ipairs(C.TRYHARD_PROGRESS_KEYS) do
            if source[key] == true then
                S.progress[key] = true
            end
        end
        if source.started == true then
            S.started = true
        end
    end

    local function syncTryhardQuestStartedFromProgress()
        if S.started then return end
        for _, key in ipairs(C.TRYHARD_PROGRESS_KEYS) do
            if S.progress[key] then
                S.started = true
                return
            end
        end
    end

    local function getTryhardQuestWorkspaceCacheFolder(createIfMissing)
        local root = Workspace:FindFirstChild(C.PINION_PROGRESS_WORKSPACE_FOLDER)
        if not root and createIfMissing then
            root = Instance.new("Folder")
            root.Name = C.PINION_PROGRESS_WORKSPACE_FOLDER
            root.Parent = Workspace
        end
        if not root then return nil end

        local userFolder = root:FindFirstChild(tostring(PLAYER.UserId))
        if not userFolder and createIfMissing then
            userFolder = Instance.new("Folder")
            userFolder.Name = tostring(PLAYER.UserId)
            userFolder.Parent = root
        end
        if not userFolder then return nil end

        local questFolder = userFolder:FindFirstChild("TryhardQuest")
        if not questFolder and createIfMissing then
            questFolder = Instance.new("Folder")
            questFolder.Name = "TryhardQuest"
            questFolder.Parent = userFolder
        end
        return questFolder
    end

    local function loadTryhardQuestProgressFromFileCache()
        if not canUsePinionFileCache() then return false end
        local path = getTryhardQuestCachePath()
        if not isfile(path) then return false end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(decoded) ~= "table" then return false end

        applyTryhardQuestProgressFromTable(decoded)
        return true
    end

    local function loadTryhardQuestProgressFromWorkspaceCache()
        local questFolder = getTryhardQuestWorkspaceCacheFolder(false)
        if not questFolder then return false end

        local loaded = false
        for _, key in ipairs(C.TRYHARD_PROGRESS_KEYS) do
            local valueObject = questFolder:FindFirstChild(key)
            if valueObject and valueObject:IsA("BoolValue") and valueObject.Value then
                S.progress[key] = true
                loaded = true
            end
        end
        local startedValue = questFolder:FindFirstChild("started")
        if startedValue and startedValue:IsA("BoolValue") and startedValue.Value then
            S.started = true
            loaded = true
        end
        return loaded
    end

    local function buildTryhardQuestProgressPayload()
        local payload = {}
        for _, key in ipairs(C.TRYHARD_PROGRESS_KEYS) do
            payload[key] = S.progress[key] == true
        end
        payload.started = S.started == true
        return payload
    end

    local function saveTryhardQuestProgressToCache()
        local payload = buildTryhardQuestProgressPayload()
        local savedFile = false
        local savedWorkspace = false

        if canUsePinionFileCache() then
            ensurePinionProgressCacheFolder()
            savedFile = pcall(function()
                writefile(getTryhardQuestCachePath(), HttpService:JSONEncode(payload))
            end)
        end

        local questFolder = getTryhardQuestWorkspaceCacheFolder(true)
        if questFolder then
            savedWorkspace = true
            for _, key in ipairs(C.TRYHARD_PROGRESS_KEYS) do
                local valueObject = questFolder:FindFirstChild(key)
                if not valueObject then
                    valueObject = Instance.new("BoolValue")
                    valueObject.Name = key
                    valueObject.Parent = questFolder
                end
                valueObject.Value = payload[key] == true
            end
            local startedValue = questFolder:FindFirstChild("started")
            if not startedValue then
                startedValue = Instance.new("BoolValue")
                startedValue.Name = "started"
                startedValue.Parent = questFolder
            end
            startedValue.Value = payload.started == true
        end

        return savedFile or savedWorkspace
    end

    local function loadTryhardQuestProgressFromCache()
        local loadedFile = loadTryhardQuestProgressFromFileCache()
        local loadedWorkspace = loadTryhardQuestProgressFromWorkspaceCache()
        syncTryhardQuestStartedFromProgress()
        if loadedFile or loadedWorkspace then
            print("[navegacao] Progresso TryHard Rod restaurado do cache.")
        end
        return loadedFile or loadedWorkspace
    end

    -- core1b3

    local function getTryhardQuestAvailability()
        local step1Done = S.progress.step1 == true
        local step2Done = S.progress.step2 == true
        local completed = step2Done

        if completed then
            return {
                available = true,
                completed = true,
                label = "TryHard Rod — completo",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
            }
        end

        if not S.started then
            return {
                available = true,
                completed = false,
                label = "TryHard Rod — clique Iniciar",
                color = Color3.fromRGB(220, 170, 80),
                step1Done = false,
                step2Done = false,
            }
        end

        local progressLabel = "Passo 1 — Obter quest TryHard"
        if step1Done and not step2Done then
            progressLabel = "Passo 2 — Ir à pesca (Flimsy Rod)"
        end

        return {
            available = true,
            completed = false,
            label = progressLabel,
            color = Color3.fromRGB(220, 170, 80),
            step1Done = step1Done,
            step2Done = step2Done,
        }
    end

    local function getTryhardQuestStartInfo()
        local tryhard = getTryhardQuestAvailability()
        if tryhard.completed then
            return { completed = true, started = true, canStart = false, blockedReason = nil }
        end

        return {
            completed = false,
            started = S.started,
            canStart = not S.started,
            blockedReason = nil,
        }
    end

    -- hud_quest_actions

    local function clearTryhardProgressFromKey(stepKey)
        local startIdx
        for i, key in ipairs(C.TRYHARD_QUEST_UNDO_ORDER) do
            if key == stepKey then
                startIdx = i
                break
            end
        end
        if not startIdx then return false end
        for i = startIdx, #C.TRYHARD_QUEST_UNDO_ORDER do
            S.progress[C.TRYHARD_QUEST_UNDO_ORDER[i]] = false
        end
        return true
    end

    local function startTryhardQuest()
        local info = getTryhardQuestStartInfo()
        if info.completed or info.started then return end
        if not info.canStart then
            print("[navegacao] TryHard Rod:", info.blockedReason or "Requisitos não atendidos para iniciar.")
            return
        end
        S.started = true
        S.redoActive = false
        saveTryhardQuestProgressToCache()
        print("[navegacao] Quest TryHard Rod iniciada.")
        if refreshHud then refreshHud(true) end
    end

    local function redoTryhardQuest()
        for _, key in ipairs(C.TRYHARD_PROGRESS_KEYS) do
            S.progress[key] = false
        end
        S.started = true
        S.redoActive = true
        saveTryhardQuestProgressToCache()
        print("[navegacao] Quest TryHard Rod reiniciada.")
        if refreshHud then refreshHud(true) end
    end

    local function markTryhardQuestStepComplete(stepKey)
        if stepKey ~= "step1" and stepKey ~= "step2" then return end
        if S.progress[stepKey] then return end
        if not S.started then
            print("[navegacao] TryHard Rod: inicie a missão antes.")
            return
        end
        if stepKey == "step2" and not S.progress.step1 then
            print("[navegacao] TryHard Rod: conclua o Passo 1 antes.")
            return
        end
        S.progress[stepKey] = true
        if stepKey == "step2" then
            S.redoActive = false
        end
        saveTryhardQuestProgressToCache()
        print("[navegacao] TryHard Rod — passo concluído:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    local function unmarkTryhardQuestStepComplete(stepKey)
        if not clearTryhardProgressFromKey(stepKey) then return end
        saveTryhardQuestProgressToCache()
        print("[navegacao] TryHard Rod — passo desmarcado:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    -- hud_quest_widgets

    local function updateTryhardCompleteButton(stepKey, done)
        local btn = ui.tryhardCompleteButtons[stepKey]
        if btn then
            btn.Text = "Concluído"
            btn.BackgroundColor3 = done and Color3.fromRGB(46, 160, 67) or Color3.fromRGB(90, 95, 110)
            btn.Active = not done
            btn.AutoButtonColor = not done
        end
        local undoBtn = ui.tryhardUndoButtons[stepKey]
        if undoBtn then
            undoBtn.Active = done == true
            undoBtn.AutoButtonColor = done == true
            undoBtn.BackgroundColor3 = done and Color3.fromRGB(180, 90, 70) or Color3.fromRGB(55, 58, 68)
        end
    end

    -- hud_labels_quest

    local function updateTryhardQuestLabels()
        local tryhard = getTryhardQuestAvailability()
        local startInfo = getTryhardQuestStartInfo()
        local tryhardStarted = startInfo.started == true
        local questsActive = (tryhardStarted and not tryhard.completed) or S.redoActive
        local showStep1 = questsActive and tryhard.available and not tryhard.step1Done
        local showStep2 = questsActive and tryhard.available and tryhard.step1Done and not tryhard.step2Done

        Nav.updateQuestControlRow(ui.tryhardStartRow, ui.tryhardStartBtn, ui.tryhardRedoBtn, startInfo, tryhard.completed == true)

        if ui.tryhardHeader then
            ui.tryhardHeader.Visible = true
        end

        if ui.statusLabels.tryhard_overview then
            local overviewHeight = 16
            if not tryhard.completed then
                if not tryhardStarted then
                    overviewHeight = startInfo.canStart and 48 or 36
                else
                    overviewHeight = 36
                end
            else
                overviewHeight = 28
            end
            ui.statusLabels.tryhard_overview.Size = UDim2.new(1, 0, 0, overviewHeight)
        end

        local overviewLabel = tryhard.label
        local overviewColor = tryhard.color
        if not tryhard.completed and not tryhardStarted and startInfo.canStart then
            overviewLabel = "Clique Iniciar para ver os passos"
            overviewColor = Color3.fromRGB(80, 200, 100)
        end

        Nav.setLabelIfChanged(ui.statusLabels.tryhard_overview, overviewLabel, overviewColor)

        if tryhard.completed and not S.redoActive then
            for _, section in ipairs(ui.tryhardStepSections) do
                section.Visible = false
            end
            return
        end

        if S.redoActive and not tryhard.completed then
            S.redoActive = false
        end

        if not tryhardStarted then
            for _, section in ipairs(ui.tryhardStepSections) do
                section.Visible = false
            end
            return
        end

        for i, section in ipairs(ui.tryhardStepSections) do
            if i == 1 then
                section.Visible = showStep1
            elseif i == 2 then
                section.Visible = showStep2
            end
        end

        updateTryhardCompleteButton("step1", tryhard.step1Done == true)
        updateTryhardCompleteButton("step2", tryhard.step2Done == true)

        if showStep1 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.TRYHARD_STEP1],
                tryhard.step1Done
                    and "Obter quest TryHard — concluído"
                    or string.format(
                        "Teleportar — %.2f, %.2f, %.2f",
                        C.TRYHARD_STEP1_SPOT.X,
                        C.TRYHARD_STEP1_SPOT.Y,
                        C.TRYHARD_STEP1_SPOT.Z
                    ),
                tryhard.step1Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep2 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.TRYHARD_STEP2],
                tryhard.step2Done
                    and "Ir à pesca — concluído (Flimsy Rod equipada)"
                    or string.format(
                        "Ir pescar — teleporte: %.2f, %.2f, %.2f\nEquipa Flimsy Rod automaticamente",
                        C.TRYHARD_STEP2_SPOT.X,
                        C.TRYHARD_STEP2_SPOT.Y,
                        C.TRYHARD_STEP2_SPOT.Z
                    ),
                tryhard.step2Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end
    end

    Nav.saveTryhardQuestProgressToCache = saveTryhardQuestProgressToCache
    Nav.getTryhardQuestAvailability = getTryhardQuestAvailability
    Nav.getTryhardQuestStartInfo = getTryhardQuestStartInfo
    Nav.startTryhardQuest = startTryhardQuest
    Nav.redoTryhardQuest = redoTryhardQuest
    Nav.markTryhardQuestStepComplete = markTryhardQuestStepComplete
    Nav.unmarkTryhardQuestStepComplete = unmarkTryhardQuestStepComplete
    Nav.updateTryhardCompleteButton = updateTryhardCompleteButton
    Nav.updateTryhardQuestLabels = updateTryhardQuestLabels

    if ctx.loadCache ~= false then
        loadTryhardQuestProgressFromCache()
    end
end
