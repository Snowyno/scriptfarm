-- quest_duskwire.lua — Duskwire Rod
-- Uso: loadstring(readfile("quests/quest_duskwire.lua"))(ctx)

return function(ctx)
    local Nav = ctx.Nav
    local S = ctx.S.duskwire
    local ui = ctx.ui
    local C = ctx.C
    local PLAYER = ctx.PLAYER
    local HttpService = ctx.HttpService
    local Workspace = ctx.Workspace
    local canUsePinionFileCache = ctx.helpers.canUsePinionFileCache
    local ensurePinionProgressCacheFolder = ctx.helpers.ensurePinionProgressCacheFolder
    local refreshHud = ctx.refreshHud

    -- quest_cache_duskwire

    local function getDuskwireQuestCachePath()
        return string.format("%s/duskwire_quest_%d.json", C.PINION_PROGRESS_CACHE_FOLDER, PLAYER.UserId)
    end

    local function applyDuskwireQuestProgressFromTable(source)
        if type(source) ~= "table" then return end
        for _, key in ipairs(C.DUSKWIRE_PROGRESS_KEYS) do
            if source[key] == true then
                S.progress[key] = true
            end
        end
        if source.started == true then
            S.started = true
        end
    end

    local function syncDuskwireQuestStartedFromProgress()
        if S.started then return end
        for _, key in ipairs(C.DUSKWIRE_PROGRESS_KEYS) do
            if S.progress[key] then
                S.started = true
                return
            end
        end
    end

    local function getDuskwireQuestWorkspaceCacheFolder(createIfMissing)
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

        local questFolder = userFolder:FindFirstChild("DuskwireQuest")
        if not questFolder and createIfMissing then
            questFolder = Instance.new("Folder")
            questFolder.Name = "DuskwireQuest"
            questFolder.Parent = userFolder
        end
        return questFolder
    end

    local function loadDuskwireQuestProgressFromFileCache()
        if not canUsePinionFileCache() then return false end
        local path = getDuskwireQuestCachePath()
        if not isfile(path) then return false end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(decoded) ~= "table" then return false end

        applyDuskwireQuestProgressFromTable(decoded)
        return true
    end

    local function loadDuskwireQuestProgressFromWorkspaceCache()
        local questFolder = getDuskwireQuestWorkspaceCacheFolder(false)
        if not questFolder then return false end

        local loaded = false
        for _, key in ipairs(C.DUSKWIRE_PROGRESS_KEYS) do
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

    local function buildDuskwireQuestProgressPayload()
        local payload = {}
        for _, key in ipairs(C.DUSKWIRE_PROGRESS_KEYS) do
            payload[key] = S.progress[key] == true
        end
        payload.started = S.started == true
        return payload
    end

    local function saveDuskwireQuestProgressToCache()
        local payload = buildDuskwireQuestProgressPayload()
        local savedFile = false
        local savedWorkspace = false

        if canUsePinionFileCache() then
            ensurePinionProgressCacheFolder()
            savedFile = pcall(function()
                writefile(getDuskwireQuestCachePath(), HttpService:JSONEncode(payload))
            end)
        end

        local questFolder = getDuskwireQuestWorkspaceCacheFolder(true)
        if questFolder then
            savedWorkspace = true
            for _, key in ipairs(C.DUSKWIRE_PROGRESS_KEYS) do
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

    local function loadDuskwireQuestProgressFromCache()
        local loadedFile = loadDuskwireQuestProgressFromFileCache()
        local loadedWorkspace = loadDuskwireQuestProgressFromWorkspaceCache()
        syncDuskwireQuestStartedFromProgress()
        if loadedFile or loadedWorkspace then
            print("[navegacao] Progresso Duskwire Rod restaurado do cache.")
        end
        return loadedFile or loadedWorkspace
    end

    -- core1b3

    local function getDuskwireQuestAvailability()
        local level = Nav.getPlayerLevel()
        local levelOk = level and level >= C.DUSKWIRE_ROD_MIN_LEVEL
        local step1Done = S.progress.step1 == true
        local step2Done = S.progress.step2 == true
        local step3Done = S.progress.step3 == true
        local completed = step3Done

        if completed then
            return {
                available = true,
                completed = true,
                label = "Duskwire Rod — completo",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
            }
        end

        if not levelOk then
            return {
                available = false,
                completed = false,
                label = string.format(
                    "Bloqueada — requer level %d (atual: %s)",
                    C.DUSKWIRE_ROD_MIN_LEVEL,
                    level and tostring(level) or "?"
                ),
                color = Color3.fromRGB(170, 178, 195),
                step1Done = false,
                step2Done = false,
                step3Done = false,
            }
        end

        if not S.started then
            return {
                available = true,
                completed = false,
                label = "Duskwire Rod — clique Iniciar",
                color = Color3.fromRGB(220, 170, 80),
                step1Done = false,
                step2Done = false,
                step3Done = false,
            }
        end

        local progressLabel = "Passo 1 — Obter quest Duskwire"
        if step1Done and not step2Done then
            progressLabel = "Passo 2 — Pescar Catfish"
        elseif step2Done and not step3Done then
            progressLabel = "Passo 3 — Entregar missão e obter Duskwire"
        elseif step1Done and step2Done then
            progressLabel = "Passo 3 — Entregar missão e obter Duskwire"
        end

        return {
            available = true,
            completed = false,
            label = progressLabel,
            color = Color3.fromRGB(220, 170, 80),
            step1Done = step1Done,
            step2Done = step2Done,
            step3Done = step3Done,
        }
    end

    local function getDuskwireQuestStartInfo()
        local duskwire = getDuskwireQuestAvailability()
        if duskwire.completed then
            return { completed = true, started = true, canStart = false, blockedReason = nil }
        end

        local level = Nav.getPlayerLevel()
        local levelOk = level and level >= C.DUSKWIRE_ROD_MIN_LEVEL
        local canStart = levelOk and not S.started
        local blockedReason

        if not S.started and not levelOk then
            blockedReason = string.format(
                "Requer level %d para iniciar (atual: %s)",
                C.DUSKWIRE_ROD_MIN_LEVEL,
                level and tostring(level) or "?"
            )
        end

        return {
            completed = false,
            started = S.started,
            canStart = canStart,
            blockedReason = blockedReason,
        }
    end

    -- hud_quest_actions

    local function clearDuskwireProgressFromKey(stepKey)
        local startIdx
        for i, key in ipairs(C.DUSKWIRE_QUEST_UNDO_ORDER) do
            if key == stepKey then
                startIdx = i
                break
            end
        end
        if not startIdx then return false end
        for i = startIdx, #C.DUSKWIRE_QUEST_UNDO_ORDER do
            S.progress[C.DUSKWIRE_QUEST_UNDO_ORDER[i]] = false
        end
        return true
    end

    local function startDuskwireQuest()
        local info = getDuskwireQuestStartInfo()
        if info.completed or info.started then return end
        if not info.canStart then
            print("[navegacao] Duskwire Rod:", info.blockedReason or "Requisitos não atendidos para iniciar.")
            return
        end
        S.started = true
        S.redoActive = false
        saveDuskwireQuestProgressToCache()
        print("[navegacao] Quest Duskwire Rod iniciada.")
        if refreshHud then refreshHud(true) end
    end

    local function redoDuskwireQuest()
        for _, key in ipairs(C.DUSKWIRE_PROGRESS_KEYS) do
            S.progress[key] = false
        end
        S.started = true
        S.redoActive = true
        saveDuskwireQuestProgressToCache()
        print("[navegacao] Quest Duskwire Rod reiniciada.")
        if refreshHud then refreshHud(true) end
    end

    local function markDuskwireQuestStepComplete(stepKey)
        if stepKey ~= "step1" and stepKey ~= "step2" and stepKey ~= "step3" then return end
        if S.progress[stepKey] then return end
        if not S.started then
            print("[navegacao] Duskwire Rod: inicie a missão antes.")
            return
        end
        if stepKey == "step2" and not S.progress.step1 then
            print("[navegacao] Duskwire Rod: conclua o Passo 1 antes.")
            return
        end
        if stepKey == "step3" and not S.progress.step2 then
            print("[navegacao] Duskwire Rod: conclua o Passo 2 antes.")
            return
        end
        S.progress[stepKey] = true
        if stepKey == "step3" then
            S.redoActive = false
        end
        saveDuskwireQuestProgressToCache()
        print("[navegacao] Duskwire Rod — passo concluído:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    local function unmarkDuskwireQuestStepComplete(stepKey)
        if not clearDuskwireProgressFromKey(stepKey) then return end
        saveDuskwireQuestProgressToCache()
        print("[navegacao] Duskwire Rod — passo desmarcado:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    -- hud_quest_widgets

    local function updateDuskwireCompleteButton(stepKey, done)
        local btn = ui.duskwireCompleteButtons[stepKey]
        if btn then
            btn.Text = "Concluído"
            btn.BackgroundColor3 = done and Color3.fromRGB(46, 160, 67) or Color3.fromRGB(90, 95, 110)
            btn.Active = not done
            btn.AutoButtonColor = not done
        end
        local undoBtn = ui.duskwireUndoButtons[stepKey]
        if undoBtn then
            undoBtn.Active = done == true
            undoBtn.AutoButtonColor = done == true
            undoBtn.BackgroundColor3 = done and Color3.fromRGB(180, 90, 70) or Color3.fromRGB(55, 58, 68)
        end
    end

    -- hud_labels_quest

    local function updateDuskwireQuestLabels()
        local duskwire = getDuskwireQuestAvailability()
        local startInfo = getDuskwireQuestStartInfo()
        local duskwireStarted = startInfo.started == true
        local questsActive = (duskwireStarted and not duskwire.completed) or S.redoActive
        local showStep1 = questsActive and duskwire.available and not duskwire.step1Done
        local showStep2 = questsActive and duskwire.available and duskwire.step1Done and not duskwire.step2Done
        local showStep3 = questsActive and duskwire.available and duskwire.step2Done and not duskwire.step3Done

        Nav.updateQuestControlRow(ui.duskwireStartRow, ui.duskwireStartBtn, ui.duskwireRedoBtn, startInfo, duskwire.completed == true)

        if ui.duskwireHeader then
            ui.duskwireHeader.Visible = true
        end

        if ui.statusLabels.duskwire_overview then
            local overviewHeight = 16
            if not duskwire.completed then
                if not duskwireStarted then
                    overviewHeight = startInfo.canStart and 48 or 36
                else
                    overviewHeight = 36
                end
            else
                overviewHeight = 28
            end
            ui.statusLabels.duskwire_overview.Size = UDim2.new(1, 0, 0, overviewHeight)
        end

        local overviewLabel = duskwire.label
        local overviewColor = duskwire.color
        if not duskwire.completed and not duskwireStarted then
            if startInfo.blockedReason then
                overviewLabel = startInfo.blockedReason
                overviewColor = Color3.fromRGB(170, 178, 195)
            elseif startInfo.canStart then
                overviewLabel = string.format("Requisitos OK — level %d+", C.DUSKWIRE_ROD_MIN_LEVEL) .. "\nClique Iniciar para ver os passos"
                overviewColor = Color3.fromRGB(80, 200, 100)
            end
        end

        Nav.setLabelIfChanged(ui.statusLabels.duskwire_overview, overviewLabel, overviewColor)

        if duskwire.completed and not S.redoActive then
            for _, section in ipairs(ui.duskwireStepSections) do
                section.Visible = false
            end
            return
        end

        if S.redoActive and not duskwire.completed then
            S.redoActive = false
        end

        if not duskwireStarted then
            for _, section in ipairs(ui.duskwireStepSections) do
                section.Visible = false
            end
            return
        end

        for i, section in ipairs(ui.duskwireStepSections) do
            if i == 1 then
                section.Visible = showStep1
            elseif i == 2 then
                section.Visible = showStep2
            elseif i == 3 then
                section.Visible = showStep3
            end
        end

        updateDuskwireCompleteButton("step1", duskwire.step1Done == true)
        updateDuskwireCompleteButton("step2", duskwire.step2Done == true)
        updateDuskwireCompleteButton("step3", duskwire.step3Done == true)

        if showStep1 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.DUSKWIRE_STEP1],
                duskwire.step1Done
                    and "Obter quest Duskwire — concluído"
                    or string.format(
                        "Teleportar — %.2f, %.2f, %.2f",
                        C.DUSKWIRE_STEP1_SPOT.X,
                        C.DUSKWIRE_STEP1_SPOT.Y,
                        C.DUSKWIRE_STEP1_SPOT.Z
                    ),
                duskwire.step1Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep2 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.DUSKWIRE_STEP2],
                duskwire.step2Done
                    and "Pescar Catfish — concluído"
                    or string.format(
                        "Ir pescar Catfish — teleporte: %.2f, %.2f, %.2f",
                        C.DUSKWIRE_STEP2_SPOT.X,
                        C.DUSKWIRE_STEP2_SPOT.Y,
                        C.DUSKWIRE_STEP2_SPOT.Z
                    ),
                duskwire.step2Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep3 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.DUSKWIRE_STEP3],
                duskwire.step3Done
                    and "Entregar missão — concluído"
                    or string.format(
                        "Mesmo local do Passo 1 — teleporte: %.2f, %.2f, %.2f",
                        C.DUSKWIRE_STEP1_SPOT.X,
                        C.DUSKWIRE_STEP1_SPOT.Y,
                        C.DUSKWIRE_STEP1_SPOT.Z
                    ),
                duskwire.step3Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end
    end

    Nav.saveDuskwireQuestProgressToCache = saveDuskwireQuestProgressToCache
    Nav.getDuskwireQuestAvailability = getDuskwireQuestAvailability
    Nav.getDuskwireQuestStartInfo = getDuskwireQuestStartInfo
    Nav.startDuskwireQuest = startDuskwireQuest
    Nav.redoDuskwireQuest = redoDuskwireQuest
    Nav.markDuskwireQuestStepComplete = markDuskwireQuestStepComplete
    Nav.unmarkDuskwireQuestStepComplete = unmarkDuskwireQuestStepComplete
    Nav.updateDuskwireCompleteButton = updateDuskwireCompleteButton
    Nav.updateDuskwireQuestLabels = updateDuskwireQuestLabels

    if ctx.loadCache ~= false then
        loadDuskwireQuestProgressFromCache()
    end
end
