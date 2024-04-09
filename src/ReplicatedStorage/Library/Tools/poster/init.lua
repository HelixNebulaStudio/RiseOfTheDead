local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modPoster = require(script:WaitForChild("Poster"));

local remoteSetPoster = modRemotesManager:Get("SetPoster");

local rayParam = RaycastParams.new();
rayParam.FilterType = Enum.RaycastFilterType.Include;
rayParam.IgnoreWater = true;
rayParam.CollisionGroup = "Raycast";

local posterPrefab = script:WaitForChild("PosterModel");
local interactableModule = game.ReplicatedStorage.Prefabs.Objects:WaitForChild("InterfaceInteractable");

if RunService:IsServer() then
	
	function remoteSetPoster.OnServerInvoke(player, action, paramPacket)
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
		
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
	end
end

return function(handler)
	local Tool = {};
	Tool.UseViewmodel = false;
	
	rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain; workspace.Interactables};
	
	function Tool:OnInputEvent(inputData)
		if inputData.InputType ~= "Begin" then return end;
		
		local classPlayer = shared.modPlayers.Get(self.Player);
		if RunService:IsClient() then
			if inputData.KeyIds.KeyFire then
				local modData = require(self.Player:WaitForChild("DataModule"));
				local modCharacter = modData:GetModCharacter();
			
				local mouseProperties = modCharacter.MouseProperties;
				
				inputData.IsActive = self.IsActive;
				
				if self.IsActive then
					local toolModel = self.Prefab;
					
					local placementHighlight;
					local colorPlaceable, colorInvalid = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);
					local isPlaceable = false;
					
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
						while self.IsActive do
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
									self.PosterCFrame = placeCf;
									setHighlightColor(colorPlaceable);
								else
									self.PosterCFrame = nil;
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
					inputData.PosterCFrame = self.PosterCFrame;
				end
				
				return true;
			end
			return false;
		end
		
		-- Server;
		if classPlayer and not classPlayer.IsAlive then return end;
		self.IsActive = inputData.IsActive == true;
		
		if inputData.KeyIds.KeyFire and not self.IsActive and inputData.PosterCFrame then
			modPoster.Spawn(inputData.PosterCFrame, self.Player);
		end
	end
	
	
	setmetatable(Tool, handler);
	return Tool;
end;