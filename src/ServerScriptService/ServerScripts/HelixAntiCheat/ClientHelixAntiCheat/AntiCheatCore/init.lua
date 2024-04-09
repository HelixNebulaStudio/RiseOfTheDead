local Core = {};
--== Configuration;
--== Script;

Core.Active = {};

Core.Tinker = game.ReplicatedStorage.Remotes:WaitForChild("Tinker");

Core.Oracle = script.Parent:GetAttribute("Oracle");
while Core.Oracle == nil do 
	task.wait();
	Core.Oracle = script.Parent:GetAttribute("Oracle");
end;
script.Parent:SetAttribute("Oracle");

Core.Invoker = Random.new(Core.Oracle);

local modHashLib = require(game.ReplicatedStorage.Library:WaitForChild("Util"):WaitForChild("HashLib"));
local function forge()
	local k = {};
	
	for a=1, 2 do
		table.insert(k, modHashLib.md5(tostring(Core.Invoker:NextInteger(1111111111, 9999999999))));
	end
	
	return k;
end

function Core.Sniper(packet)
	return Core.Tinker:InvokeServer(forge(), "sniper", packet);
end

function Core.Bane()
	Core.Tinker:InvokeServer(forge(), "bane");
end;

for _, module in pairs(script:GetChildren()) do
	local scr = module:IsA("ModuleScript") and require(module) or nil;
	if type(scr) == "function" then
		coroutine.wrap(scr)(Core);
	end;
end

function Core.Tinker.OnClientInvoke(action, ...)
	local rPacket = {
		Key=forge();
	};
	
	if action == "setactive" then
		local moduleId, setActive = ...;
		
		if setActive == nil then
			if Core.Active[moduleId] == true then
				Core.Active[moduleId] = false;
				
			else
				Core.Active[moduleId] = true;
				
			end
		else
			Core.Active[moduleId] = (setActive == true);
		end
		rPacket.Active = Core.Active[moduleId] == true;
		
	elseif action == "getactive" then
		local list = {};
		for mId, bool in pairs(Core.Active) do
			if bool == true then
				table.insert(list, mId);
			end
		end
		
		rPacket.List = list;
		
	end
	
	return rPacket;
end

Core.Tinker.Destroying:Connect(function()
	Core.Bane();
end)
Core.Tinker:GetPropertyChangedSignal("Parent"):Connect(function()
	Core.Bane();
end);

repeat
	Core.Sniper({
		Ability="Ignite";
	});
until game.Players.LocalPlayer:GetAttribute("Ignited") == true;

game.Debris:AddItem(script.Parent, 0);

return true;