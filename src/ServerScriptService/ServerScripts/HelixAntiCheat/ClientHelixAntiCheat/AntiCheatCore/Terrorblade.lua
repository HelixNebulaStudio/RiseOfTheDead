return function(core)
	local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
	local RunService = game:GetService("RunService");
	local localPlayer = game.Players.LocalPlayer;
	
	workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
		local valid = core.Sniper{Ability="BlackHole"; Value=workspace.Gravity;};
		if workspace.Gravity ~= valid then
			workspace.Gravity = valid;
		end
	end)
	
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid");
		local rootPart = character:WaitForChild("HumanoidRootPart");
		local collisionRootPart = character:WaitForChild("CollisionRootPart");
		
		local characterModule;
		while workspace:IsAncestorOf(character) do
			characterModule = character:FindFirstChild("CharacterModule");
			if characterModule == nil then
				task.wait(0.1);
			else
				break;
			end
		end
		if not workspace:IsAncestorOf(character) then return end;
		if characterModule == nil then return end;

		local modCharacter = require(characterModule);
		local characterProperties = modCharacter.CharacterProperties;
		
		local lastCFrame, lastPos, lastVel;
		local threshold = 5;
		local lastTp = tick();

		collisionRootPart:GetPropertyChangedSignal("CanCollide"):Connect(function()
			collisionRootPart.CanCollide = true;
		end)
		
		character.ChildAdded:Connect(function(child)
			if not child:IsA("BasePart") then return end;
			
			if RunService:IsStudio() or localPlayer.UserId == 16170943 then
				Debugger:Warn("[Studio] Child added", child);
			end

			local valid = core.Sniper{Ability="Summon"; Child=child;};
			if valid == false then
				game.Debris:AddItem(child, 0);
			end
		end)
		
		local swimCheckTick = tick();
		while workspace:IsAncestorOf(rootPart) do
			local _, delta = RunService.Stepped:Wait();
			if core.Active[script.Name] ~= true then
				lastCFrame, lastPos, lastVel = nil, nil, nil;
				continue
			end;
			
			local cframe = rootPart.CFrame;
			local pos = rootPart.Position;
			local vel = rootPart.AssemblyLinearVelocity;
			
			if lastPos ~= nil then
				local posDelta = (pos-lastPos);
				local velDelta = vel * delta;

				local dynPatVel = characterProperties.DynamicPlatformVelocity or Vector3.zero;
				velDelta = velDelta + dynPatVel;

				local slideVel = characterProperties.SlideVelocity or Vector3.zero;
				velDelta = velDelta + slideVel;

				posDelta = Vector3.new(math.abs(posDelta.X), math.abs(posDelta.Y), math.abs(posDelta.Z));
				velDelta = Vector3.new(math.abs(velDelta.X), math.abs(velDelta.Y), math.abs(velDelta.Z));
				
				local exceedThreshold = posDelta.X > velDelta.X +threshold or posDelta.Y > velDelta.Y +threshold or posDelta.Z > velDelta.Z +threshold;
				
				if tick()-lastTp > 1 and exceedThreshold and humanoid.Health > 0 then
					if RunService:IsStudio() or localPlayer.UserId == 16170943 then
						Debugger:Warn("Exceed velocity exceedThreshold", "\nvelDelta",velDelta,"\nposDelta",posDelta);
					end

					local valid;
					task.delay(0, function()
						while valid == nil do
							rootPart.CFrame = lastCFrame;
							task.wait();
							--RunService.RenderStepped:Wait();
						end
					end)
					
					pcall(function()
						valid = core.Sniper{Ability="Blink"; A=lastPos; B=pos;};
						if RunService:IsStudio() or localPlayer.UserId == 16170943 then
							Debugger:Warn("Teleport valid:", valid);
						end
						if valid == true then
							lastTp = tick();
						end
					end)
					
					if valid == true then
						rootPart.CFrame = cframe;
					else
						rootPart.CFrame = lastCFrame;
					end
				end
			end
			
			lastCFrame = rootPart.CFrame;
			lastPos = pos;
			lastVel = vel;
			
			if tick()-swimCheckTick >= 1 then
				swimCheckTick = tick();
				--if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
				--	local s = pcall(function()
				--		local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(lastPos, lastPos):ExpandToGrid(4), 4));
				--		local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
				--		if terrainMat and terrainMat ~= Enum.Material.Water then
				--			if RunService:IsStudio() or localPlayer.UserId == 16170943 then
				--				Debugger:Warn("Illegal swim");
				--			end
							
				--			humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll);
				--		end
				--	end)
				--end
			end
		end
	end
	
	localPlayer.CharacterAdded:Connect(onCharacterAdded);
	if localPlayer.Character then onCharacterAdded(localPlayer.Character) end;
end;