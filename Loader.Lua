-- loader.lua — ponto de entrada do script
--
-- Execute no executor (copie e cole):
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Snowyno/scriptfarm/refs/heads/main/loader.lua"))()
--
-- Fluxo:
--   loader.lua  →  HttpGet(main.lua)
--   main.lua    →  HttpGet(cada quest rod)

local BASE = "https://raw.githubusercontent.com/Snowyno/scriptfarm/refs/heads/main"

local SOURCES = {
    -- Script principal (HUD, farm, teleporte)
    main = BASE .. "/main.lua",
    mainFile = "navegacao",

    -- Quest rods (GitHub)
    oscar = BASE .. "/Oscar.lua",
    pinion = BASE .. "/Pinion.lua",
    duskwire = BASE .. "/Duskwire.lua",
    tryhard = BASE .. "/TryHardRod.lua",
}

-- Disponível para navegacao ler as URLs das quests
_G.NAVEGACAO_QUEST_URLS = {
    oscar = SOURCES.oscar,
    pinion = SOURCES.pinion,
    duskwire = SOURCES.duskwire,
    tryhard = SOURCES.tryhard,
}

local function httpGet(url)
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
    local hs = game:GetService("HttpService")
    if hs then
        return hs:GetAsync(url)
    end
    return nil
end

local function loadSource(url, filePath, label)
    local source
    if url and url ~= "" then
        source = httpGet(url)
        if not source then
            warn("[navegacao] Falha ao baixar", label, "de", url)
            return false
        end
    elseif type(readfile) == "function" then
        if type(isfile) == "function" and not isfile(filePath) then
            warn("[navegacao] Arquivo não encontrado:", filePath)
            return false
        end
        source = readfile(filePath)
    else
        warn("[navegacao] Sem readfile/HttpGet para carregar", label)
        return false
    end

    local chunk, err = loadstring(source, "@" .. (url ~= "" and url or filePath))
    if not chunk then
        warn("[navegacao] Erro ao compilar", label, ":", err)
        return false
    end
    local ok, runErr = pcall(chunk)
    if not ok then
        warn("[navegacao] Erro ao executar", label, ":", runErr)
        return false
    end
    return true
end

if not loadSource(SOURCES.main, SOURCES.mainFile, "script principal") then
    warn("[navegacao] Loader abortado.")
end
