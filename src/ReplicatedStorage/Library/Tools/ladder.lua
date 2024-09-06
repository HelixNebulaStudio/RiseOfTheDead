local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local rayParam = RaycastParams.new();
rayParam.FilterType = Enum.RaycastFilterType.Include;
rayParam.IgnoreWater = true;
rayParam.CollisionGroup = "Raycast";


return function()
	local Tool = {};
	Tool.IsActive = false;
	Tool.UseViewmodel = false;
	
	rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain; workspace.Interactables};
	
	local ladderPrefab = game.ReplicatedStorage.Prefabs.Objects.Ladder;
	local prefabSize = ladderPrefab:GetExtentsSize();
	
	function Tool.OnInputEvent(toolHandler, inputData)
		local maxLadderRange = 24;
		if inputData.InputType ~= "Begin" then return end;
		
		local classPlayer = shared.modPlayers.Get(toolHandler.Player);
		
		local groundCFrame;
		local function getGroundCFrame()
			local rootCFrame = classPlayer.RootPart.CFrame;
			groundCFrame = rootCFrame + rootCFrame.LookVector + Vector3.new(0, -2.4, 0);
			return groundCFrame;
		end
		getGroundCFrame();
		
		local toolConfig = toolHandler.ToolConfig;
		if RunService:IsClient() then
			if inputData.KeyIds.KeyFire then
				local modData = require(toolHandler.Player:WaitForChild("DataModule"));
				local modCharacter = modData:GetModCharacter();
			
				local mouseProperties = modCharacter.MouseProperties;
				
				inputData.IsActive = toolConfig.IsActive;
				
				if toolConfig.IsActive then
					
					local toolModel = toolHandler.Prefab;
					
					local placementHighlight, highlightDescendants;
					local colorPlaceable, colorInvalid = Color3.fromRGB(131, 255, 135), Color3.fromRGB(255, 90, 93);
					local isPlaceable = false;
					
					local function setHighlightColor(color)
						if highlightDescendants == nil then return end;
						for _, obj in pairs(highlightDescendants) do
							if obj:IsA("BasePart") then
								if obj.ClassName == "MeshPart" then
									obj.TextureID = "";
								end
								local surfApp = obj:FindFirstChildWhichIsA("SurfaceAppearance");
								if surfApp then
									surfApp:Destroy();
								end
								obj.Transparency = obj.Name == "Hitbox" and 1 or 0.5;
								obj.Color = color;
								obj.CanCollide = false;
							end
						end
					end
					
					local function createHighlight()
						local new = ladderPrefab:Clone();
						task.delay(60, function()
							if new then
								new:Destroy();
							end
						end)
						new.PrimaryPart.Anchored = true;
						for _, obj in pairs(new:GetDescendants()) do
							if obj:IsA("Decal") or obj:IsA("Texture") then
								obj:Destroy();
							end
						end
						
						return new;
					end
					
					task.spawn(function()
						local lastStrech = 0;
						while toolConfig.IsActive do
							local groundCFrame = getGroundCFrame();
							
							local mouseOrigin=mouseProperties.Focus.p;
							local mouseDirection=mouseProperties.Direction;
							
							local targetDir = mouseDirection*64;
							local raycastResult = workspace:Raycast(mouseOrigin, targetDir, rayParam);
							
							local rayHit, rayPos = nil, (mouseOrigin + targetDir);
							
							if raycastResult then
								rayHit = raycastResult.Instance;
								rayPos = raycastResult.Position;
							end
							
							if placementHighlight == nil then
								placementHighlight = createHighlight();
								task.delay(60, function()
									if placementHighlight then
										placementHighlight:Destroy();
										placementHighlight = nil;
									end
								end)
								highlightDescendants = placementHighlight:GetDescendants();
								
								setHighlightColor(colorPlaceable);
							end
							
							local distance = (rayPos-groundCFrame.p).Magnitude;
							
							if rayHit then
								local strechCount = math.min(math.ceil(distance/prefabSize.Y), maxLadderRange);
								if lastStrech  ~= strechCount then
									for _, obj in pairs(placementHighlight:GetChildren()) do
										if obj.Name == "extension" then
											Debugger.Expire(obj, 0);
										end
									end
									
									if strechCount > 1 then
										for a=2, strechCount do
											local new =	createHighlight();
											new.Name = "extension";
											new.Parent = placementHighlight;
											new:SetPrimaryPartCFrame(placementHighlight:GetPrimaryPartCFrame() * CFrame.new(0, -prefabSize.Y * (a-1), 0));
											
										end
										
										highlightDescendants = placementHighlight:GetDescendants();
										setHighlightColor(colorPlaceable);
									end
								end
								
								placementHighlight:SetPrimaryPartCFrame(CFrame.lookAt(groundCFrame.p, rayPos) 
									* CFrame.Angles(math.rad(90), 0, 0)
									* CFrame.new(0, -prefabSize.Y/2, 0)
								);
								placementHighlight.Parent = workspace.CurrentCamera;
									
								lastStrech = strechCount;
								
								if distance <= maxLadderRange then
									toolConfig.TargetPosition = rayPos;
									setHighlightColor(colorPlaceable);
								else
									toolConfig.TargetPosition = nil;
									setHighlightColor(colorInvalid);
								end
								
							else
								lastStrech = nil;
								if placementHighlight then placementHighlight:Destroy(); placementHighlight = nil; end;
							end
							
							task.wait();
						end
						
						if placementHighlight then placementHighlight:Destroy(); placementHighlight = nil; end;
						Debugger:Log("ladder loop killed");
					end)
					
				else
					inputData.TargetPosition = toolConfig.TargetPosition;
					
				end
				
				return true;
			end
			return false;
		end
		
		-- Server;
		--===
		if classPlayer and not classPlayer.IsAlive then return end;
		toolConfig.IsActive = inputData.IsActive == true;
		
		maxLadderRange = maxLadderRange +2;
		
		if inputData.KeyIds.KeyFire then
			local toolModel = toolHandler.Prefabs[1];
			
			local placed = false;
			if toolConfig.IsActive then
				if toolConfig.PropModel then
					for _, obj in pairs(toolConfig.PropModel:GetChildren()) do
						if obj.Name == "ladderProp" then
							Debugger.Expire(obj, 0);
						end
					end
				end
				
			else
				local rayPos = inputData.TargetPosition;
				
				if rayPos then
					local distance = (rayPos-groundCFrame.p).Magnitude;
					if not shared.IsNan(rayPos) and distance <= maxLadderRange then
						
						local strechCount = math.min(math.ceil(distance/prefabSize.Y), maxLadderRange);
						
						local baseCFrame = CFrame.lookAt(groundCFrame.p, rayPos) 
										* CFrame.Angles(math.rad(90), 0, 0)
										* CFrame.new(0, -prefabSize.Y/2, 0);
						
						if toolConfig.PropModel == nil then
							toolConfig.PropModel = Instance.new("Model");
							toolConfig.PropModel.Name = toolHandler.Player.Name.."_ladder";
							Debugger.Expire(toolConfig.PropModel, 300);
							
							local conn
							conn = toolModel:GetPropertyChangedSignal("Parent"):Connect(function()
								Debugger.Expire(toolConfig.PropModel, 0);
								toolConfig.PropModel = nil;
								conn:Disconnect();
							end)
							
							
							local profile = shared.modProfile:Get(toolHandler.Player);
							if profile and profile.Junk and profile.Junk.CacheInstances then
								table.insert(profile.Junk.CacheInstances, toolConfig.PropModel);
							end
						end
						
						for a=1, math.max(strechCount, 1) do
							local new =	ladderPrefab:Clone();
							
							new.PrimaryPart.Anchored = true;
							
							new.Name = "ladderProp";
							new.Parent = toolConfig.PropModel;
							
							new:SetPrimaryPartCFrame(baseCFrame * CFrame.new(0, -prefabSize.Y * (a-1), 0));
							
						end
						
						toolConfig.PropModel.Parent = workspace.Clips;
						
						toolHandler.Garbage:Tag(function()
							Debugger.Expire(toolConfig.PropModel, 0);
							toolConfig.PropModel = nil;
						end)
						
						placed = true;
					end;
				end
				
			end
			
			local players = modGlobalVars.GetPlayersExlude(toolHandler.Player);
			modReplicationManager:SetClientProperties(players, { -- sets tool properties;
				Instances=toolHandler.Prefabs;
				ClassName={
					BasePart={
						CollisionGroupId=(toolConfig.IsActive and 0 or 10);
						CanCollide=toolConfig.IsActive;
					};
				};
			});
			
			for _, obj in pairs(toolModel:GetChildren()) do
				if obj:IsA("BasePart") then
					obj.Transparency = placed and 1 or 0;
				end
			end
			
		elseif inputData.KeyIds.KeyFocus then
			if not toolConfig.IsActive then return end;
			
			
		end
	end
	
	return Tool;
end;