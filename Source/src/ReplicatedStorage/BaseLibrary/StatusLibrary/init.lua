local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local StatusLibrary = {};
StatusLibrary.__index = StatusLibrary;
--== Script;
function StatusLibrary:Init(super)
	super.DebuffTags = {"Mobility"; "DOT"; "Confusion"};

	for _, ms in pairs(script:GetChildren()) do
		if not ms:IsA("ModuleScript") then continue end;
		if ms.Name == "Template" then continue end;
		
		super:LoadModule(ms);
	end

	if true then return end; -- MARK: TODO

	--== Skill tree status;
	super:Add{
		Id="morbir";
		Icon="rbxassetid://4488388895";
		Name="Skill: Morning Bird";
		Description="+$Amount Health regen per second for $Duration seconds.";
		DescProcess={["Amount"]=function(v) return v*10; end};
		Buff=true;
		Cleansable=true;
	};

	super:Add{
		Id="trinar";
		Icon="rbxassetid://4483748413";
		Name="Skill: Trained In Arms";
		Description="Weapon accuracy increased by $Percent%.";
		Buff=true;
	};

	super:Add{
		Id="nigowl";
		Icon="rbxassetid://4492141104";
		Name="Skill: Night Owl";
		Description="-$Percent% enemy detection for $Duration seconds.";
		Buff=true;
	};

	super:Add{
		Id="fiaitr";
		Icon="rbxassetid://4493354290";
		Name="Skill: First Aid Training";
		Description="Medkits use speed increased by $Percent%.";
		Buff=true;
	};

	super:Add{
		Id="effmet";
		Icon="rbxassetid://4561093556";
		Name="Skill: Efficient Metabolism";
		Description="Increases the duration of food by $Percent%.";
		Buff=true;
	};

	super:Add{
		Id="remres";
		Icon="rbxassetid://4651191717";
		Name="Skill: Remarkable Resilience Cooldown";
		Description="Skill on cooldown, regenerated to $Percent% of max health.";
		Buff=true;
	};

	super:Add{
		Id="agirec";
		Icon="rbxassetid://4561097552";
		Name="Skill: Agile Recovery";
		Description="Movement impairment debuff duration reduced by $Percent%.";
		Buff=true;
	};

	super:Add{
		Id="reqback";
		Icon="rbxassetid://4561090238";
		Name="Skill: Requesting Backup Cooldown";
		Description="Skill on cooldown, when you drop below 35% health, you will heal up to $Percent% health of a squadmate with the highest health.";
		Buff=true;
	};

	super:Add{
		Id="ovehea";
		Icon="rbxassetid://4752500248";
		Name="Skill: Over Heal";
		Description="Heal over max health by $Amount health with medkits.";
		Buff=true;
		Cleansable=true;
	};

	super:Add{
		Id="bunnyman";
		Icon="rbxassetid://4845612402";
		Name="Bunny Man's Head";
		Description="You are ignored by normal zombies.";
		Buff=true;
	};

	super:Add{
		Id="tickre";
		Icon="rbxassetid://4978159755";
		Name="Tick Protection";
		Description="You recently got damaged by a tick, thus will not take damage from another one until this expires.";
		Buff=true;
		Cleansable=true;
	};

	super:Add{
		Id="TiedUp";
		Icon="rbxassetid://4983245856";
		Name="Tied Up";
		Description="You are tied up and cannot move or do anything while being tied up.";
		Buff=false;
		Tags = {"Mobility"; "Stun";};
		Cleansable=true;
	};

	super:Add{
		Id="NekronMask";
		Icon="rbxassetid://5419783427";
		Name="Nekron Mask";
		Description="When this effect is over, the Nekron Mask is consumed.";
		Module=script.NekronMask;
		Buff=true;
	};

	super:Add{
		Id="Disguised";
		Icon="rbxassetid://5783987908";
		Name="Disguised";
		Description="You are disguised as $Name.";
		Buff=true;
	};

	super:Add{
		Id="MeleeFury";
		Icon="rbxassetid://6557976555";
		Name="Melee Fury";
		Description="Buff increases attack speed by $Amount stacks. (Max Stacks: 0.5 seconds)";
		QuantityLabel="Amount";
		Buff=true;
		Cleansable=true;
	};

	super:Add{
		Id="ArmorBreak";
		Icon="rbxassetid://6561711943";
		Name="Armor Break";
		Description="Your armor broke after you took $Damage damage. Armor regeneration is delay by $Duration seconds.";
		Buff=false;
		Tags = {"Weaken";};
		Cleansable=true;
	};

	super:Add{
		Id="TooCold";
		Icon="rbxassetid://3564119613";
		Name="Too Cold";
		Description="It's too cold. (Below 10°C) Put on more clothes! If you take damage, you might freeze.";
		Buff=false;
	};

	super:Add{
		Id="TooHot";
		Icon="rbxassetid://3479646912";
		Name="Too Hot";
		Description="It's too hot. (Above 40°C) \"Take off your jacket!\" If you take damage, you might ignite.";
		Buff=false;
	};

	super:Add{
		Id="Freezing";
		Icon="rbxassetid://10371553364";
		Name="Freezing";
		Description="You are freezing, you will lose mobility and won't be able to perform actions.";
		Buff=false;
		Tags = {"Mobility"; "Slow";};
		Cleansable=true;
	};

	super:Add{
		Id="Toxic";
		Icon="rbxassetid://12517601747";
		Name="Toxic";
		Description="You are taking toxic damage.";
		Buff=false;
		Tags = {"DOT";};
		Cleansable=true;
	};

	super:Add{
		Id="Nekrosis";
		Icon="rbxassetid://14423236705";
		Name="Nekrosis";
		Description="You are healing from Nekrosis, +$Amount hp/s.";
		DescProcess={["Amount"]=function(v) return v*10; end};
		Module=script.Nekrosis;
		Buff=true;
		Cleansable=true;
	};

	super:Add{
		Id="Ziphoning";
		Icon="rbxassetid://15936793820";
		Name="Ziphoning";
		Description="Nekrosis heal from this pool of health. +$Amount hp/s";
		Module=script.Ziphoning;
		QuantityLabel="Pool";
		Buff=true;
		Cleansable=true;
	};

	super:Add{
		Id="PacifistsAmulet";
		Icon="rbxassetid://16049397225";
		Name="Pacifist's Amulet";
		Description="Armor over charges and increased armor rate from pacifism.";
		Buff=true;
		Module=script.PacifistsAmulet;
	};

	super:Add{
		Id="WarmongerScales";
		Icon="rbxassetid://16084490297";
		Name="Warmonger's Scales";
		Description="For every percent damaged, temporary increases max health.";
		Buff=true;
		Module=script.WarmongerScales;
	};

	super:Add{
		Id="Mending";
		Icon="rbxassetid://16074211222";
		Name="Mending";
		Description="For every kill, reduce <b>Armor Break</b> duration by $Times.";
		Buff=true;
		Module=script.Mending;
	};

	super:Add{
		Id="resgat";
		Icon="rbxassetid://16380816785";
		Name="Resource Gatherers Cooldown";
		Description="A squadmate helped you pick up some items.";
		Buff=true;
	};

	super:Add{
		Id="Chained";
		Icon="rbxassetid://16716699240";
		Name="Chained";
		Description="You are chained to something. Maybe destroy it to break free?";
		Buff=false;
	};


	super:Add{
		Id="TireArmor";
		Icon="rbxassetid://16745983668";
		Name="Tire Armor";
		Description="Tire Armor Passive";
		Module=script.TireArmor;
		Buff=true;
	};

	super:Add{
		Id="FumesGas";
		Icon="rbxassetid://17203237389";
		Name="Fumes Gas";
		Description="Taking health damage from Fumes bypassing your gas protection.";
		Buff=false;
	}

	super:Add{
		Id="ItemHealth";
		Icon="rbxasset://textures/ui/GuiImagePlaceholder.png";
		Name="Item Health Hud";
		Description="$Desc";
		Buff=false;
	}

	super:Add{
		Id="LabCoat";
		Icon="rbxassetid://4978200934";
		Name="LabCoat";
		Description="Your Lab Coat adds 30% extra gas protection to gas damages.";
		Buff=true;
	}

end

return StatusLibrary;