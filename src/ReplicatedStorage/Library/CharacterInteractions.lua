local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");

-- Variables;
local modConfigurations = Debugger:Require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);
local modKeyBindsHandler = Debugger:Require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modSyncTime = Debugger:Require(game.ReplicatedStorage.Library.SyncTime);
local modEmotes = Debugger:Require(game.ReplicatedStorage.Library.EmotesLibrary);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);

local remoteCharacterInteractions = modRemotesManager:Get("CharacterInteractions");

if RunService:IsClient() then
	localPlayer = game.Players.LocalPlayer;
	playerGui = localPlayer:WaitForChild("PlayerGui");
	modData = require(localPlayer:WaitForChild("DataModule"));
	
else
	modOnGameEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
end

--
local CharacterInteractions = {};
CharacterInteractions.__index = CharacterInteractions;

CharacterInteractions.MountStyle = {
	Injured = {Id="Injured";};
}

--==
Debugger:Log("Initialized");

function CharacterInteractions.Dismount(mountChar, passengerChar, mountStyle)
	mountStyle = mountStyle or CharacterInteractions.MountStyle.Injured;

	local mountPlayer = game.Players:GetPlayerFromCharacter(mountChar);
	local passengerPlayer = game.Players:GetPlayerFromCharacter(passengerChar);

	if RunService:IsClient() then
		local modCharacter = modData:GetModCharacter()
		local characterProperties = modCharacter.CharacterProperties


		if passengerPlayer == nil then -- NPC mounts player;
			characterProperties.WalkSpeed:Remove("mount");
			characterProperties.JumpPower:Remove("mount");
		end
		
		return;
	end
	
	modOnGameEvents:Fire("OnDismount", mountChar, passengerChar);

	local classPlayer = shared.modPlayers.Get(mountPlayer);
	if classPlayer.Mount and classPlayer.Mount.Passenger and classPlayer.Mount.Passenger[passengerChar] then
		local mountData = classPlayer.Mount.Passenger[passengerChar];

		local passengerHumanoid = passengerChar:FindFirstChildWhichIsA("Humanoid");
		passengerHumanoid.PlatformStand = false;

		for _, obj in pairs(passengerChar:GetChildren()) do
			if obj:IsA("BasePart") then
				if obj:GetAttribute("DefaultMassless") == false then
					obj.Massless = false;
				end
			end
		end

		Debugger.Expire(passengerChar.HumanoidRootPart:FindFirstChild("Mount"), 0);
		
		classPlayer.Mount.Passenger[passengerChar] = nil;
	end
	
	remoteCharacterInteractions:InvokeClient(mountPlayer, "dismount", {
		MountCharacter=mountChar;
		PassengerCharacter=passengerChar;
		MountStyle=mountStyle;
	});
end

