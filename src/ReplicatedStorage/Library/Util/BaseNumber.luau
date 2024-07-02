local BaseNumber = {}

local Symbols = "0123456789abcdefghijklmnopqrstuvwxyz"

BaseNumber.Symbols = Symbols;

function BaseNumber.ToBase(Base10Number: number, k: number)
    local BaseK = ""

    while Base10Number > 0 do
        local n = math.fmod(Base10Number,k) + 1

        BaseK = Symbols:sub(n,n)..BaseK
        Base10Number = math.floor(Base10Number / k)
    end

    return BaseK
end

return BaseNumber;