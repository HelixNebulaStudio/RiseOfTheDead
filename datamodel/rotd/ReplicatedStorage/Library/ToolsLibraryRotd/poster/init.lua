local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modPoster = shared.require(game.ReplicatedStorage.BaseLibrary.Poster);

local remoteSetPoster = modRemotesManager:Get("SetPoster");

local rayParam = RaycastParams.new();
rayParam.FilterType = Enum.RaycastFilterType.Include;
rayParam.IgnoreWater = true;
rayParam.CollisionGroup = "Raycast";
--==
if RunService:IsServer() then
	
	function remoteSetPoster.OnServerInvoke(player, action, paramPacket)
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
		
		local profile = shared.modProfile:Get(player);
		if profile == nil or profile.Cache == nil then return end;
		
		if action == "set" then
			local posterModel = paramPacket.Poster;
			if posterModel == nil then
				return;
			end
			
			local validId = nil;
			local postersList = modPoster.List;
			for a=1, #postersList do
				if postersList[a].Object == posterModel and postersList[a].Player == player then
					
					if tick()-postersList[a].Tick >= 1 then 
						local decal = posterModel:FindFirstChild("Decal", true);
						if decal then
							local decalId = paramPacket.DecalId;
							
							local productInfo = shared.modAntiCheatService:SafeProductInfo(decalId, Enum.InfoType.Asset, player);
							
							if productInfo then
								local assetId = productInfo.AssetId;
								
								if productInfo.Verifying then
									decal.Texture = productInfo.Placeholder;
									postersList[a].Tick = tick();
									validId = assetId;
									shared.Notify(player, "Decal id is being verified.. ("..modSyncTime.ToString(productInfo.TimeLeft)..")", "Inform");
									
								elseif productInfo.AssetTypeId == 1 then
									decal.Texture = "rbxassetid://"..assetId;
									postersList[a].Tick = tick();
									validId = assetId;
									
								else
									shared.Notify(player, "Invalid decal id.", "Negative");
									
								end
							end
							Debugger:Log("Set Poster id ", decal.Texture);
						end
					end
					break;
				end
			end
			
			if validId ~= nil then
				local posterHistory = modEvents:GetEvent(player, "PosterHistory") or {
					Id="PosterHistory";
					List={};
				};
				
				while #posterHistory.List > 32 do
					table.remove(posterHistory.List, 1);
				end
				for a=#posterHistory.List, 1, -1 do
					if posterHistory.List[a].ImageId == validId then
						table.remove(posterHistory.List, a);
					end
				end
				table.insert(posterHistory.List, {
					ImageId=validId;
				})
				
				modEvents:NewEvent(player, posterHistory);
			end
			
		elseif action == "fetchhistory" then
			return modEvents:GetEvent(player, "PosterHistory");
			
		end

		return;
	end
end


local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=8388875136;};
		Use={Id=8388988860};
	};
	Audio={};
	Configurations={
		UseViewmodel = false;
	};
	Properties={};
};

function toolPackage.OnInputEvent(toolHandler, inputData)
	if inputData.InputType ~= "Begin" then return end;
	
	local posterPrefab = modPoster.Script:WaitForChild("PosterModel");

	local equipmentClass = toolHandler.EquipmentClass;
	local properties = equipmentClass.Properties;

	local classPlayer = shared.modPlayers.get(toolHandler.Player);
	if RunService:IsClient() then
		if inputData.KeyIds.KeyFire then
			local modData = shared.require(toolHandler.Player:WaitForChild("DataModule"));
			local modCharacter = modData:GetModCharacter();
		
			local mouseProperties = modCharacter.MouseProperties;

			inputData.IsActive = properties.IsActive;
			
			if properties.IsActive then
				local placementHighlight;
				local colorPlaceable, colorInvalid = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);
				
				local function setHighlightColor(color)
					if placementHighlight == nil then return end;
					local primaryPart = placementHighlight.PrimaryPart;
					if primaryPart:IsA("BasePart") then
						if primaryPart.ClassName == "MeshPart" then
							primaryPart.TextureID = "";
						end
						primaryPart.Transparency = 0.5;
						primaryPart.Color = color;
						primaryPart.CanCollide = false;
					end
				end
				
				local function createHighlight()
					local new = posterPrefab:Clone();
					task.delay(60, function()
						if new then
							new:Destroy();
						end
					end)
					for _, obj in pairs(new:GetDescendants()) do
						if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ModuleScript") then
							obj:Destroy();
						end
					end
					
					return new;
				end
				
				task.spawn(function()
					rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};
					while properties.IsActive do
						local mouseOrigin=mouseProperties.Focus.p;
						local mouseDirection=mouseProperties.Direction;
						
						local targetDir = mouseDirection*64;
						local raycastResult = workspace:Raycast(mouseOrigin, targetDir, rayParam);
						
						local rayHit, rayPos, rayNormal = nil, (mouseOrigin + targetDir), nil;
						
						if raycastResult then
							rayHit = raycastResult.Instance;
							rayPos = raycastResult.Position;
							rayNormal = raycastResult.Normal;
						end
						
						if placementHighlight == nil then
							placementHighlight = createHighlight();
							task.delay(60, function()
								if placementHighlight then
									placementHighlight:Destroy();
									placementHighlight = nil;
								end
							end)
							
							setHighlightColor(colorPlaceable);
						end
						
						local distance = (rayPos-classPlayer.RootPart.Position).Magnitude;
						
						if rayHit then
							local placeCf = CFrame.lookAt(rayPos, rayPos + rayNormal) * CFrame.new(0, 0, -0.1);
							placementHighlight:SetPrimaryPartCFrame(placeCf);
							placementHighlight.Parent = workspace.CurrentCamera;
							
							if distance <= 25 then
								properties.PosterCFrame = placeCf;
								setHighlightColor(colorPlaceable);
							else
								properties.PosterCFrame = nil;
								setHighlightColor(colorInvalid);
							end
							
						else
							if placementHighlight then placementHighlight:Destroy(); placementHighlight = nil; end;
						end
						
						task.wait();
					end
					
					if placementHighlight then placementHighlight:Destroy(); placementHighlight = nil; end;
					Debugger:Log("poster loop killed");
				end)
				
			else
				inputData.PosterCFrame = properties.PosterCFrame;
			end
			
			return true;
		end
		return false;
	end
	
	-- Server;
	if classPlayer and not classPlayer.IsAlive then return end;
	properties.IsActive = inputData.IsActive == true;
	
	if inputData.KeyIds.KeyFire and not properties.IsActive and inputData.PosterCFrame then
		modPoster.Spawn(inputData.PosterCFrame, toolHandler.Player);
	end
	
	return;
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;