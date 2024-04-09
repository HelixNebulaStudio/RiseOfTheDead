local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local toggleInteract = Interactable.Toggle("Toggle Window");
toggleInteract.Script = script;

if RunService:IsServer() then
	local windowMotor = script.Parent.Parent:WaitForChild("Bars"):WaitForChild("Window");
	
	function toggleInteract:OnToggle(player)
		if self.CanInteract == false then return end;
		self.CanInteract = false;
		self.Active = not self.Active;
		
		self:Sync();
		
		if self.Active then
			TweenService:Create(windowMotor, TweenInfo.new(0.4), {C1=CFrame.new(0, 2.31, 0)}):Play();
		else
			TweenService:Create(windowMotor, TweenInfo.new(0.4), {C1=CFrame.new(0, 0, 0)}):Play();
		end
		
		wait(0.5);
		
		self.CanInteract = true;
		self:Sync();
	end
end

return toggleInteract;