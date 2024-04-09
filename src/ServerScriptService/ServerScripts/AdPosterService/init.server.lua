local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modPoster = require(game.ReplicatedStorage.Library.Tools.poster.Poster);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);

local posterAds = {
	{
		Type="Ad";
		Decal="rbxassetid://9242720986";
		ProductId="poster";
		Interactable="GoldShopInteractable";
	};
	{
		Type="Ad";
		Decal="rbxassetid://11347301232";
		ProductId="communitywaysidemap";
		Interactable="GoldShopInteractable";
	};
	{
		Type="Ad";
		Decal="rbxassetid://12475719198";
		ProductId="communityfissionbaymap";
		Interactable="GoldShopInteractable";
	};
	{
		Type="Ad";
		Decal="rbxassetid://12475719198";
		ProductId="communityrooftopmap";
		Interactable="GoldShopInteractable";
	};
	{
		Type="Leaderboard";
		BackgroundDecal="rbxassetid://11526922873";
		OverlayDecal="rbxassetid://11526924044";
		Key="WeeklyZombieKills";
		Index=1; -- Top Weekly Zombie Killer;
		Message="$Name is currently the top zombie killer this week!";
	};
	{
		Type="Leaderboard";
		BackgroundDecal="rbxassetid://11528060414";
		OverlayDecal="rbxassetid://11528061894";
		Key="WeeklyGoldDonor";
		Index=1; -- Top Weekly Gold Donor;
		Message="$Name is currently the top donor this week!";
	};
	{
		Type="Ad";
		Decal="rbxassetid://14879567830";
		ProductId="communityrooftopmap";
		Interactable="GoldShopInteractable";
	};
}

--== Script;
function modPoster.LoadPosters(model)
	for _, obj in pairs(model:GetDescendants()) do
		if obj.Name == "PosterDecal" then

			local posterData;
			
			for a=1, 5 do
				posterData = posterAds[math.random(1, #posterAds)];
				if posterData.Type == "Ad" then break end;
			end
			
			if posterData.Type == "Ad" then
				obj.Texture = posterData.Decal;

			end
			
		end
	end
	
end

if modConfigurations.DisableWorldAd == true then return end;

local spawnAdPoster;

local posterSpawns = workspace.Debris:FindFirstChild("PosterSpawns");
if posterSpawns then
	local spawnPoints = {};
	for _, model in pairs(posterSpawns:GetChildren()) do
		table.insert(spawnPoints, model:GetPivot());
	end
	posterSpawns:Destroy();
	
	spawnAdPoster = function()
		local pickSpawn --= spawnPoints[math.random(1, #spawnPoints)];
		for a=1, #spawnPoints do
			pickSpawn = spawnPoints[a];

			local overlap = false;
			for _, posterObj in pairs(modPoster.List) do
				if posterObj.Object and (posterObj.Object:GetPivot().Position - pickSpawn.Position).Magnitude <= 2 then
					overlap = true;
					break;
				end
			end

			if not overlap then
				pickSpawn = spawnPoints[a];
				break;
			else
				pickSpawn = nil;
			end
		end
		if pickSpawn == nil then Debugger:Log("No spot for poster.") return end;


		local posterData = posterAds[math.random(1, #posterAds)];


		if posterData.Type == "Ad" then
			local posterObject = modPoster.Spawn(pickSpawn);
			posterObject:SetDecal(posterData.Decal);

			if posterData.Interactable then
				local templateInteractable = script:FindFirstChild(posterData.Interactable);
				local newInteratable = templateInteractable:Clone();
				newInteratable.Name = "Interactable"
				newInteratable:SetAttribute("ProductId", posterData.ProductId);

				newInteratable.Parent = posterObject.Prefab;
			end

		elseif posterData.Type == "Leaderboard" then
			local dataTable = modLeaderboardService:GetTable(posterData.Key);

			local topOne = dataTable[posterData.Index];
			if topOne == nil or topOne.Value <= 0 then return end;
			
			local posterObject = modPoster.Spawn(pickSpawn);
			posterObject:SetDecal("rbxthumb://type=Avatar&id=".. (topOne.UserId or "1") .."&w=720&h=720");
			posterObject:SetBackgroundDecal(posterData.BackgroundDecal);
			posterObject:SetOverlayDecal(posterData.OverlayDecal);
			
			if posterData.Message then
				local msg = string.gsub(posterData.Message, "$Name", topOne.Title or "Someone");
				
				
				local newInteratable = script.MessageInteractable:Clone();
				newInteratable.Name = "Interactable"
				newInteratable:SetAttribute("Message", msg);

				newInteratable.Parent = posterObject.Prefab;
			end
			
		end
	end
	
	game.Players.PlayerAdded:Connect(function()
		spawnAdPoster();
	end)
end



task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("spawnadposter", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = "Spawn ad posters.";

		RequiredArgs = 0;
		UsageInfo = "/spawnadposter";
		Function = function(player, args)
			
			if posterSpawns == nil then
				shared.Notify(player, "No poster spawn locations.", "Inform");
				return;
			end
			
			if spawnAdPoster then
				spawnAdPoster();
				shared.Notify(player, "Spawned poster ad.", "Inform");
			end

			return true;
		end;
	});
end)