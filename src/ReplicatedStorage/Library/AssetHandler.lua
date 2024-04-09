local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

--==
local AssetHandler = {};


function AssetHandler.init()
	AssetHandler.AssetsFolder = game.ReplicatedStorage:FindFirstChild("Assets"..modGlobalVars.EngineMode);
	AssetHandler.Inited = true;
end

function AssetHandler:Get(name)
	if self.Inited ~= true then AssetHandler.init() end;
	if self.AssetsFolder == nil then return end
	
	return self.AssetsFolder:FindFirstChild(name);
end


return AssetHandler;