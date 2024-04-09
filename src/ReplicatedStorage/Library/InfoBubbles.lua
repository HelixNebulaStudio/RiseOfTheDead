local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local InfoBubbles = {};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local TextService = game:GetService("TextService");
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remoteCreateInfoBubble = modRemotesManager:Get("CreateInfoBubble");

local infoBubblePrefab = script:WaitForChild("InfoBubble");
local random = Random.new();
--== Script;

function InfoBubbles.Create(packet, ...)
	task.spawn(function()
		if packet.Position == nil then Debugger:Warn("Missing position."); return end;

		packet.Value = tonumber(packet.Value);
		local valStr = tostring(packet.Value or "");
		if packet.Value ~= nil then
			if packet.Value >= 1000 then
				valStr = (math.floor(packet.Value/100)/10).."K";
			else
				valStr = tostring(math.round(packet.Value));
			end
		end
		packet.ValueString = packet.ValueString or valStr;
		
		local firedPlayer = {};
		for a=1, #packet.Players do
			if typeof(packet.Players[a]) ~= "Instance" or not packet.Players[a]:IsA("Player") then continue end;
			if firedPlayer[packet.Players[a]] then continue end;
			firedPlayer[packet.Players[a]] = true;
			
			remoteCreateInfoBubble:FireClient(packet.Players[a], packet);
		end
	end)
end

local lastBubbleInfo = {
	Index = 0;
	LastTick = tick();
};

