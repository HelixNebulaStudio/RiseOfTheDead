local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--[[
	UniverseEvent by 3dsboy08
	
	v1.0.0
--]]

local ESubscriptions = {}
local ECache = {}
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local MessagingService = game:GetService("MessagingService");

if not RunService:IsStudio() then
	task.spawn(function() 
		local subSuccess, subError;
		for a=1, 3 do
			subSuccess, subError = pcall(function()
				MessagingService:SubscribeAsync("ul-master", function(Call)
					if Call == nil then Debugger:Warn("Topic (ul-master) recieved null parameters."); return end;
					local Args = Call.Data
					
					local Guid = table.remove(Args)
					local Name = table.remove(Args)
					local Server = table.remove(Args)
					local FinalArgs = table.remove(Args)
					
					if ESubscriptions[Name] and Server ~= game.JobId and not ECache[Guid] then
						ECache[Guid] = true
						
						ESubscriptions[Name]:Fire(unpack(FinalArgs))
					end
				end)
			end)
			if subSuccess then break; end;
		end
		if not subSuccess then
			task.delay(3, function()
				local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
				local GameAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
				local ver = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
				GameAnalytics:ReportError("UniversalEventBind Error", subError);
				Debugger:Warn("[MSE] "..subError);
			end)
		end
	end)
end

local UEvent =
{
	__index = function(T, K)
		if string.lower(K) == "fire" then
			return function(T2, ...)
				local args = {...};
				local succ, err = pcall(function()
					if not RunService:IsStudio() then
						T.Sent = T.Sent +1;
						MessagingService:PublishAsync("ul-master", {args, game.JobId, T2.Channel, HttpService:GenerateGUID(false) });
					end
				end)
				return succ, err;
			end
			
		elseif K == "Clear" then
			return function()
				T.Sent = 0;
				T.Recieved = 0;
			end
			
		elseif K == "Sent" then
			return T.Sent;
			
		elseif K == "Recieved" then
			return T.Recieved;
		end
		
		return T.Native[K]
	end,
	
	__newindex = function(T, K, V)
		T.Native[K] = V
	end
}

local UCreator =
{
	new = function(Name)
		if not ESubscriptions[Name] then
			ESubscriptions[Name] = Instance.new("BindableEvent")
		end
			
		local Ret = 
		{
			Native = ESubscriptions[Name];
			Channel = Name;
			Sent = 0;
			Recieved = 0;
		}
		
		Ret.Native.Event:Connect(function()
			Ret.Recieved = Ret.Recieved +1;
		end)
		return setmetatable(Ret, UEvent)
	end
}

shared.modUniversalBind = UCreator;
return UCreator
