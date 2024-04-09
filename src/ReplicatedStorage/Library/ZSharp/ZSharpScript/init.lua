local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

local modLoadstring = require(script.Parent:WaitForChild("Loadstring"));

--
local ZSharpScript = {};
ZSharpScript.__index = ZSharpScript;
ZSharpScript.Debugger = Debugger;

ZSharpScript.ConsoleOutput = modEventSignal.new("OnConsoleOutput");

ZSharpScript.Instances = {};
ZSharpScript.InstanceCounter = 0;
--==
for _, src in pairs(script:GetChildren()) do
	if not src:IsA("ModuleScript") then continue end;
	local obj = require(src);
	
	if obj.Init then
		obj.Init(ZSharpScript);
	end
end

function ZSharpScript.Run(zscriptPacket)
	local zEnv = {};
	
	for _, src in pairs(script:GetChildren()) do
		if not src:IsA("ModuleScript") then continue end;
		local obj = require(src);

		obj.Load(ZSharpScript, zEnv);
	end
	
	zEnv.ScriptName = zscriptPacket.Name;
	
	if zscriptPacket.Self then
		for k, v in pairs(zscriptPacket.Self) do
			if zEnv.Self == nil then
				zEnv.Self = {};
			end
			zEnv.Self[k] = v;
		end
	end
	
	local loadFunction, loadFailReason;
		
	local s, e = pcall(function()
		if RunService:IsServer() then
			loadFunction, loadFailReason = loadstring(zscriptPacket.Source);
			if loadFunction then
				setfenv(loadFunction, zEnv);
				loadFunction();
			end
			
		else
			loadFunction, loadFailReason = modLoadstring(zscriptPacket.Source, zEnv);
			if loadFunction then
				loadFunction();
			end
			
		end
	end)
	
	local function extractError(errStr)
		local i, j = string.find(errStr, "ReplicatedStorage.Library.ZSharp");
		if i and j then
			local colonI = j;
			for a=1, 2 do
				colonI = string.find(errStr, ":", colonI+1);
				if colonI then
					j = colonI+1;
				end
			end
		end
		
		local s, e = pcall(function()
			errStr = errStr:sub(0, math.max(i-1, 0))..errStr:sub(j, #errStr);
			errStr = string.gsub(errStr, "compiled%-lua", zEnv.ScriptName);
		end)
		if not s then
			Debugger:Warn("ZSharpScript Error",e)
		end
		
		return errStr;
	end
	
	local errMsg;
	
	if s and loadFailReason then
		errMsg = extractError(loadFailReason);
		error("Compile: "..errMsg, 0);
		
	elseif not s and e then
		errMsg = extractError(e);
		error("Execution: "..errMsg, 0);
		
	end
end

return ZSharpScript;