local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local PlaceholderIcon = "rbxassetid://16029038219";
--
local library = modLibraryManager.new();

library.DebuffTags = {"Mobility"; "DOT"; "Confusion"};

library:Add{
	Id="Coop";
	Icon="rbxassetid://4466529123";
	Name="Coop";
	Description="Coop";
	Buff=true;
};

library:Add{
	Id="FoodHeal";
	Icon="rbxassetid://4466529123";
	Name="Healing From Food";
	Description="+$Amount Health regen per second.";
	DescProcess={["Amount"]=function(v) return v*10; end};
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="MaxHeal";
	Icon="rbxassetid://2770153676";
	Name="Healing From Healer";
	Description="Heals 10% of max health per second.";
	Buff=true;
};

library:Add{
	Id="Slowness";
	Icon="rbxassetid://4467439574";
	Name="Slowness";
	Description="Slowed by $Amount walk speed.";
	Buff=false;
	Tags = {"Mobility"; "Slow";};
	Cleansable=true;
};

library:Add{
	Id="Dizzy";
	Icon="rbxassetid://4881193285";
	Name="Dizzy";
	Description="Dizzy for $Amount seconds.";
	Buff=false;
	Tags = {"Confusion";};
	Cleansable=true;
};


library:Add{
	Id="Stun";
	Icon="rbxassetid://4467439850";
	Name="Stunned";
	Description="Stunned";
	Buff=false;
	Tags = {"Mobility"; "Stun";};
	Cleansable=true;
};

library:Add{
	Id="FrostivusSpirit";
	Icon="rbxassetid://4534155688";
	Name="Frostivus Spirit";
	Description="Buff adds +$Amount bonus damage. For every kill you get, increases bonus damage by 20. You lose 20 damage every 3 seconds. (Max Stacks: 10'000 damage)";
	QuantityLabel="Amount";
	Buff=true;
};

library:Add{
	Id="BloxyRush";
	Icon="rbxassetid://5094119246";
	Name="Bloxy Rush";
	Description="Speed and Melee Stamina bonus for a temporary duration.";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="Burn";
	Icon="rbxassetid://5105787895";
	Name="Burning";
	Description="You are on fire, you will lose $Amount Health per second.";
	Buff=false;
	Tags = {"DOT";};
	Cleansable=true;
};

library:Add{
	Id="Forcefield";
	Icon="rbxassetid://6121328871";
	Name="Forcefield";
	Description="Temporarily negate any damage.";
	Buff=true;
};

library:Add{
	Id="Reinforcement";
	Icon="rbxassetid://6121421255";
	Name="Reinforcement";
	Description="A R.A.T. member is temporarily hired to assist you.";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="Superspeed";
	Icon="rbxassetid://6121470569";
	Name="Superspeed";
	Description="Grant you temporary super speed.";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="Lifesteal";
	Icon="rbxassetid://6129813061";
	Name="Lifesteal";
	Description="For every kill, you heal by +$Amount health.";
	Buff=true;
	Cleansable=true;
};

--== Skill tree status;
library:Add{
	Id="morbir";
	Icon="rbxassetid://4488388895";
	Name="Skill: Morning Bird";
	Description="+$Amount Health regen per second for $Duration seconds.";
	DescProcess={["Amount"]=function(v) return v*10; end};
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="trinar";
	Icon="rbxassetid://4483748413";
	Name="Skill: Trained In Arms";
	Description="Weapon accuracy increased by $Percent%.";
	Buff=true;
};

library:Add{
	Id="nigowl";
	Icon="rbxassetid://4492141104";
	Name="Skill: Night Owl";
	Description="-$Percent% enemy detection for $Duration seconds.";
	Buff=true;
};

library:Add{
	Id="fiaitr";
	Icon="rbxassetid://4493354290";
	Name="Skill: First Aid Training";
	Description="Medkits use speed increased by $Percent%.";
	Buff=true;
};

