local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);

local templateHealthbarGui = script:WaitForChild("HealthbarGui");
local templateNpcStatusLink = script.Parent.Parent:WaitForChild("NpcStatus");

--== Script;
local CustomHealthbar = {};
CustomHealthbar.__index = CustomHealthbar;

function CustomHealthbar:Create(name, maxHealth, adornee)
	if self.Healths[name] then Debugger:Warn("Health bar already exist. (",name,")"); return end;
	local newHealthGui = templateHealthbarGui:Clone();
	local healthObj = {
		Name = name;
		LastDamaged = tick();
		IsDead=false;
		Health=maxHealth;
		MaxHealth=maxHealth;
		HealthGui=newHealthGui;
		BasePart=adornee;
		OnDeath = modEventSignal.new("OnCustomHealthbarDeath");
	};
	self.Healths[name] = healthObj;
	newHealthGui.Parent = adornee;
	newHealthGui.Adornee = adornee;
	self:RefreshGui(name);
	
	if adornee.Parent and adornee.Parent:FindFirstChild("NpcStatus") == nil then
		local newLink = templateNpcStatusLink:Clone();
		newLink.Parent = adornee.Parent;
		require(newLink):Initialize(self.Npc);
	end
	
	self.Npc.Garbage:Tag(function()
		healthObj.BasePart = nil;
		healthObj.OnDeath:Destroy();
	end);
	
	return self.Healths[name];
end

function CustomHealthbar:GetFromPart(bodyPart: BasePart)
	for name, healthObj in pairs(self.Healths) do
		if healthObj.BasePart == bodyPart then
			return healthObj;
		end
	end

	return;
end

function CustomHealthbar:SetGuiSize(name, x, y)
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo and healthInfo.HealthGui;
	if healthGui then
		healthGui.Size = UDim2.new(x, 0, y, 0);
	end
end

function CustomHealthbar:SetOffset(name, vec)
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo and healthInfo.HealthGui;
	if healthGui then
		healthGui.StudsOffsetWorldSpace = vec;
	end
end

function CustomHealthbar:RefreshGui(name)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if (healthInfo.Health > 0 and healthInfo.Health ~= healthInfo.MaxHealth) or healthGui.Enabled then
		healthGui.Enabled = true;
		local bar = healthGui.Frame.Bar;
		local lostBar = healthGui.Frame.Lostbar;
		local labelTag = healthGui.Label;
		
		labelTag.Text = math.max(math.ceil(healthInfo.Health), 0).."/"..healthInfo.MaxHealth;
		
		local newSize = UDim2.new(math.clamp(healthInfo.Health/healthInfo.MaxHealth, 0, 1), 0, 1, 0);
		bar.Size = newSize;
		task.delay(0.1, function()
			lostBar.Size = newSize;
		end)
	else
		healthGui.Enabled = false;
	end
end

function CustomHealthbar:ShowGui(name)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if healthGui then
		healthGui.Enabled = true;
		self:RefreshGui(name);
	end
end

function CustomHealthbar:HideGui(name)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if healthGui then
		healthGui.Enabled = false;
	end
end

function CustomHealthbar:SetGuiDistance(name, value)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if healthGui then
		healthGui.MaxDistance = value;
	end
end

function CustomHealthbar:ToggleLabel(name, v)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	
	if healthGui then
		local label: TextLabel = healthGui.Label;
		
		label.Visible = v == true;
	end
end

-- interface: function CustomHealthbar:OnDamaged() : boolean
-- return true to isolate damage

function CustomHealthbar:TakeDamage(name, amount)
	local healthObj = self.Healths[name];
	if healthObj == nil then
		Debugger:StudioWarn("TakeDamage for unknown health bar",name);
		return;
	end
	
	if healthObj.Health <= 0 then return end
		
	healthObj.LastDamaged = tick();
	healthObj.Health = healthObj.Health - amount;
		
	self:RefreshGui(name)
	task.delay(2, function()
		if healthObj and not healthObj.IsDead and tick()-healthObj.LastDamaged > 2 then
			self:HideGui(name);
		end
	end)
	
	if healthObj.Health <= 0 then
		healthObj.OnDeath:Fire();
		healthObj.OnDeath:Destroy();
		healthObj.IsDead = true;
		self.OnDeath:Fire(name, healthObj);

		task.spawn(function()
			task.wait(0.1);
			local destoryStr = `{(string.gsub(name, "[%A]*", ""))} Destroyed!`;
			local attackers = self.Npc.Status:GetAttackers();
			Debugger:StudioWarn("Destroyed CustomHealthObj ", name);

			modInfoBubbles.Create{
				Players=attackers;
				Position=healthObj.BasePart.Position;
				Type="Status";
				ValueString=destoryStr;
			};
			
			task.delay(3, function()
				if healthObj then
					self:HideGui(name);
				end
			end)
		end)
	end

end

function CustomHealthbar:Destroy()
	self.OnDeath:Destroy();
	pcall(function()
		for k,v in pairs(self.Healths) do
			self.Healths[k].OnDeath:Fire();
			self.Healths[k].OnDeath:Destroy();
			self.Healths[k] = nil;
		end
	end)
end

function CustomHealthbar.new(Npc)
	local self = {
		Npc = Npc;
		Healths = {};
		OnDeath = modEventSignal.new("OnCustomHealthbarDeath");
	};
	
	setmetatable(self, CustomHealthbar);
	return self;
end

return CustomHealthbar;