process('Quake_Shipping_Playfab_GOG_x64.exe')

local settings =
{
    episodeRun = false, -- Episode Run
    ignoreHub = false, -- Ignore Hub
    ignoreIntermission = false -- Ignore intermissions
}


local current =
{
    map = "",
    intermission = 0,
    menu = 0
}

local old =
{
    map = "",
    intermission = 0,
    menu = 0
}

local vars =
{
    lastMap = "",
    lastVisitedMaps = {},
    fullGameStarts = {"start"},
    fullGameEnds = { "end", "hipend", "r2m8", "e5end", "mgend", "nend" },
    episodeStarts = { "e1m1", "e2m1", "e3m1", "e4m1", "hip1m1", "hip2m1", "hip2m3", "r1m1", "r2m1" },
    episodeEnds = { "e1m7", "e2m6", "e3m6", "e4m7", "hip1m5", "hip2m5", "hipend", "r1m7", "r2m8" }
}

function startup()
    refreshRate = 120
    mapsCacheCycles = 1
end

function state()
    old.map = current.map
    old.intermission = current.intermission
    old.menu = current.menu

    current.map = readAddress("string255", "0x18A4B70")
    current.intermission = readAddress("int", "0x9D9A68C")
    current.menu = readAddress("int", "0xE566F4")
end

function start()
    if settings.episodeRun then
        if indexOf(vars.episodeStarts, current.map) > -1 then
            vars.lastMap = current.map
            return true
        end
    end

    if indexOf(vars.fullGameStarts, current.map) > -1 then
        vars.lastMap = current.map
        return true
    end

    return false
end


function split()
    if settings.episodeRun then
        if (indexOf(vars.episodeEnds, current.map) > -1) and current.intermission > 0 then
            vars.lastVisitedMaps[#vars.lastVisitedMaps + 1] = vars.lastMap .. current.map
            vars.lastMap = current.map
            return true
        end
    end

    if (indexOf(vars.fullGameEnds, current.map) > -1) and current.intermission > 0 then
        vars.lastVisitedMaps[#vars.lastVisitedMaps + 1] = vars.lastMap .. current.map
        vars.lastMap = current.map
        return true
    end

    if old.map ~= current.map and (current.map ~= nil and #current.map > 0) then
        if vars.lastMap ~= current.map and not contains(vars.lastVisitedMaps, vars.lastMap .. current.map) then
            vars.lastVisitedMaps[#vars.lastVisitedMaps + 1] = vars.lastMap .. current.map
            vars.lastMap = current.map
            return true
        end

        vars.lastMap = current.map
    end

    return false
end

function reset()
    if current.menu == 1 and (current.map == nil or #current.map == 0) then
        vars.listVisitedMaps = {}
        return true
    end
end

function isLoading()
    if settings.ignoreHub and (indexOf(vars.fullGameStarts, current.map) > -1) then
        return true
    end

    if settings.ignoreIntermission and current.intermission > 0 then
        return true
    end

    return false
end

-- Helper functions
function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return -1
end

function contains(tbl, element)
    if tbl == nil then
        return false
    end
    for _, value in pairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end