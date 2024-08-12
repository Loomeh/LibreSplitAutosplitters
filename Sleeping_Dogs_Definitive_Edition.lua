process('SDHDShip.exe')

local current = { loading }

function state()
    current.loading = readAddress("int", "0x0207B000", "0x260")
end

function isLoading()
    if current.loading == 1 then
        return true
    else
        return false
    end
end