local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local BaseInterface = {};
BaseInterface.__index = BaseInterface;

--== Script;

function BaseInterface:Init(Interface)
	Debugger:Log("Init BaseInterface.");
	
	local msrcs = {};
	for _, msrc in pairs(script:GetChildren()) do
		if msrc:IsA("ModuleScript") then
			table.insert(msrcs, {
				Name=("mod"..msrc.Name);
				Msrc=msrc;
				Order=msrc:GetAttribute("LoadOrder") or 999;
			});
		end
	end
	
	table.sort(msrcs, function(a,b) return a.Order < b.Order end)
	for _, s in pairs(msrcs) do
		Interface[s.Name] = require(s.Msrc).init(Interface);
		Debugger:Log("Loaded", s.Name);
	end
end

return BaseInterface;
