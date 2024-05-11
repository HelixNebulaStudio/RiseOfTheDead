local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--==
local BitFlags = {};
BitFlags.__index = BitFlags;

function BitFlags.toBin(num)
	local t, rest = {}, nil;
	while num>0 do
		rest=math.fmod(num,2)
		t[#t+1]=rest
		num=(num-rest)/2
	end
	return table.concat(t);
end

function BitFlags.new()
	local self = {
		Pow=0;
		Flags={};
		Names={};
		Size=0;
	};
	
	setmetatable(self, BitFlags);
	return self;
end

function BitFlags:HasFlag(tag)
	return self.Flags[tag];
end

function BitFlags:AddFlag(tag, name)
	self.Flags[tag] = math.pow(2, self.Pow);
	self.Pow = self.Pow +1;
	self.Size = self.Size + self.Flags[tag];
	self.Names[tag] = name or tag;
	return self.Flags[tag];
end

-- bitString: string of bits e.g. 010010010;
-- decimals gets converted to bitstring.

function BitFlags:Test(tag, bitString) -- basically :Get()
	return bit32.btest(bitString, self.Flags[tag]);
end

function BitFlags:Set(bitString, tag, setValue)
	local v = self:Test(tag, bitString);
	if setValue == 1 then setValue = true; end;
	if setValue == v then
		return bitString;
	end
	return bit32.bxor(bitString, self.Flags[tag]);
end

function BitFlags:List(bitString)
	local r = {};
	
	for k,_ in pairs(self.Flags) do
		if self:Test(k, bitString) then
			r[k] = true;
		else
			r[k] = false;
		end
	end
	
	return r;
end

--[[
	Usage:

	local clientBitString = 2; -- bin = 0b0000_0010

	local ActionPermissions = modBitFlags.new();
	ActionPermissions:AddFlag("CanActionA", "Flag Label Action A");
	ActionPermissions:AddFlag("CanActionB", "Flag Label Action B");

	print(ActionPermissions:Test("CanActionA", clientBitString)); -- false;
	print(ActionPermissions:Test("CanActionB", clientBitString)); -- true;

]]

return BitFlags;