function CharacterInteractions.Mount(mountChar, passengerChar, mountStyle)
	mountStyle = mountStyle or CharacterInteractions.MountStyle.Injured;
	
	local mountPlayer = game.Players:GetPlayerFromCharacter(mountChar);
	local passengerPlayer = game.Players:GetPlayerFromCharacter(passengerChar);
	
	if RunService:IsClient() then
		local classPlayer = shared.modPlayers.Get(localPlayer);
		
		local modCharacter = modData:GetModCharacter()
		local characterProperties = modCharacter.CharacterProperties
		
		
		if passengerPlayer == nil then -- NPC mounts player;
			local passengerHumanoid = passengerChar:FindFirstChildWhichIsA("Humanoid");
			
			characterProperties.WalkSpeed:Set("mount", 8, 2);
			characterProperties.JumpPower:Set("mount", 0, 2);

			local remotePlayEmote = modCharacter.Character:FindFirstChild("PlayEmote", true);
			if remotePlayEmote then
				remotePlayEmote:Invoke("carryinginjured", true);
				
			end
		end
		
		return 
	end;
	
	if mountPlayer then
		if passengerPlayer == nil then
			local classPlayer = shared.modPlayers.Get(mountPlayer);
			
			local mountData = {Passenger={};};
			if classPlayer.Mount == nil then classPlayer.Mount = mountData; end;
			local passengerHumanoid = passengerChar:FindFirstChildWhichIsA("Humanoid");
			
			mountData.Passenger[passengerChar] = {Humanoid=passengerHumanoid; Waist=passengerChar:FindFirstChild("Waist", true);};
			
			passengerChar.PrimaryPart:SetNetworkOwner(mountPlayer);
			
			passengerHumanoid.PlatformStand = true;
			
			for _, obj in pairs(passengerChar:GetChildren()) do
				if obj:IsA("BasePart") then
					if not obj.Massless then
						obj:SetAttribute("DefaultMassless", false);
					end
					obj.Massless = true;
				end
			end
			
			local motor = Instance.new("Motor6D");
			motor.Name = "Mount";
			motor.Parent = passengerChar.HumanoidRootPart;
			motor.Part0 = passengerChar.HumanoidRootPart;
			motor.Part1 = mountChar.HumanoidRootPart;
			motor.C0 = CFrame.new(2.1, 0, 0);

			local humanAnims = game.ReplicatedStorage.Prefabs.Animations.Human;
			
			task.spawn(function()
				local walkingAnim = passengerHumanoid:WaitForChild("Animator"):LoadAnimation(humanAnims.Walking:FindFirstChildWhichIsA("Animation"));
				
				while passengerHumanoid.PlatformStand == true do
					local vel = passengerHumanoid.RootPart.AssemblyLinearVelocity.Magnitude;
					if vel > 0 then
						if not walkingAnim.IsPlaying then
							walkingAnim:Play(nil,nil,0);
						end
						walkingAnim:AdjustSpeed(vel/16);
					else
						if walkingAnim.IsPlaying then
							walkingAnim:Stop();
						end
					end
					task.wait();
				end
				
				walkingAnim:Stop();
				Debugger.Expire(motor, 0);
			end)
		end
		remoteCharacterInteractions:InvokeClient(mountPlayer, "mount", {
			MountCharacter=mountChar;
			PassengerCharacter=passengerChar;
			MountStyle=mountStyle;
		});
	end
end

if RunService:IsServer() then
	shared.modPlayers.OnPlayerDied:Connect(function(classPlayer)
		if classPlayer.Mount and classPlayer.Mount.Passenger then
			for charPassenger, _ in pairs(classPlayer.Mount.Passenger) do
				CharacterInteractions.Dismount(classPlayer.Character, charPassenger, nil);
			end
		end
		
	end)
	
	function remoteCharacterInteractions.OnServerInvoke(player, action, ...)
		local classPlayer = shared.modPlayers.Get(player);
		
		if action == "sit" then
			local packet = ...;
			local interactData = shared.saferequire(player, packet.InteractableScript);
			
			if not interactData.CanInteract or interactData.Type ~= "Seat" then return end;
			
			local seatModel = packet.InteractableScript.Parent;
			local distance = player:DistanceFromCharacter(seatModel:GetPivot().Position);
			
			if distance > 16 then return end;
			
			local seatPart = seatModel:FindFirstChildWhichIsA("Seat");
			if seatPart == nil or seatPart.Occupant ~= nil then return end;
			
			seatPart:Sit(classPlayer.Humanoid);
			
		elseif action == "eject" then
			if classPlayer.Mount and classPlayer.Mount.Passenger then
				for charPassenger, _ in pairs(classPlayer.Mount.Passenger) do
					CharacterInteractions.Dismount(classPlayer.Character, charPassenger, nil);
				end
			end
			
		end
	end
else
	function remoteCharacterInteractions.OnClientInvoke(action, ...)
		if action == "mount" then
			local mountPack = ...;
			CharacterInteractions.Mount(mountPack.MountCharacter, mountPack.PassengerCharacter, mountPack.MountStyle);
			
		elseif action == "dismount" then
			local mountPack = ...;
			CharacterInteractions.Dismount(mountPack.MountCharacter, mountPack.PassengerCharacter, mountPack.MountStyle);
			
		end
	end
end

return CharacterInteractions;
