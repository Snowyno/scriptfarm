-- quest_pinion.lua — Pinion Aria Rod Quest
-- Uso: loadstring(readfile("quests/quest_pinion.lua"))(ctx)

return function(ctx)
    local Nav = ctx.Nav
    local S = ctx.S.pinion
    local ui = ctx.ui
    local C = ctx.C
    local PLAYER = ctx.PLAYER
    local HttpService = ctx.HttpService
    local Workspace = ctx.Workspace
    local refreshHud = ctx.refreshHud
    local trackConnection = ctx.trackConnection
    local canUsePinionFileCache = ctx.helpers.canUsePinionFileCache
    local ensurePinionProgressCacheFolder = ctx.helpers.ensurePinionProgressCacheFolder

    do -- pinion_cache_pinion

    local function getPinionProgressCachePath()
        return string.format("%s/pinion_quest_%d.json", C.PINION_PROGRESS_CACHE_FOLDER, PLAYER.UserId)
    end

    local function applyPinionQuestProgressFromTable(source)
        if type(source) ~= "table" then return end
        for _, key in ipairs(C.PINION_PROGRESS_KEYS) do
            if source[key] == true then
                S.progress[key] = true
            end
        end
        for _, key in ipairs(C.PINION_HEAVENS_PROGRESS_KEYS) do
            if source[key] == true then
                S.heavens[key] = true
            end
        end
        if source.heavens8 == true then
            S.progress.step11 = true
        end
        if source.step10 == true and source.step11 ~= true then
            S.progress.step11 = true
            S.progress.step10 = false
        end
        if source.started == true then
            S.started = true
        end
    end

    local function syncPinionQuestStartedFromProgress()
        if S.started then return end
        for _, key in ipairs(C.PINION_PROGRESS_KEYS) do
            if S.progress[key] then
                S.started = true
                return
            end
        end
        for _, key in ipairs(C.PINION_HEAVENS_PROGRESS_KEYS) do
            if S.heavens[key] then
                S.started = true
                return
            end
        end
    end

    local function loadPinionQuestProgressFromFileCache()
        if not canUsePinionFileCache() then return false end
        local path = getPinionProgressCachePath()
        if not isfile(path) then return false end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(decoded) ~= "table" then return false end

        applyPinionQuestProgressFromTable(decoded)
        return true
    end

    local function getPinionQuestWorkspaceCacheFolder(createIfMissing)
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

        local questFolder = userFolder:FindFirstChild("PinionQuest")
        if not questFolder and createIfMissing then
            questFolder = Instance.new("Folder")
            questFolder.Name = "PinionQuest"
            questFolder.Parent = userFolder
        end
        return questFolder
    end

    local function loadPinionQuestProgressFromWorkspaceCache()
        local questFolder = getPinionQuestWorkspaceCacheFolder(false)
        if not questFolder then return false end

        local loaded = false
        for _, key in ipairs(C.PINION_PROGRESS_KEYS) do
            local valueObject = questFolder:FindFirstChild(key)
            if valueObject and valueObject:IsA("BoolValue") and valueObject.Value then
                S.progress[key] = true
                loaded = true
            end
        end
        for _, key in ipairs(C.PINION_HEAVENS_PROGRESS_KEYS) do
            local valueObject = questFolder:FindFirstChild(key)
            if valueObject and valueObject:IsA("BoolValue") and valueObject.Value then
                S.heavens[key] = true
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

    local function buildPinionQuestProgressPayload()
        local payload = {}
        for _, key in ipairs(C.PINION_PROGRESS_KEYS) do
            payload[key] = S.progress[key] == true
        end
        for _, key in ipairs(C.PINION_HEAVENS_PROGRESS_KEYS) do
            payload[key] = S.heavens[key] == true
        end
        payload.started = S.started == true
        return payload
    end

    local function savePinionQuestProgressToCache()
        local payload = buildPinionQuestProgressPayload()
        local savedFile = false
        local savedWorkspace = false

        if canUsePinionFileCache() then
            ensurePinionProgressCacheFolder()
            savedFile = pcall(function()
                writefile(getPinionProgressCachePath(), HttpService:JSONEncode(payload))
            end)
        end

        local questFolder = getPinionQuestWorkspaceCacheFolder(true)
        if questFolder then
            savedWorkspace = true
            for _, key in ipairs(C.PINION_PROGRESS_KEYS) do
                local valueObject = questFolder:FindFirstChild(key)
                if not valueObject then
                    valueObject = Instance.new("BoolValue")
                    valueObject.Name = key
                    valueObject.Parent = questFolder
                end
                valueObject.Value = payload[key] == true
            end
            for _, key in ipairs(C.PINION_HEAVENS_PROGRESS_KEYS) do
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

    local function loadPinionQuestProgressFromCache()
        local loadedFile = loadPinionQuestProgressFromFileCache()
        local loadedWorkspace = loadPinionQuestProgressFromWorkspaceCache()
        syncPinionQuestStartedFromProgress()
        if loadedFile or loadedWorkspace then
            print("[navegacao] Progresso Pinion Aria restaurado do cache.")
        end
        return loadedFile or loadedWorkspace
    end

    Nav.savePinionQuestProgressToCache = savePinionQuestProgressToCache
    Nav.loadPinionQuestProgressFromCache = loadPinionQuestProgressFromCache

    end -- pinion_cache_pinion

    do -- pinion_availability

    local function getPinionAriaQuestAvailability()
        local level = Nav.getPlayerLevel()
        local levelOk = level and level >= C.PINION_ARIA_MIN_LEVEL

        local vertigoProgress = levelOk and Nav.getVertigoBestiaryProgress() or nil
        local step3Auto = vertigoProgress ~= nil and (vertigoProgress.percent or 0) >= 100
        local step3Done = S.progress.step3 or step3Auto

        if step3Done then
            S.progress.step1 = true
            S.progress.step2 = true
        end

        local p, h = S.progress, S.heavens
        local step1Done = p.step1 or step3Done
        local step2Done = p.step2 or Nav.hasIsonade() or step3Done
        local heavens1_4Done = h.heavens1 and h.heavens2 and h.heavens3 and h.heavens4
        local heavens5AllDone = h.heavens5_1 and h.heavens5_2 and h.heavens5_3
            and h.heavens5_4 and h.heavens5_5 and h.heavens5_6
        local heavensRodComplete = heavens5AllDone and h.heavens6
        local pinionComplete = heavensRodComplete and p.step10 and p.step11 and p.step12 and p.step13

        local function heavensFields()
            return {
                heavens1Done = h.heavens1,
                heavens2Done = h.heavens2,
                heavens3Done = h.heavens3,
                heavens4Done = h.heavens4,
                heavens1_4Done = heavens1_4Done,
                heavens5_1Done = h.heavens5_1,
                heavens5_2Done = h.heavens5_2,
                heavens5_3Done = h.heavens5_3,
                heavens5_4Done = h.heavens5_4,
                heavens5_5Done = h.heavens5_5,
                heavens5_6Done = h.heavens5_6,
                heavens5AllDone = heavens5AllDone,
                heavens6Done = h.heavens6,
                heavensRodComplete = heavensRodComplete,
                heavensComplete = heavensRodComplete,
                step10Done = p.step10,
                step11Done = p.step11,
                step12Done = p.step12,
                step13Done = p.step13,
                pinionComplete = pinionComplete,
            }
        end

        if not levelOk then
            return {
                available = false,
                completed = false,
                label = string.format(
                    "Bloqueada — requer level %d (atual: %s)",
                    C.PINION_ARIA_MIN_LEVEL,
                    level and tostring(level) or "?"
                ),
                color = Color3.fromRGB(170, 178, 195),
                step1Done = false,
                step2Done = false,
                step3Done = false,
                step4Done = false,
                step5Done = false,
                step6Done = false,
                step7Done = false,
                step8Done = false,
                step9Done = false,
                vertigoProgress = nil,
            }
        end

        if step1Done and step2Done and step3Done and p.step4 and p.step5 and p.step6 and p.step7 and p.step8 and p.step9 then
            if pinionComplete then
                return {
                    available = true,
                    completed = true,
                    label = "Pinion Aria — completo",
                    color = Color3.fromRGB(80, 200, 100),
                    step1Done = true,
                    step2Done = true,
                    step3Done = true,
                    step4Done = true,
                    step5Done = true,
                    step6Done = true,
                    step7Done = true,
                    step8Done = true,
                    step9Done = true,
                    step10Done = true,
                    step11Done = true,
                    step12Done = true,
                    step13Done = true,
                    vertigoProgress = vertigoProgress,
                    heavens = heavensFields(),
                }
            end

            local heavensLabel = "P9 OK — Passo 10: Heaven's Rod — conclua os passos 1 a 4"
            if heavens1_4Done and not heavens5AllDone then
                heavensLabel = "Passo 10.5 — conclua os 6 teleportes"
            elseif heavens5AllDone and not h.heavens6 then
                heavensLabel = "Passo 10.6 — Heaven's Rod final"
            elseif heavensRodComplete and not p.step10 then
                heavensLabel = "Passo 11 — Obter Heavenly Harmonic Dove"
            elseif p.step10 and not p.step11 then
                heavensLabel = "Passo 12 — Quest Dj Spinous (mesmo local do Passo 6)"
            elseif p.step11 and not p.step12 then
                heavensLabel = "Passo 13 — Pescar Dj Spinous"
            elseif p.step12 and not p.step13 then
                heavensLabel = "Passo 14 — Voltar quest Dj Spinous (mesmo local do Passo 12)"
            end

            return {
                available = true,
                completed = false,
                label = heavensLabel,
                color = Color3.fromRGB(220, 170, 80),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = true,
                step5Done = true,
                step6Done = true,
                step7Done = true,
                step8Done = true,
                step9Done = true,
                step10Done = p.step10,
                step11Done = p.step11,
                step12Done = p.step12,
                step13Done = p.step13,
                vertigoProgress = vertigoProgress,
                heavens = heavensFields(),
            }
        end

        if step1Done and step2Done and step3Done and p.step4 and p.step5 and p.step6 and p.step7 and p.step8 then
            return {
                available = true,
                completed = true,
                label = "P8 OK — Passo 9",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = true,
                step5Done = true,
                step6Done = true,
                step7Done = true,
                step8Done = true,
                step9Done = false,
                vertigoProgress = vertigoProgress,
            }
        end

        if step1Done and step2Done and step3Done and p.step4 and p.step5 and p.step6 and p.step7 then
            return {
                available = true,
                completed = true,
                label = "P7 OK — Passo 8: Voltar quest Dj Spinous",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = true,
                step5Done = true,
                step6Done = true,
                step7Done = true,
                step8Done = false,
                step9Done = false,
                vertigoProgress = vertigoProgress,
            }
        end

        if step1Done and step2Done and step3Done and p.step4 and p.step5 and p.step6 then
            return {
                available = true,
                completed = true,
                label = "P6 OK — Passo 7: Pescar Dj Spinous",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = true,
                step5Done = true,
                step6Done = true,
                step7Done = false,
                step8Done = false,
                step9Done = false,
                vertigoProgress = vertigoProgress,
            }
        end

        if step1Done and step2Done and step3Done and p.step4 and p.step5 then
            return {
                available = true,
                completed = true,
                label = "P5 OK — Passo 6: Quest Dj Spinous",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = true,
                step5Done = true,
                step6Done = false,
                step7Done = false,
                step8Done = false,
                step9Done = false,
                vertigoProgress = vertigoProgress,
            }
        end

        if step1Done and step2Done and step3Done and p.step4 then
            return {
                available = true,
                completed = true,
                label = "P4 OK — Passo 5: Enchant Relic (Chaotic)",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = true,
                step5Done = false,
                step6Done = false,
                step7Done = false,
                step8Done = false,
                step9Done = false,
                vertigoProgress = vertigoProgress,
            }
        end

        if step1Done and step2Done and step3Done then
            return {
                available = true,
                completed = true,
                label = "P1-P3 concluídos — Passo 4: The Depths Key",
                color = Color3.fromRGB(80, 200, 100),
                step1Done = true,
                step2Done = true,
                step3Done = true,
                step4Done = false,
                step5Done = false,
                step6Done = false,
                step7Done = false,
                step8Done = false,
                step9Done = false,
                vertigoProgress = vertigoProgress,
            }
        end

        local parts = {}
        if step1Done then
            table.insert(parts, "P1: OK — Vertigo desbloqueado")
        else
            table.insert(parts, "P1: ir ao local e desbloquear Vertigo")
        end
        if step2Done then
            table.insert(parts, "P2: OK — Isonade obtida")
        else
            table.insert(parts, "P2: pegar Isonade (usar Zenith)")
        end
        if step3Done then
            table.insert(parts, "P3: OK — bestiário Vertigo 100%")
        elseif vertigoProgress then
            table.insert(parts, string.format("P3: Atual %s%%", Nav.formatPercent(vertigoProgress.percent)))
        else
            table.insert(parts, "P3: Atual ?% — detectando bestiário Vertigo")
        end

        return {
            available = true,
            completed = false,
            label = table.concat(parts, "\n"),
            color = Color3.fromRGB(220, 170, 80),
            step1Done = step1Done,
            step2Done = step2Done,
            step3Done = step3Done,
            step4Done = p.step4,
            step5Done = p.step5,
            step6Done = p.step6,
            step7Done = p.step7,
            step8Done = p.step8,
            step9Done = p.step9,
            vertigoProgress = vertigoProgress,
        }
    end

    Nav.getPinionAriaQuestAvailability = getPinionAriaQuestAvailability

    end -- pinion_availability

    do -- pinion_start_info

    local function getPinionQuestStartInfo()
        local pinion = Nav.getPinionAriaQuestAvailability()
        if pinion.completed then
            return { completed = true, started = true, canStart = false, blockedReason = nil }
        end

        local level = Nav.getPlayerLevel()
        local levelOk = level and level >= C.PINION_ARIA_MIN_LEVEL
        local canStart = levelOk and not S.started
        local blockedReason

        if not S.started and not levelOk then
            blockedReason = string.format(
                "Requer level %d para iniciar (atual: %s)",
                C.PINION_ARIA_MIN_LEVEL,
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

    Nav.getPinionQuestStartInfo = getPinionQuestStartInfo

    end -- pinion_start_info

    do -- pinion_actions_start

    Nav.startPinionQuest = function()
        local info = Nav.getPinionQuestStartInfo()
        if info.completed or info.started then return end
        if not info.canStart then
            print("[navegacao] Pinion Aria:", info.blockedReason or "Requisitos não atendidos para iniciar.")
            return
        end
        S.started = true
        S.redoActive = false
        if Nav.savePinionQuestProgressToCache then
            Nav.savePinionQuestProgressToCache()
        end
        print("[navegacao] Quest Pinion Aria iniciada.")
        if refreshHud then refreshHud(true) end
    end

    Nav.redoPinionQuest = function()
        for _, key in ipairs(C.PINION_PROGRESS_KEYS) do
            S.progress[key] = false
        end
        for _, key in ipairs(C.PINION_HEAVENS_PROGRESS_KEYS) do
            S.heavens[key] = false
        end
        S.started = true
        S.redoActive = true
        if Nav.savePinionQuestProgressToCache then
            Nav.savePinionQuestProgressToCache()
        end
        print("[navegacao] Quest Pinion Aria reiniciada.")
        if refreshHud then refreshHud(true) end
    end

    end -- pinion_actions_start

    do -- pinion_actions_mark

    Nav.markPinionQuestStepComplete = function(stepKey)
        if stepKey ~= "step1" and stepKey ~= "step2" and stepKey ~= "step3" and stepKey ~= "step4" and stepKey ~= "step5" and stepKey ~= "step6" and stepKey ~= "step7" and stepKey ~= "step8" and stepKey ~= "step9" and stepKey ~= "step10" and stepKey ~= "step11" and stepKey ~= "step12" and stepKey ~= "step13" then return end
        if S.progress[stepKey] then return end
        if stepKey == "step2" and not S.progress.step1 then
            print("[navegacao] Pinion Aria: conclua o Passo 1 antes.")
            return
        end
        if stepKey == "step3" then
            if not S.progress.step1 then
                print("[navegacao] Pinion Aria: conclua o Passo 1 antes.")
                return
            end
            if not S.progress.step2 and not Nav.hasIsonade() then
                print("[navegacao] Pinion Aria: conclua o Passo 2 antes.")
                return
            end
        end
        if stepKey == "step4" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            if not pinion.step3Done then
                print("[navegacao] Pinion Aria: conclua o Passo 3 antes.")
                return
            end
        end
        if stepKey == "step5" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            if not pinion.step4Done then
                print("[navegacao] Pinion Aria: conclua o Passo 4 antes.")
                return
            end
        end
        if stepKey == "step6" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            if not pinion.step5Done then
                print("[navegacao] Pinion Aria: conclua o Passo 5 antes.")
                return
            end
        end
        if stepKey == "step7" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            if not pinion.step6Done then
                print("[navegacao] Pinion Aria: conclua o Passo 6 antes.")
                return
            end
        end
        if stepKey == "step8" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            if not pinion.step7Done then
                print("[navegacao] Pinion Aria: conclua o Passo 7 antes.")
                return
            end
        end
        if stepKey == "step9" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            if not pinion.step8Done then
                print("[navegacao] Pinion Aria: conclua o Passo 8 antes.")
                return
            end
        end
        if stepKey == "step10" then
            local pinion = Nav.getPinionAriaQuestAvailability()
            local heavens = pinion.heavens or {}
            if not heavens.heavensRodComplete then
                print("[navegacao] Pinion Aria: conclua o Passo 10.6 (Heaven's Rod) antes.")
                return
            end
        end
        if stepKey == "step11" then
            if not S.progress.step10 then
                print("[navegacao] Pinion Aria: conclua o Passo 11 antes.")
                return
            end
        end
        if stepKey == "step12" then
            if not S.progress.step11 then
                print("[navegacao] Pinion Aria: conclua o Passo 12 antes.")
                return
            end
        end
        if stepKey == "step13" then
            if not S.progress.step12 then
                print("[navegacao] Pinion Aria: conclua o Passo 13 antes.")
                return
            end
        end
        S.progress[stepKey] = true
        if Nav.savePinionQuestProgressToCache then
            Nav.savePinionQuestProgressToCache()
        end
        print("[navegacao] Pinion Aria — passo concluído:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    end -- pinion_actions_mark

    do -- pinion_actions_unmark

    local function clearPinionProgressFromKey(stepKey)
        local startIdx
        for i, key in ipairs(C.PINION_QUEST_UNDO_ORDER) do
            if key == stepKey then
                startIdx = i
                break
            end
        end
        if not startIdx then return false end
        for i = startIdx, #C.PINION_QUEST_UNDO_ORDER do
            local key = C.PINION_QUEST_UNDO_ORDER[i]
            if key:sub(1, 7) == "heavens" then
                S.heavens[key] = false
            else
                S.progress[key] = false
            end
        end
        return true
    end

    Nav.unmarkPinionQuestStepComplete = function(stepKey)
        if not clearPinionProgressFromKey(stepKey) then return end
        if Nav.savePinionQuestProgressToCache then
            Nav.savePinionQuestProgressToCache()
        end
        print("[navegacao] Pinion Aria — passo desmarcado:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    Nav.unmarkHeavensStepComplete = Nav.unmarkPinionQuestStepComplete

    end -- pinion_actions_unmark

    do -- pinion_widgets_buttons

    Nav.updatePinionCompleteButton = function(stepKey, done)
        local btn = ui.pinionCompleteButtons[stepKey]
        if btn then
            btn.Text = "Concluído"
            btn.BackgroundColor3 = done and Color3.fromRGB(46, 160, 67) or Color3.fromRGB(90, 95, 110)
            btn.Active = not done
            btn.AutoButtonColor = not done
        end
        local undoBtn = ui.pinionUndoButtons[stepKey]
        if undoBtn then
            undoBtn.Active = done == true
            undoBtn.AutoButtonColor = done == true
            undoBtn.BackgroundColor3 = done and Color3.fromRGB(180, 90, 70) or Color3.fromRGB(55, 58, 68)
        end
    end

    Nav.allHeavensSteps1To4Done = function()
        return S.heavens.heavens1
            and S.heavens.heavens2
            and S.heavens.heavens3
            and S.heavens.heavens4
    end

    Nav.allHeavensTeleportsDone = function()
        for _, key in ipairs(C.HEAVENS_STEP5_KEYS) do
            if not S.heavens[key] then
                return false
            end
        end
        return true
    end

    end -- pinion_widgets_buttons

    do -- pinion_widgets_heavens_mark

    Nav.markHeavensStepComplete = function(stepKey)
        local valid = stepKey == "heavens1" or stepKey == "heavens2" or stepKey == "heavens3"
            or stepKey == "heavens4" or stepKey == "heavens6"
        if not valid then
            for _, key in ipairs(C.HEAVENS_STEP5_KEYS) do
                if stepKey == key then
                    valid = true
                    break
                end
            end
        end
        if not valid then return end
        if S.heavens[stepKey] then return end

        local pinion = Nav.getPinionAriaQuestAvailability()
        if not pinion.step9Done then
            print("[navegacao] Heaven's Rod: conclua o Passo 9 antes.")
            return
        end

        if stepKey:sub(1, 9) == "heavens5_" then
            if not Nav.allHeavensSteps1To4Done() then
                print("[navegacao] Heaven's Rod: conclua os passos 1 a 4 antes.")
                return
            end
        elseif stepKey == "heavens6" then
            if not Nav.allHeavensTeleportsDone() then
                print("[navegacao] Heaven's Rod: conclua os 6 teleportes antes.")
                return
            end
        end

        S.heavens[stepKey] = true
        if Nav.savePinionQuestProgressToCache then
            Nav.savePinionQuestProgressToCache()
        end
        print("[navegacao] Heaven's Rod — passo concluído:", stepKey)
        if refreshHud then refreshHud(true) end
    end

    end -- pinion_widgets_heavens_mark

    do -- pinion_widgets_heavens_row

    Nav.makePinionHeavensCompleteRow = function(parent, y, stepKey, labelText)
        local rowHeight = 32

        local row = Instance.new("Frame")
        row.Name = "HeavensRow_" .. stepKey
        row.Size = UDim2.new(1, -16, 0, rowHeight - 2)
        row.Position = UDim2.fromOffset(8, y)
        row.BackgroundTransparency = 1
        row.Parent = parent

        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Size = UDim2.new(1, -166, 1, 0)
        status.BackgroundTransparency = 1
        status.Font = Enum.Font.Gotham
        status.TextSize = 10
        status.TextColor3 = Color3.fromRGB(170, 178, 195)
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextYAlignment = Enum.TextYAlignment.Center
        status.TextWrapped = true
        status.Text = labelText
        status.Parent = row

        local doneBtn = Instance.new("TextButton")
        doneBtn.Name = "Done_" .. stepKey
        doneBtn.Size = UDim2.fromOffset(72, 24)
        doneBtn.Position = UDim2.new(1, -72, 0.5, -12)
        doneBtn.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
        doneBtn.BorderSizePixel = 0
        doneBtn.Font = Enum.Font.GothamBold
        doneBtn.TextSize = 10
        doneBtn.TextColor3 = Color3.new(1, 1, 1)
        doneBtn.Text = "Concluído"
        doneBtn.Parent = row

        local doneCorner = Instance.new("UICorner")
        doneCorner.CornerRadius = UDim.new(0, 6)
        doneCorner.Parent = doneBtn

        ui.pinionCompleteButtons[stepKey] = doneBtn

        trackConnection(doneBtn.MouseButton1Click:Connect(function()
            Nav.markHeavensStepComplete(stepKey)
            Nav.updatePinionCompleteButton(stepKey, S.heavens[stepKey] == true)
        end))

        Nav.makeQuestUndoButton(
            row,
            stepKey,
            ui.pinionUndoButtons,
            UDim2.new(1, -158, 0.5, -12),
            Nav.unmarkHeavensStepComplete
        )

        return row
    end

    Nav.makePinionHeavensSteps1to4Section = function(parent, layoutOrder)
        local rowHeight = 32
        local headerHeight = 22
        local sectionHeight = headerHeight + (4 * rowHeight) + 8

        local section = Instance.new("Frame")
        section.Name = "Section_HeavensSteps1to4"
        section.Size = UDim2.new(1, 0, 0, sectionHeight)
        section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
        section.BorderSizePixel = 0
        section.LayoutOrder = layoutOrder
        section.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = section

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 0, headerHeight)
        title.Position = UDim2.fromOffset(8, 4)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextColor3 = Color3.fromRGB(200, 210, 225)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "Passo 10 — Heaven's Rod (1 a 4)"
        title.Parent = section

        for i = 1, 4 do
            local stepKey = "heavens" .. i
            local y = headerHeight + (i - 1) * rowHeight
            Nav.makePinionHeavensCompleteRow(
                section,
                y,
                stepKey,
                string.format("Passo %d — marcar como concluído", i)
            )
        end

        return section
    end

    end -- pinion_widgets_heavens_row

    do -- pinion_widgets_heavens_step5

    Nav.makePinionHeavensStep5Section = function(parent, layoutOrder)
        local rowHeight = 32
        local headerHeight = 22
        local sectionHeight = headerHeight + (#C.PINION_HEAVENS_ROD_SPOTS * rowHeight) + 8

        local section = Instance.new("Frame")
        section.Name = "Section_HeavensStep5"
        section.Size = UDim2.new(1, 0, 0, sectionHeight)
        section.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
        section.BorderSizePixel = 0
        section.LayoutOrder = layoutOrder
        section.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = section

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 0, headerHeight)
        title.Position = UDim2.fromOffset(8, 4)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextColor3 = Color3.fromRGB(200, 210, 225)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "Passo 10.5 — 6 teleportes"
        title.Parent = section

        for i, spot in ipairs(C.PINION_HEAVENS_ROD_SPOTS) do
            local mode = C.PINION_HEAVENS_MODE_LIST[i]
            local stepKey = C.HEAVENS_STEP5_KEYS[i]
            local y = headerHeight + (i - 1) * rowHeight

            local row = Instance.new("Frame")
            row.Name = "HeavensRow_" .. stepKey
            row.Size = UDim2.new(1, -16, 0, rowHeight - 2)
            row.Position = UDim2.fromOffset(8, y)
            row.BackgroundTransparency = 1
            row.Parent = section

            local status = Instance.new("TextLabel")
            status.Name = "Status"
            status.Size = UDim2.new(1, -248, 1, 0)
            status.BackgroundTransparency = 1
            status.Font = Enum.Font.Gotham
            status.TextSize = 10
            status.TextColor3 = Color3.fromRGB(170, 178, 195)
            status.TextXAlignment = Enum.TextXAlignment.Left
            status.TextYAlignment = Enum.TextYAlignment.Center
            status.TextWrapped = true
            status.Text = string.format(
                "%d — %.2f, %.2f, %.2f",
                i,
                spot.X,
                spot.Y,
                spot.Z
            )
            status.Parent = row
            ui.statusLabels[mode] = status

            local tpBtn = Instance.new("TextButton")
            tpBtn.Name = "Teleport_" .. mode
            tpBtn.Size = UDim2.fromOffset(72, 24)
            tpBtn.Position = UDim2.new(1, -234, 0.5, -12)
            tpBtn.BackgroundColor3 = Color3.fromRGB(46, 120, 180)
            tpBtn.BorderSizePixel = 0
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 10
            tpBtn.TextColor3 = Color3.new(1, 1, 1)
            tpBtn.Text = "Teleportar"
            tpBtn.Parent = row

            local tpCorner = Instance.new("UICorner")
            tpCorner.CornerRadius = UDim.new(0, 6)
            tpCorner.Parent = tpBtn

            trackConnection(tpBtn.MouseButton1Click:Connect(function()
                task.spawn(function()
                    Nav.teleportOnceToMode(mode)
                end)
            end))

            local doneBtn = Instance.new("TextButton")
            doneBtn.Name = "Done_" .. stepKey
            doneBtn.Size = UDim2.fromOffset(72, 24)
            doneBtn.Position = UDim2.new(1, -72, 0.5, -12)
            doneBtn.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
            doneBtn.BorderSizePixel = 0
            doneBtn.Font = Enum.Font.GothamBold
            doneBtn.TextSize = 10
            doneBtn.TextColor3 = Color3.new(1, 1, 1)
            doneBtn.Text = "Concluído"
            doneBtn.Parent = row

            local doneCorner = Instance.new("UICorner")
            doneCorner.CornerRadius = UDim.new(0, 6)
            doneCorner.Parent = doneBtn

            ui.pinionCompleteButtons[stepKey] = doneBtn

            trackConnection(doneBtn.MouseButton1Click:Connect(function()
                Nav.markHeavensStepComplete(stepKey)
                Nav.updatePinionCompleteButton(stepKey, S.heavens[stepKey] == true)
            end))

            Nav.makeQuestUndoButton(
                row,
                stepKey,
                ui.pinionUndoButtons,
                UDim2.new(1, -158, 0.5, -12),
                Nav.unmarkHeavensStepComplete
            )
        end

        return section
    end

    end -- pinion_widgets_heavens_step5

    do -- pinion_widgets_heavens_step6

    Nav.makePinionHeavensStep6Section = function(parent, layoutOrder)
        local mode = C.MODES.PINION_HEAVENS_6
        local stepKey = "heavens6"
        local sectionHeight = 56
        local statusHeight = sectionHeight - 24
        local rightPad = 242

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
        title.Text = "Passo 10.6 — Heaven's Rod final"
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
        status.Text = string.format(
            "Teleportar — %.2f, %.2f, %.2f",
            C.PINION_HEAVENS_FINAL_SPOT.X,
            C.PINION_HEAVENS_FINAL_SPOT.Y,
            C.PINION_HEAVENS_FINAL_SPOT.Z
        )
        status.Parent = section
        ui.statusLabels[mode] = status

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
                Nav.teleportOnceToMode(mode)
            end)
        end))

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

        ui.pinionCompleteButtons[stepKey] = doneBtn

        trackConnection(doneBtn.MouseButton1Click:Connect(function()
            Nav.markHeavensStepComplete(stepKey)
            Nav.updatePinionCompleteButton(stepKey, S.heavens[stepKey] == true)
        end))

        Nav.makeQuestUndoButton(
            section,
            stepKey,
            ui.pinionUndoButtons,
            UDim2.new(1, -158, 0, 16),
            Nav.unmarkHeavensStepComplete
        )

        return section
    end

    end -- pinion_widgets_heavens_step6

    do -- pinion_labels

    Nav.updatePinionQuestLabels = function()
        local pinion = Nav.getPinionAriaQuestAvailability()
        local startInfo = Nav.getPinionQuestStartInfo()
        local heavens = pinion.heavens or {}
        local pinionStarted = startInfo.started == true
        local questsActive = (pinionStarted and not pinion.completed) or S.redoActive
        local showMainSteps = questsActive and pinion.available and not pinion.step9Done
        local showStep4 = questsActive and pinion.available and pinion.step3Done and not pinion.step4Done
        local showStep5 = questsActive and pinion.available and pinion.step4Done and not pinion.step5Done
        local showStep6 = questsActive and pinion.available and pinion.step5Done and not pinion.step6Done
        local showStep7 = questsActive and pinion.available and pinion.step6Done and not pinion.step7Done
        local showStep8 = questsActive and pinion.available and pinion.step7Done and not pinion.step8Done
        local showStep9 = questsActive and pinion.available and pinion.step8Done and not pinion.step9Done
        local showHeavens1_4 = questsActive and pinion.available and pinion.step9Done and not heavens.heavens1_4Done
        local showHeavens5 = questsActive and pinion.available and pinion.step9Done and heavens.heavens1_4Done and not heavens.heavens5AllDone
        local showHeavens6 = questsActive and pinion.available and pinion.step9Done and heavens.heavens5AllDone and not heavens.heavens6Done
        local showStep10 = questsActive and pinion.available and pinion.step9Done and heavens.heavensRodComplete and not pinion.step10Done
        local showStep11 = questsActive and pinion.available and pinion.step9Done and pinion.step10Done and not pinion.step11Done
        local showStep12 = questsActive and pinion.available and pinion.step9Done and pinion.step11Done and not pinion.step12Done
        local showStep13 = questsActive and pinion.available and pinion.step9Done and pinion.step12Done and not pinion.step13Done

        Nav.updateQuestControlRow(ui.pinionStartRow, ui.pinionStartBtn, ui.pinionRedoBtn, startInfo, pinion.completed == true)

        if ui.pinionHeader then
            ui.pinionHeader.Visible = true
        end

        if ui.statusLabels.pinion_overview then
            local overviewHeight = 16
            if not pinion.completed then
                if not pinionStarted then
                    overviewHeight = startInfo.canStart and 48 or 36
                else
                    overviewHeight = pinion.available and 48 or 28
                end
            else
                overviewHeight = 28
            end
            ui.statusLabels.pinion_overview.Size = UDim2.new(1, 0, 0, overviewHeight)
        end

        local overviewLabel = pinion.label
        local overviewColor = pinion.color
        if not pinion.completed and not pinionStarted then
            if startInfo.blockedReason then
                overviewLabel = startInfo.blockedReason
                overviewColor = Color3.fromRGB(170, 178, 195)
            elseif startInfo.canStart then
                overviewLabel = string.format("Requisitos OK — level %d+", C.PINION_ARIA_MIN_LEVEL) .. "\nClique Iniciar para ver os passos"
                overviewColor = Color3.fromRGB(80, 200, 100)
            end
        end

        Nav.setLabelIfChanged(ui.statusLabels.pinion_overview, overviewLabel, overviewColor)

        if pinion.completed and not S.redoActive then
            for _, section in ipairs(ui.pinionStepSections) do
                section.Visible = false
            end
            return
        end

        if S.redoActive and not pinion.completed then
            S.redoActive = false
        end

        if not pinionStarted then
            for _, section in ipairs(ui.pinionStepSections) do
                section.Visible = false
            end
            return
        end

        for i, section in ipairs(ui.pinionStepSections) do
            if i <= 3 then
                section.Visible = showMainSteps
            elseif i == 4 then
                section.Visible = showStep4
            elseif i == 5 then
                section.Visible = showStep5
            elseif i == 6 then
                section.Visible = showStep6
            elseif i == 7 then
                section.Visible = showStep7
            elseif i == 8 then
                section.Visible = showStep8
            elseif i == 9 then
                section.Visible = showStep9
            elseif i == 10 then
                section.Visible = showHeavens1_4
            elseif i == 11 then
                section.Visible = showHeavens5
            elseif i == 12 then
                section.Visible = showHeavens6
            elseif i == 13 then
                section.Visible = showStep10
            elseif i == 14 then
                section.Visible = showStep11
            elseif i == 15 then
                section.Visible = showStep12
            elseif i == 16 then
                section.Visible = showStep13
            end
        end

        Nav.updatePinionCompleteButton("step1", pinion.step1Done)
        Nav.updatePinionCompleteButton("step2", pinion.step2Done)
        Nav.updatePinionCompleteButton("step3", pinion.step3Done)
        Nav.updatePinionCompleteButton("step4", pinion.step4Done)
        Nav.updatePinionCompleteButton("step5", pinion.step5Done)
        Nav.updatePinionCompleteButton("step6", pinion.step6Done)
        Nav.updatePinionCompleteButton("step7", pinion.step7Done)
        Nav.updatePinionCompleteButton("step8", pinion.step8Done)
        Nav.updatePinionCompleteButton("step9", pinion.step9Done)
        Nav.updatePinionCompleteButton("heavens1", heavens.heavens1Done == true)
        Nav.updatePinionCompleteButton("heavens2", heavens.heavens2Done == true)
        Nav.updatePinionCompleteButton("heavens3", heavens.heavens3Done == true)
        Nav.updatePinionCompleteButton("heavens4", heavens.heavens4Done == true)
        Nav.updatePinionCompleteButton("heavens5_1", heavens.heavens5_1Done == true)
        Nav.updatePinionCompleteButton("heavens5_2", heavens.heavens5_2Done == true)
        Nav.updatePinionCompleteButton("heavens5_3", heavens.heavens5_3Done == true)
        Nav.updatePinionCompleteButton("heavens5_4", heavens.heavens5_4Done == true)
        Nav.updatePinionCompleteButton("heavens5_5", heavens.heavens5_5Done == true)
        Nav.updatePinionCompleteButton("heavens5_6", heavens.heavens5_6Done == true)
        Nav.updatePinionCompleteButton("heavens6", heavens.heavens6Done == true)
        Nav.updatePinionCompleteButton("step10", pinion.step10Done == true)
        Nav.updatePinionCompleteButton("step11", pinion.step11Done == true)
        Nav.updatePinionCompleteButton("step12", pinion.step12Done == true)
        Nav.updatePinionCompleteButton("step13", pinion.step13Done == true)

        if showMainSteps then

        Nav.setLabelIfChanged(
            ui.statusLabels[C.MODES.PINION_STEP1],
            pinion.step1Done
                and "Local visitado — bestiário Vertigo desbloqueado"
                or string.format(
                    "Desbloquear Vertigo — coords: %.2f, %.2f, %.2f",
                    C.PINION_VERTIGO_UNLOCK_SPOT.X,
                    C.PINION_VERTIGO_UNLOCK_SPOT.Y,
                    C.PINION_VERTIGO_UNLOCK_SPOT.Z
                ),
            pinion.step1Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
        )

        local hasIsonadeNow = Nav.hasIsonade()
        Nav.setLabelIfChanged(
            ui.statusLabels[C.MODES.PINION_STEP2],
            pinion.step2Done
                and (hasIsonadeNow and "Isonade no inventário" or "Isonade marcada como obtida")
                or (not pinion.step1Done and "Conclua o Passo 1 antes"
                    or "Pegar Isonade — usar Zenith"),
            pinion.step2Done and Color3.fromRGB(80, 200, 100)
                or (pinion.step1Done and Color3.fromRGB(170, 178, 195) or Color3.fromRGB(220, 170, 80))
        )

        Nav.setLabelIfChanged(
            ui.statusLabels[C.MODES.PINION_STEP3],
            pinion.step3Done and "Bestiário Vertigo 100% — completo"
                or (pinion.vertigoProgress and string.format(
                    "Atual: %s%%",
                    Nav.formatPercent(pinion.vertigoProgress.percent)
                ) or "Atual: ?% — detectando bestiário Vertigo"),
            pinion.step3Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
        )
        end

        if showStep4 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP4],
                string.format(
                    "Equipa The Depths Key e teleporta — %.2f, %.2f, %.2f",
                    C.PINION_DEPTHS_KEY_SPOT.X,
                    C.PINION_DEPTHS_KEY_SPOT.Y,
                    C.PINION_DEPTHS_KEY_SPOT.Z
                ),
                Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep5 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP5],
                string.format(
                    "Enchant Relic (Chaotic) — teleporte: %.2f, %.2f, %.2f",
                    C.PINION_ENCHANT_RELIC_SPOT.X,
                    C.PINION_ENCHANT_RELIC_SPOT.Y,
                    C.PINION_ENCHANT_RELIC_SPOT.Z
                ),
                Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep6 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP6],
                string.format(
                    "Obter quest Dj Spinous — teleporte: %.2f, %.2f, %.2f",
                    C.PINION_STEP6_SPOT.X,
                    C.PINION_STEP6_SPOT.Y,
                    C.PINION_STEP6_SPOT.Z
                ),
                Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep7 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP7],
                string.format(
                    "Ir pescar Dj Spinous — teleporte: %.2f, %.2f, %.2f",
                    C.PINION_STEP7_SPOT.X,
                    C.PINION_STEP7_SPOT.Y,
                    C.PINION_STEP7_SPOT.Z
                ),
                Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep8 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP8],
                string.format(
                    "Voltar ao local da quest — teleporte: %.2f, %.2f, %.2f",
                    C.PINION_STEP6_SPOT.X,
                    C.PINION_STEP6_SPOT.Y,
                    C.PINION_STEP6_SPOT.Z
                ),
                Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep9 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP9],
                string.format(
                    "Teleportar — %.2f, %.2f, %.2f",
                    C.PINION_STEP9_SPOT.X,
                    C.PINION_STEP9_SPOT.Y,
                    C.PINION_STEP9_SPOT.Z
                ),
                Color3.fromRGB(170, 178, 195)
            )
        end

        if showHeavens5 then
            for i, mode in ipairs(C.PINION_HEAVENS_MODE_LIST) do
                local spot = C.PINION_HEAVENS_ROD_SPOTS[i]
                local stepKey = C.HEAVENS_STEP5_KEYS[i]
                local done = stepKey and S.heavens[stepKey] == true
                if spot and ui.statusLabels[mode] then
                    Nav.setLabelIfChanged(
                        ui.statusLabels[mode],
                        done
                            and string.format("%d — concluído", i)
                            or string.format(
                                "%d — %.2f, %.2f, %.2f",
                                i,
                                spot.X,
                                spot.Y,
                                spot.Z
                            ),
                        done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
                    )
                end
            end
        end

        if showHeavens6 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_HEAVENS_6],
                heavens.heavens6Done
                    and "Heaven's Rod final — concluído"
                    or string.format(
                        "Teleportar — %.2f, %.2f, %.2f",
                        C.PINION_HEAVENS_FINAL_SPOT.X,
                        C.PINION_HEAVENS_FINAL_SPOT.Y,
                        C.PINION_HEAVENS_FINAL_SPOT.Z
                    ),
                heavens.heavens6Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep10 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP10],
                pinion.step10Done
                    and "Heavenly Harmonic Dove — concluído"
                    or string.format(
                        "Teleportar — %.2f, %.2f, %.2f",
                        C.PINION_HEAVENLY_DOVE_SPOT.X,
                        C.PINION_HEAVENLY_DOVE_SPOT.Y,
                        C.PINION_HEAVENLY_DOVE_SPOT.Z
                    ),
                pinion.step10Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep11 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP11],
                pinion.step11Done
                    and "Quest Dj Spinous — concluído"
                    or string.format(
                        "Mesmo local do Passo 6 — teleporte: %.2f, %.2f, %.2f",
                        C.PINION_STEP6_SPOT.X,
                        C.PINION_STEP6_SPOT.Y,
                        C.PINION_STEP6_SPOT.Z
                    ),
                pinion.step11Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep12 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP12],
                pinion.step12Done
                    and "Pescar Dj Spinous — concluído"
                    or string.format(
                        "Ir pescar Dj Spinous — teleporte: %.2f, %.2f, %.2f",
                        C.PINION_POST_QUEST_FISH_SPOT.X,
                        C.PINION_POST_QUEST_FISH_SPOT.Y,
                        C.PINION_POST_QUEST_FISH_SPOT.Z
                    ),
                pinion.step12Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end

        if showStep13 then
            Nav.setLabelIfChanged(
                ui.statusLabels[C.MODES.PINION_STEP13],
                pinion.step13Done
                    and "Voltar quest Dj Spinous — concluído"
                    or string.format(
                        "Mesmo local do Passo 12 — teleporte: %.2f, %.2f, %.2f",
                        C.PINION_STEP6_SPOT.X,
                        C.PINION_STEP6_SPOT.Y,
                        C.PINION_STEP6_SPOT.Z
                    ),
                pinion.step13Done and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(170, 178, 195)
            )
        end
    end

    end -- pinion_labels

    if ctx.loadCache ~= false then
        Nav.loadPinionQuestProgressFromCache()
    end
end