library:Add{
	Id="effmet";
	Icon="rbxassetid://4561093556";
	Name="Skill: Efficient Metabolism";
	Description="Increases the duration of food by $Percent%.";
	Buff=true;
};

library:Add{
	Id="remres";
	Icon="rbxassetid://4651191717";
	Name="Skill: Remarkable Resilience Cooldown";
	Description="Skill on cooldown, regenerated to $Percent% of max health.";
	Buff=true;
};

library:Add{
	Id="agirec";
	Icon="rbxassetid://4561097552";
	Name="Skill: Agile Recovery";
	Description="Movement impairment debuff duration reduced by $Percent%.";
	Buff=true;
};

library:Add{
	Id="reqback";
	Icon="rbxassetid://4561090238";
	Name="Skill: Requesting Backup Cooldown";
	Description="Skill on cooldown, when you drop below 35% health, you will heal up to $Percent% health of a squadmate with the highest health.";
	Buff=true;
};

library:Add{
	Id="ovehea";
	Icon="rbxassetid://4752500248";
	Name="Skill: Over Heal";
	Description="Heal over max health by $Amount health with medkits.";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="bunnyman";
	Icon="rbxassetid://4845612402";
	Name="Bunny Man's Head";
	Description="You are ignored by normal zombies.";
	Buff=true;
};

library:Add{
	Id="tickre";
	Icon="rbxassetid://4978159755";
	Name="Tick Repellent";
	Description="You recently got damaged by a tick, thus will not take damage from another one until this expires.";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="TiedUp";
	Icon="rbxassetid://4983245856";
	Name="Tied Up";
	Description="You are tied up and cannot move or do anything while being tied up.";
	Buff=false;
	Tags = {"Mobility"; "Stun";};
	Cleansable=true;
};

library:Add{
	Id="XpBoost";
	Icon="rbxassetid://5627435285";
	Name="Exp Boost";
	Description="Experience gain is doubled.";
	Buff=true;
};

library:Add{
	Id="NekronMask";
	Icon="rbxassetid://5419783427";
	Name="Nekron Mask";
	Description="When this effect is over, the Nekron Mask is consumed.";
	Module=script.NekronMask;
	Buff=true;
};

library:Add{
	Id="Disguised";
	Icon="rbxassetid://5783987908";
	Name="Disguised";
	Description="You are disguised as $Name.";
	Buff=true;
};


library:Add{
	Id="Poisoned";
	Icon="rbxassetid://6361544022";
	Name="Poisoned";
	Description="Poisoned for $Amount seconds.";
	Buff=false;
	Tags = {"DOT";};
	Cleansable=true;
};

library:Add{
	Id="MeleeFury";
	Icon="rbxassetid://6557976555";
	Name="Melee Fury";
	Description="Buff increases attack speed by $Amount stacks. (Max Stacks: 0.5 seconds)";
	QuantityLabel="Amount";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="ArmorBreak";
	Icon="rbxassetid://6561711943";
	Name="Armor Break";
	Description="Your armor broke after you took $Damage damage. Armor regeneration is delay by $Duration seconds.";
	Buff=false;
	Tags = {"Weaken";};
	Cleansable=true;
};

library:Add{
	Id="StatusResistance";
	Icon="rbxassetid://6469142255";
	Name="Status Resistance";
	Description="Reduced negative effects duration by $Percent%.";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="NightVision";
	Icon="rbxassetid://6008673515";
	Name="Night Vision Mode";
	Description="Dark areas are lit up in green.";
	Buff=true;
};

library:Add{
	Id="Wounded";
	Icon="rbxassetid://7482205902";
	Name="Wounded";
	Description="You are wounded!";
	Module=script.Wounded;
	Buff=false;
};

library:Add{
	Id="KnockedOut";
	Icon="rbxassetid://4881193285";
	Name="Knocked Out";
	Description="You are knocked out!";
	Module=script.KnockedOut;
	Buff=false;
};

