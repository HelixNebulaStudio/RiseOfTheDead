local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modLazyLoader = require(game.ReplicatedStorage.Library.LazyLoader);

local lazyLoader = modLazyLoader.new(script);
lazyLoader.RequestLimit = 20;

local AssetHandler = {
	SharedAssetsFolder=nil;
	ServerAssetsFolder=nil;

	LazyLoader=lazyLoader;
};
--==


local function getDirectory(root, ...)
	local index = 0;
	local dir = nil;

	for _, path in pairs({...}) do
		if index == 0 then
			dir = root;
		end

		dir = dir:FindFirstChild(path);

		if dir == nil then
			return nil;
		end
	end

	return dir;
end

function AssetHandler.init()
	AssetHandler.Inited = true;

	local assetsKey = "Assets"..modGlobalVars.EngineMode;

	AssetHandler.SharedAssetsFolder = game.ReplicatedStorage:FindFirstChild(assetsKey);
	AssetHandler.ServerAssetsFolder = game.ServerStorage:FindFirstChild(assetsKey);
end

function AssetHandler:GetShared(...: string)
	if self.Inited ~= true then AssetHandler.init() end;
	if self.SharedAssetsFolder == nil then return end

	return getDirectory(self.SharedAssetsFolder, ...);
end

function AssetHandler:GetServer(...: string)
	if self.Inited ~= true then AssetHandler.init() end;

	if RunService:IsClient() then 
		local path = table.concat({...}, "/");
		local asset = self:GetShared(path);

		if asset then
			return asset;
		end

		for a=1, 3 do
			lazyLoader:Request(path);
			for a=0, 1, 1/60 do
				task.wait(1/60);
				
				asset = AssetHandler:GetShared(path);
				if asset then return asset end;
			end
			
			asset = AssetHandler:GetShared(path);
			if asset then return asset end;
		end

		return asset;
	end


	if self.ServerAssetsFolder == nil then return end;

	return getDirectory(self.ServerAssetsFolder, ...);
end


if RunService:IsServer() then
	lazyLoader:ConnectOnServerRequested(function(player, key)
		if key == nil then return end;
		local path = string.split(key, "/");

		local asset = AssetHandler:GetServer(path);
		if asset == nil then return end

		local new = asset:Clone();
		new.Parent = player.PlayerGui;

		Debugger.Expire(new, 10);

		return new;
	end)
end
if RunService:IsClient() then
	lazyLoader:ConnectOnClientLoad(function(key: string, obj: Instance)
		if AssetHandler.Inited ~= true then AssetHandler.init() end;
		if key == nil then return end;
	
		if AssetHandler.SharedAssetsFolder:FindFirstChild(key) then return end;

		local folder = Instance.new("Folder");
		folder.Name = key;
		folder.Parent = AssetHandler.SharedAssetsFolder;

		local new = obj:Clone();
		new.Parent = folder;

	end)
end

return AssetHandler;