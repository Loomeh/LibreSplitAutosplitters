process('P3P.exe')

local current = { load = 0 }
local old = { load = 0 }


function state()
    old.load = current.load

    current.load = readAddress("short", "0x9CF134")
end

function isLoading()
    return current.load == 4
end

function update()
    print(current.load)
end