local localplayer, modData;
function InfoBubbles.Spawn(packet)
	if modConfigurations.DisableInfoBubbles then return end;
	
	local spawnPart = packet.SpawnPart or workspace.Terrain;
	local position = packet.Position;
	local bubbleType = packet.Type or "Damage";
	
	local att = Instance.new("Attachment");
	att.WorldPosition = position + Vector3.new(random:NextNumber(-0.7, 0.7), random:NextNumber(-0.7, 0.7), random:NextNumber(-0.7, 0.7));
	att.Parent = spawnPart;
	
	local new = infoBubblePrefab:Clone();
	local iconTag = new:WaitForChild("IconTag");
	local labelTag = new:WaitForChild("LabelTag");

	labelTag.Text = packet.ValueString or ""; --typeof(value) == "number" and math.floor(value+0.5) or value or ""; --(math.floor(value*100)/100)
	new.Parent = att;
	new.Adornee = att;
	
	if bubbleType == "FireDamage" then
		iconTag.Image = "rbxassetid://3479646912";
		iconTag.ImageColor3 = Color3.fromRGB(162, 53, 53);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "ElectricityDamage" then
		iconTag.Image = "rbxassetid://3576225217";
		iconTag.ImageColor3 = Color3.fromRGB(162, 153, 52);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "FrostDamage" then
		iconTag.Image = "rbxassetid://3564119613";
		iconTag.ImageColor3 = Color3.fromRGB(52, 125, 162);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "ToxicDamage" then
		iconTag.Image = "rbxassetid://3564120076";
		iconTag.ImageColor3 = Color3.fromRGB(125, 162, 52);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "ExplosiveDamage" then
		iconTag.Image = "rbxassetid://6839944806";
		iconTag.ImageColor3 = Color3.fromRGB(162, 116, 0);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "Immune" then
		iconTag.Image = "rbxassetid://6469142255";
		iconTag.ImageColor3 = Color3.fromRGB(230, 230, 230);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "Armor" then
		iconTag.Image = "rbxassetid://6469142255";
		iconTag.ImageColor3 = Color3.fromRGB(72, 120, 197);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "Shield" then
		iconTag.Image = "rbxassetid://6469175695";
		iconTag.ImageColor3 = Color3.fromRGB(120, 120, 120);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "AntiShield" then
		iconTag.Image = "rbxassetid://6469156345";
		iconTag.ImageColor3 = Color3.fromRGB(180, 75, 56);
		labelTag.TextColor3 = iconTag.ImageColor3;

	elseif bubbleType == "Heal" then
		iconTag.Image = "rbxassetid://2770153676";
		iconTag.ImageColor3 = Color3.fromRGB(39, 120, 17);
		labelTag.TextColor3 = iconTag.ImageColor3;

	else
		labelTag.Size = UDim2.new(1, 0, 1, 0);
		iconTag.Visible = false;
	end
	
	if bubbleType == "Crit" then
		labelTag.TextColor3 = Color3.fromRGB(249, 120, 69);
		labelTag.TextSize = 20;
		iconTag.ImageColor3 = labelTag.TextColor3;
		
	end
	
	if packet.KillSnd then
		if packet.KillSnd == "KillHead" then
			local hitSoundRoll = (random:NextNumber(0,1) == 1 and "BulletBoneKillshot" or "BulletBoneKillshot2");
			modAudio.Play(hitSoundRoll, nil, false);
		else
			local hitSoundRoll = (random:NextNumber(0,1) == 1 and "BulletFleshKillshot" or "BulletFleshKillshot2");
			modAudio.Play(hitSoundRoll, nil, false);
		end

		labelTag.TextColor3 = Color3.fromRGB(249, 87, 87);
		labelTag.TextSize = 22;
		labelTag.TextStrokeColor3 = Color3.fromRGB(112, 0, 0);
		iconTag.ImageColor3 = labelTag.TextColor3;
	end
	
	if packet.BreakSnd then
		iconTag.Image = "rbxassetid://6469156345";
		iconTag.ImageColor3 = Color3.fromRGB(180, 75, 56);
		labelTag.TextColor3 = iconTag.ImageColor3;
		labelTag.TextSize = 22;
		modAudio.Play("ArmorBreak", nil, false).PlaybackSpeed = math.random(90, 110)/100;
		
	end
	
	labelTag.Font = packet.Bold == true and Enum.Font.ArialBold or Enum.Font.Arial;
	local textBounds = TextService:GetTextSize(labelTag.Text, labelTag.TextSize, labelTag.Font, Vector2.new(200, 20));
	new.Size = UDim2.new(0, math.clamp(math.ceil(textBounds.X/10), 1, 20)*10 + (iconTag.Visible and 23 or 3), 0, 20);

	if tick()-lastBubbleInfo.LastTick <= 0.1 then
		lastBubbleInfo.Index = lastBubbleInfo.Index+1;
	else
		lastBubbleInfo.Index = 0;
	end
	lastBubbleInfo.LastTick = tick();

	local spread = math.clamp(lastBubbleInfo.Index/8, 0, 3);
	local lifespan = 1 - math.clamp(lastBubbleInfo.Index/8, 0, 0.5);
	TweenService:Create(att, TweenInfo.new(lifespan, Enum.EasingStyle.Quart), {WorldPosition=(att.WorldPosition 
		+ Vector3.new(random:NextNumber(-3 - spread, 3 + spread), 3 + spread, random:NextNumber(-3 - spread, 3 + spread)))}):Play();
	game.Debris:AddItem(att, lifespan);
	
end

if RunService:IsClient() then
	local spawnPart = Instance.new("Part");
	spawnPart.Name = "InfoBubbles";
	spawnPart.Anchored = true;
	spawnPart.CFrame = CFrame.new(0, 0, 0);
	spawnPart.Size = Vector3.new(0, 0, 0);
	spawnPart.Transparency = 1;
	spawnPart.CanCollide = false;
	spawnPart.Parent = workspace.CurrentCamera;
	
	localplayer = game.Players.LocalPlayer;
	
	if script:GetAttribute("ClientConnected") ~= true then
		script:SetAttribute("ClientConnected", true);

		remoteCreateInfoBubble.OnClientEvent:Connect(function(packet)
			if localplayer:GetAttribute("CinematicMode") then return end;
			if localplayer:GetAttribute("DisableHud") then return end;

			local bubbleType = packet.Type;
			modData = require(localplayer:WaitForChild("DataModule"));
			if modData and modData.Settings and modData.Settings.DamageBubble == 1 then -- and bubbleType and bubbleType:match("Damage")
				return
			end;

			packet.SpawnPart = spawnPart;
			InfoBubbles.Spawn(packet)
		end)
	end
end

return InfoBubbles;