library:Add{
	Id="TooCold";
	Icon="rbxassetid://3564119613";
	Name="Too Cold";
	Description="It's too cold. (Below 10°C) Put on more clothes! If you take damage, you might freeze.";
	Buff=false;
};

library:Add{
	Id="TooHot";
	Icon="rbxassetid://3479646912";
	Name="Too Hot";
	Description="It's too hot. (Above 40°C) \"Take off your jacket!\" If you take damage, you might ignite.";
	Buff=false;
};

library:Add{
	Id="CritBoost";
	Icon="rbxassetid://10368377851";
	Name="Crit Boost";
	Description="Boost crit chance by +$Amount%";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="Freezing";
	Icon="rbxassetid://10371553364";
	Name="Freezing";
	Description="You are freezing, you will lose mobility and won't be able to perform actions.";
	Buff=false;
	Tags = {"Mobility"; "Slow";};
	Cleansable=true;
};

library:Add{
	Id="Toxic";
	Icon="rbxassetid://12517601747";
	Name="Toxic";
	Description="You are taking toxic damage.";
	Buff=false;
	Tags = {"DOT";};
	Cleansable=true;
};

library:Add{
	Id="Nekrosis";
	Icon="rbxassetid://14423236705";
	Name="Nekrosis";
	Description="You are healing from Nekrosis, +$Amount hp/s.";
	DescProcess={["Amount"]=function(v) return v*10; end};
	Module=script.Nekrosis;
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="Ziphoning";
	Icon="rbxassetid://15936793820";
	Name="Ziphoning";
	Description="Nekrosis heal from this pool of health. +$Amount hp/s";
	Module=script.Ziphoning;
	QuantityLabel="Pool";
	Buff=true;
	Cleansable=true;
};

library:Add{
	Id="Withering";
	Icon="rbxassetid://15948741680";
	Name="Withering";
	Description="Withering because a Wither is nearby. Looking at them will start Withering and slowly drains armor over time.";
	Buff=false;
	Tags = {"DOT";};
	Module=script.Withering;
	Cleansable=true;
};

library:Add{
	Id="PacifistsAmulet";
	Icon="rbxassetid://16049397225";
	Name="Pacifist's Amulet";
	Description="Armor over charges and increased armor rate from pacifism.";
	Buff=true;
	Module=script.PacifistsAmulet;
};

library:Add{
	Id="WarmongerScales";
	Icon="rbxassetid://16084490297";
	Name="Warmonger's Scales";
	Description="For every percent damaged, temporary increases max health.";
	Buff=true;
	Module=script.WarmongerScales;
};

library:Add{
	Id="Mending";
	Icon="rbxassetid://16074211222";
	Name="Mending";
	Description="For every kill, reduce <b>Armor Break</b> duration by $Times.";
	Buff=true;
	Module=script.Mending;
};

library:Add{
	Id="resgat";
	Icon="rbxassetid://16380816785";
	Name="Resource Gatherers Cooldown";
	Description="A squadmate helped you pick up some items.";
	Buff=true;
};

library:Add{
	Id="Chained";
	Icon="rbxassetid://16716699240";
	Name="Chained";
	Description="You are chained to something. Maybe destroy it to break free?";
	Buff=false;
};


library:Add{
	Id="TireArmor";
	Icon="rbxassetid://16745983668";
	Name="Tire Armor";
	Description="Tire Armor Passive";
	Module=script.TireArmor;
	Buff=true;
};

library:Add{
	Id="FumesGas";
	Icon="rbxassetid://17203237389";
	Name="Fumes Gas";
	Description="Taking health damage from Fumes bypassing your gas protection.";
	Buff=false;
}

library:Add{
	Id="ItemHealth";
	Icon="rbxasset://textures/ui/GuiImagePlaceholder.png";
	Name="Item Health Hud";
	Description="$Desc";
	Buff=false;
}

library:Add{
	Id="LabCoat";
	Icon="rbxassetid://4978200934";
	Name="LabCoat";
	Description="Your Lab Coat adds 30% extra gas protection to gas damages.";
	Buff=true;
}

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;