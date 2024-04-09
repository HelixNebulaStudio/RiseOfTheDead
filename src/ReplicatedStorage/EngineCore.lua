local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
Debugger:InitMainThread();
--==
local RunService = game:GetService("RunService");

local modConst = require(game.ReplicatedStorage.Library.Const);

--==
local EngineCore = {};
EngineCore.IsReady = false;
EngineCore.Players = {};
EngineCore.Funcs = {};

function EngineCore:ProcessPlayerAddedFuncs(player) -- yielding
	if RunService:IsServer() then
		Debugger.AwaitShared("modProfile");
	end
	while EngineCore.IsReady == false and game.Players:IsAncestorOf(player) do
		task.wait();
	end
	
	if not game.Players:IsAncestorOf(player) then return end;
	local playerFuncs = self.Players[player];
	
	for _, funcInfo in pairs(self.Funcs) do
		local src = funcInfo.Src;
		local func = funcInfo.Func;
		
		if func == nil then Debugger:Warn("ProcessPlayerAddFunc Src (",src,") missing Func, funcInfo (",funcInfo,")") continue end;
		if playerFuncs[func] == true then continue end;
		playerFuncs[func] = true;
		
		Debugger:Log("ProcessPlayerAddedFuncs>>", src);
		task.spawn(func, player);
	end
end

local lastConnectTick;
function EngineCore:ConnectOnPlayerAdded(src, func, order)
	table.insert(self.Funcs, {
		Func=func;
		Src=src;
		Order=order or 999;
	});
	table.sort(self.Funcs, function(a, b)
		return a.Order < b.Order;
	end)
	
	if lastConnectTick == nil then
		lastConnectTick = tick();
		task.spawn(function()
			while (tick()-lastConnectTick) <= 1 do
				task.wait();
			end
			
			EngineCore.IsReady = true;
		end)
	end
	lastConnectTick = tick();
	
	for _, player in pairs(game.Players:GetPlayers()) do
		task.spawn(function()
			EngineCore:ProcessPlayerAddedFuncs(player);
		end)
	end
end

function OnPlayerAdded(player)
	if EngineCore.Players[player] then return end;
	EngineCore.Players[player] = {};
	
	EngineCore:ProcessPlayerAddedFuncs(player);
end

game.Players.PlayerRemoving:Connect(function(player)
	if EngineCore.Players[player] then 
		EngineCore.Players[player] = nil;
	end;
end)

for _, player in pairs(game.Players:GetPlayers()) do
	task.spawn(OnPlayerAdded, player);
end
game.Players.PlayerAdded:Connect(OnPlayerAdded);
for _, player in pairs(game.Players:GetPlayers()) do
	task.spawn(OnPlayerAdded, player);
end


return EngineCore;
