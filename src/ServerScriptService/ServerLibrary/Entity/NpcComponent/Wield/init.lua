local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);

local weaponHandler = require(script.WeaponHandler);
local meleeHandler = require(script.MeleeHandler);
local roleplayHandler = require(script.RoleplayHandler);
local healHandler = require(script.HealHandler);
--== Script;
local Component = {};

function Component.new(Npc)
	local Wield = {};
	Wield.Instances = {};
	Wield.ToolModule = nil;
	Wield.Targetable = {["Zombie"]=1;};
	Wield.Controls = {
		Mouse1Down = false; 
	}
	Wield.AllowShooting = false;
	Wield.ReloadCoolDown = tick();
	Wield.Handler = nil;
	Wield.Audio = {};
	Wield.ItemId = nil;
	
	function Wield.Equip(toolItemId, packet)
		packet = packet or {};

		if Wield.ItemId == toolItemId then return end;
		if Wield.ItemId then
			Wield.Unequip();
		end
		if Wield.Handler == nil or Wield.ItemId ~= toolItemId then
			if Wield.Handler then
				Wield.Handler:Unequip();
				task.wait(0.5);
			end;
			
			if modWeapons[toolItemId] then
				Wield.Handler = weaponHandler.new(Npc, Wield, toolItemId);
				Wield.ItemId = toolItemId;
				
			elseif modTools[toolItemId] then
				if modTools[toolItemId].Type == "Melee" then
					Wield.Handler = meleeHandler.new(Npc, Wield, toolItemId);
					
				elseif modTools[toolItemId].Type == "HealTool" then
					Wield.Handler = healHandler.new(Npc, Wield, toolItemId);
					
				else
					Wield.Handler = roleplayHandler.new(Npc, Wield, toolItemId);
					
				end
				
				Wield.ItemId = toolItemId;
				
			else
				Debugger:Warn(Npc.Name," no handler for (",toolItemId,")");
				
			end
		end
		if Wield.Handler then
			if packet.MockItem then
				Wield.Handler.MockItem = true;
			end
			Wield.Handler:Equip();
			
		end
		for k, obj in pairs(Wield.Instances) do
			obj:SetAttribute("ItemId", toolItemId);
		end
	end

	function Wield.Unequip(toolItemId)
		if Wield.Handler then
			Wield.Handler.AnimGroup:Destroy();
			Wield.Handler:Unequip();
			for k,v in pairs(Wield.Audio) do
				game.Debris:AddItem(v, 0);
			end
			Wield.ItemId = nil;
		end
	end
	
	function Wield.PrimaryFireRequest(...)
		if Wield.Handler and Wield.Handler.PrimaryFireRequest then
			Wield.Handler:PrimaryFireRequest(...);
		end
	end
	
	function Wield.ReloadRequest()
		if Wield.Handler and Wield.Handler.ReloadRequest then
			Wield.Handler:ReloadRequest();
		end
	end
	
	function Wield.LoadRequest()
		if Wield.Handler and Wield.Handler.PlayLoad then
			Wield.Handler:PlayLoad();
		end
	end

	function Wield.SetEnemyHumanoid(enemy)
		Wield.EnemyHumanoid = enemy;
	end
	
	function Wield.ToggleIdle(self, v)
		if Wield.Handler and Wield.Handler.ToggleIdle then
			Wield.Handler:ToggleIdle(v);
		end
	end
	
	--[[
		SetSkin({
			Colors={
				["Handle"]=14;
			};
			Textures={
				["Handle"]=10;
			};
		});
	]]--
	function Wield.SetSkin(itemValues)
		for k, obj in next, Wield.Instances do
			if obj:IsA("Model") then
				modColorsLibrary.ApplyAppearance(obj, itemValues);
			end
		end
	end


	function Wield.ActionRequest(...)
		if Wield.Handler and Wield.Handler.ActionRequest then
			Wield.Handler:ActionRequest(...);
		end
	end
	
	function Wield.PlayAnim(categoryId)
		if Wield.Handler and Wield.Handler.AnimGroup then
			Wield.Handler.AnimGroup:Play(categoryId);
		end
	end
	
	function Wield.StopAnim(categoryId)
		if Wield.Handler and Wield.Handler.AnimGroup then
			Wield.Handler.AnimGroup:Stop(categoryId);
		end
	end
	
	function Wield.GetAnim(categoryId, index)
		if Wield.Handler == nil or Wield.Handler.AnimGroup == nil then return end;
		return Wield.Handler.AnimGroup:GetTrackData(categoryId, index);
	end
	
	return Wield;
end

return Component;