local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local TweenService = game:GetService("TweenService");

local localplayer = game.Players.LocalPlayer;

local modData = require(localplayer:WaitForChild("DataModule"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local remoteDamagePacket = modRemotesManager:Get("DamagePacket");
	
local mainFrame = script.Parent.Parent:WaitForChild("HurtScreen");
local templateHurtDir = script:WaitForChild("HurtDir");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("HurtInterface", mainFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:Open();
	window:SetConfigKey("DisableHurtInterface");
	
	
	function Interface.SpawnIndicator(packet)
		local damage = packet.Damage;
		local damageType = packet.DamageType;
		local dmgPos = packet.DamagePosition;
		
		local classPlayer = shared.modPlayers.Get(localplayer);
		local playerCFrame = classPlayer:GetCFrame();
		
		local pivot : CFrame = playerCFrame:ToObjectSpace(CFrame.new(dmgPos));
		local dirRad = math.atan2(pivot.X, -pivot.Z);
		
		
		local modCharacter = modData:GetModCharacter();
		local characterProperties = modCharacter.CharacterProperties;
		local mouseProperties = modCharacter.MouseProperties;
		
		local flinchMulti = math.clamp(damage, 5, 100);

		local flinchProtection = classPlayer:GetBodyEquipment("FlinchProtection") or 0;
		flinchProtection = math.clamp(1-flinchProtection, 0, 1);
		
		flinchMulti = flinchMulti * flinchProtection;

		if classPlayer.Character and classPlayer.Character:FindFirstChild("GodModeFF") == nil then
			if flinchMulti > 5 then
				flinchMulti = flinchMulti/2;
				mouseProperties.XAngOffset = mouseProperties.XAngOffset + math.rad(math.abs(math.sin(dirRad)) * flinchMulti);
				mouseProperties.YAngOffset = mouseProperties.YAngOffset + math.rad(math.abs(math.cos(dirRad)) * flinchMulti);
			end
			mouseProperties.FlinchInacc = mouseProperties.FlinchInacc + (flinchMulti*2);
		end
		
		if modData and modData.Settings.DisableDamageIndicator == 1 then return end;
		local lifetime = math.clamp(damage/35, 2, 5);
		
		local new = templateHurtDir:Clone();
		game.Debris:AddItem(new, lifetime);
		new.Rotation = math.deg(dirRad);
		new.Parent = mainFrame;
		
		local bar = new:WaitForChild("Bar");
		
		local dmgScale = modMath.MapNum(damage, 1, 100, 40, 80);
		bar.Size = UDim2.new(0, dmgScale, 0, 800);
		
		if damageType == "Armor" then
			bar.BackgroundColor3 = Color3.fromRGB(170, 170, 170);
		else
			bar.BackgroundColor3 = Color3.fromRGB(150, 30, 30);
		end
		
		TweenService:Create(bar, TweenInfo.new(0.05), {BackgroundTransparency=0}):Play();
		
		task.delay(lifetime-1, function()
			TweenService:Create(bar, TweenInfo.new(1), {BackgroundTransparency=1}):Play();
		end)
	end
	
	Interface.Garbage:Tag(remoteDamagePacket.OnClientEvent:Connect(function(damageSource)
		local dmgPos = damageSource.DamagePosition;
		
		if dmgPos == nil then
			local dealer = damageSource.Dealer;
			if dealer == nil then return end;
			
			if dealer:IsA("Player") then
				local model = dealer.Character;
				dmgPos = model:GetPivot().Position;
				
			elseif dealer:IsA("Model") then
				dmgPos = dealer:GetPivot().Position;
				
			end
		end
		
		if dmgPos == nil then return end;

		local packet = {
			Damage = damageSource.Damage;
			DamageType = damageSource.DamageType;
			DamagePosition = dmgPos;
		}
		
		if damageSource.DamageType == "Heal" then return end;
		Interface.SpawnIndicator(packet);
	end));
	
	return Interface;
end;

function Interface.Update()

end

return Interface;
