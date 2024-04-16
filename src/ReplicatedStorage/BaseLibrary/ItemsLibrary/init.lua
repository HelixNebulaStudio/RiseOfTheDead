local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local ItemsLibrary = {};
ItemsLibrary.__index = ItemsLibrary;

--== Script;

function ItemsLibrary:Init(super)
	--local Lib = super.Library;
	local function new(b, d) b.__index=b; super:Add(setmetatable(d, b)); end;
	
	--==========================================================[[ RESOURCE ]]==========================================================--
	local resourceBase = {
		Type = super.Types.Resource;
		Tradable = super.Tradable.Nontradable;
		Stackable = 200;
	};
	
	-- Common
	new(resourceBase, {Id="metal"; Name="Metal Scraps"; Icon="rbxassetid://1551792125"; Description="Metallic scraps used in crafting metal objects.";});
	new(resourceBase, {Id="glass"; Name="Glass Shards"; Icon="rbxassetid://1551792117"; Description="Glass shards and pieces used in crafting glass objects.";});
	new(resourceBase, {Id="wood"; Name="Wooden Parts"; Icon="rbxassetid://1551280660"; Description="Wooden parts used in crafting wooden objects.";});
	new(resourceBase, {Id="cloth"; Name="Cloth"; Icon="rbxassetid://3580309486"; Description="Cloth used in crafting clothing or medical supplies.";});
	new(resourceBase, {Id="screws"; Name="Screws & Nails"; Icon="rbxassetid://16520368724"; Description="Screws & Nails used in crafting structures.";});
	new(resourceBase, {Id="adhesive"; Name="Sticky Adhesive"; Icon="rbxassetid://16816518567"; Description="Sticky adhesive is a strong binding glue used in sticking objects together.";});
	
	new(resourceBase, {Id="steelfragments"; Name="Steel Fragments"; Icon="rbxassetid://8815170269"; Description="Steel Fragments used in crafting high quality items."; Sources={"Obtainable from <b>Lewis in the Rat Harbor Safehouse</b>";};});
	new(resourceBase, {Id="nekronparticulate"; Name="Nekron Particulate"; Icon="rbxassetid://11121659627"; Description="A tube of synthesized Nekron Particulate."; Sources={"Obtainable from <b>Coop: Sunken Ship</b>";};});

	new(resourceBase, {Id="coal"; Name="Coal"; Icon="rbxassetid://6117038530"; Description="A low grade fire fuel source."; Sources={"Obtained from <b>The Underground Cave</b>";} });
	new(resourceBase, {Id="sulfur"; Name="Sulfur"; Icon="rbxassetid://12122140942"; Description="Used in crafting gun powder and explosives."; Sources={"Obtained from <b>The Harbor Caves</b>";} });
	new(resourceBase, {Id="gunpowder"; Name="Gun Powder"; Icon="rbxassetid://12122129617"; Description="Used in crafting ammunition.";});
	
	new(resourceBase, {Id="nekronscales"; Name="Nekron Scales"; Icon="rbxassetid://14479314520"; Description="Dead and dried scales of Nekron."; Sources={"Obtainable from <b>Elder Vexeron's Tumours</b>"; "Obtainable from <b>Tendrils</b>"; "Mined from <b>Sector F</b>";};});


	--=========================================================[[ COMPONENTS ]]==========================================================--
	local componentsBase = {
		Type = super.Types.Component;
		Tradable = super.Tradable.PremiumOnly;
		Stackable = 10;
		NonPremiumTax = 5;
	};

	new(componentsBase, {Id="metalpipes"; Name="Metal Pipes"; Icon="rbxassetid://3238326135"; Description="Useful for transfering liquid or gas.";});
	new(componentsBase, {Id="igniter"; Name="Igniter"; Icon="rbxassetid://3238394477"; Description="Creates a spark when used, useful for igniting something.";});
	new(componentsBase, {Id="gastank"; Name="Gas Tank"; Icon="rbxassetid://3238394723"; Description="Useful for storing liquid or gas.";});
	new(componentsBase, {Id="battery"; Name="Battery"; Icon="rbxassetid://3592076927"; Description="Useful for storing electricity."; BaseValues={Power=100}; StackMatch={"Power"}});
	new(componentsBase, {Id="wires"; Name="Wires"; Icon="rbxassetid://3592663953"; Description="Useful for transfering electricity.";});
	new(componentsBase, {Id="motor"; Name="Electric Motor"; Icon="rbxassetid://3621925030"; Description="Useful for making things spin or generating electricity.";});
	new(componentsBase, {Id="circuitboards"; Name="Circuit Boards"; Icon="rbxassetid://4327228467"; Description="Useful for making electronic devices.";});
	new(componentsBase, {Id="lightbulb"; Name="Light Bulb"; Icon="rbxassetid://4578932663"; Description="Useful for lighting up the place.";});
	new(componentsBase, {Id="radiator"; Name="Radiator"; Icon="rbxassetid://4697683304"; Description="Useful to removing thermal energy.";});
	new(componentsBase, {Id="toxiccontainer"; Name="Toxic Waste Container"; Icon="rbxassetid://4819059189"; Description="Contains 1 kilogram of securely contained toxic waste.";});
	new(componentsBase, {Id="gears"; Name="Gears"; Icon="rbxassetid://10964927455"; Description="Useful for functional mechanisms.";});
	new(componentsBase, {Id="liquidmetalpolish"; Name="Liquid Metal Polish"; Icon="rbxassetid://12784244819"; Description="Useful for polishing tools and weapons.";});
	new(componentsBase, {Id="rope"; Name="Rope"; Icon="rbxassetid://13265271329"; Description="Useful for tying things together.";});
	new(componentsBase, {Id="tires"; Name="Tires"; Icon="rbxassetid://16836806362"; Description="Sturdy looking tires..";});
	
	new(componentsBase, {Id="tier2augment"; Name="Tier 2 Augment"; TradingTax = 50; Icon="rbxassetid://16903224330"; Description="An augment to upgrade mods to tier 2."; });
	new(componentsBase, {Id="tier3augment"; Name="Tier 3 Augment"; TradingTax = 100; Icon="rbxassetid://16903249001"; Description="An augment to upgrade mods to tier 3."; });
	new(componentsBase, {Id="tier4augment"; Name="Tier 4 Augment"; TradingTax = 200; Icon="rbxassetid://16910121022"; Description="An augment to upgrade mods to tier 4."; });

	--==========================================================[[ WEAPONS ]]==========================================================--
	local gunBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.PremiumOnly;
		Tags = {"Gun"; "Weapon"};
		SkinWear = true;
		NonPremiumTax = 1000;
	}
	new(gunBase, {Id="p250"; Name="P250"; Icon="rbxassetid://17007248915"; Tags={"Pistol"}; Description="A handy pistol."; Sources={"Obtained from <b>Mason in The Beginning</b>";};});
	new(gunBase, {Id="cz75"; Name="CZ75-Auto"; Icon="rbxassetid://17007239643"; Tags={"Pistol"}; Description="High fire-rate automatic pistol. Has built in <b>Damage Rev</b>, which does more damage the lower your ammo count is in your magazine.";});
	new(gunBase, {Id="tec9"; Name="Tec-9"; Icon="rbxassetid://17007237750"; Tags={"Pistol"}; Description="High power, high firerate pistol. Has built in <b>Auto Trigger</b>, which sets the firing mode to automatic.";});
	new(gunBase, {Id="dualp250"; Name="Dual P250"; Icon="rbxassetid://17007236263"; Tags={"Pistol"}; Description="Two handy pistols. Is a <b>Dual Wield</b> weapon.";});
	new(gunBase, {Id="m9legacy"; Name="M9 Legacy"; Icon="rbxassetid://3296446616"; Tags={"Pistol"}; Description="A handy legacy pistol.";});
	new(gunBase, {Id="revolver454"; Name="Revolver 454"; Icon="rbxassetid://2009719243"; Tags={"Pistol"}; Description="Also known as the Raging Bull 454, high power, high fire-rate revolver.";});
	new(gunBase, {Id="deagle"; Name="Desert Eagle"; Icon="rbxassetid://16238188322"; Tags={"Pistol"}; Description="The hand cannon. Has built in <b>Focus Charge</b>, which does more damage if you charge your focus by aiming down sights.";}); --rbxassetid://5166288732 

	new(gunBase, {Id="xm1014"; Name="XM1014"; Icon="rbxassetid://6523762932"; Tags={"Shotgun"}; Description="Quick fire-rate long barrel shotgun.";});
	new(gunBase, {Id="sawedoff"; Name="Sawed-Off"; Icon="rbxassetid://17007247358"; Tags={"Shotgun"}; Description="Close range head remover with high multishot.";});
	new(gunBase, {Id="mariner590"; Name="Mariner 590"; Icon="rbxassetid://17007243924"; Tags={"Shotgun"}; Description="Quick and high damage tactical shotgun.";});
	new(gunBase, {Id="rusty48"; Name="Rusty 48"; Icon="rbxassetid://10390716871"; Tags={"Shotgun"}; Description="Powerful hand made shotgun with built-in <b>Crit Receiver</b>.";});

	new(gunBase, {Id="mp5"; Name="MP5"; Icon="rbxassetid://9960159062"; Tags={"Submachine gun"}; Description="Quick fire-rate sub-machine gun.";});
	new(gunBase, {Id="mp7"; Name="MP7"; Icon="rbxassetid://9960161355"; Tags={"Submachine gun"}; Description="Good accuracy and damage sub-machine gun.";});
	new(gunBase, {Id="czevo3"; Name="CZ-Scorpion EVO 3"; Icon="rbxassetid://4814129724"; Tags={"Submachine gun"}; Description="Extremely tactical sub-machine gun with a high base damage. Has built in <b>Damage Rev</b>, which does more damage the lower your ammo count is in your magazine.";});
	new(gunBase, {Id="vectorx"; Name="Vector X"; Icon="rbxassetid://8527896764"; Tags={"Submachine gun"}; NonPremiumTax = 4900; Description="Elite sub-machine gun with built-in <b>Crit Receiver</b> and suppressor.";});

	new(gunBase, {Id="m4a4"; Name="M4A4"; Icon="rbxassetid://5166150878"; Tags={"Rifle"}; Description="Military grade M4 rifle capable of high damage and long range shooting.";});
	new(gunBase, {Id="ak47"; Name="AK-47"; Icon="rbxassetid://5166397129"; Tags={"Rifle"}; Description="High damage, high magazine capacity, and great fire-rate. Quite a noise maker.";});
	new(gunBase, {Id="fnfal"; Name="FN FAL"; Icon="rbxassetid://17007249959"; Tags={"Rifle"}; Description="The FN FAL is a high damage rifle with a very high fire rate.";});
	new(gunBase, {Id="sr308"; Name="SR-308"; Icon="rbxassetid://16570523670"; Tags={"Rifle"}; Description="Ergonomic Russian battle rifle. Built with a special type of receiver that has a chance to fire a critical shot.";});
	
	new(gunBase, {Id="awp"; Name="AWP"; Icon="rbxassetid://5166454078"; Tags={"Sniper"}; Description="High Damage, high recoil and long ranged rifle.";});
	new(gunBase, {Id="rec21"; Name="Rec-21"; Icon="rbxassetid://6532745901"; Tags={"Sniper"}; Description="High power, light weight tactical sniper rifle.";});
	
	new(gunBase, {Id="minigun"; Name="Minigun"; Icon="rbxassetid://5175211604"; Tags={"Heavy machine gun"}; Description="It weighs fifty seven kilograms and fires two hundred dollar, custom-tooled cartridges at ten thousand rounds per minute. It costs four hundred thousand dollars to fire this weapon... for twelve seconds.";});
	new(gunBase, {Id="desolatorheavy"; Name="Desolator Heavy"; Icon="rbxassetid://6244386293"; Tags={"Heavy machine gun"}; Description="Heavy machine gun that desolates your enemies. Design inspired by the negev LMG, the Desolator Heavy is a high power concentrated machine gun firing heavy rounds with built-in <b>Rapid Fire</b> enabled. Weapon accuracy will increase as the weapon warms up from firing.";});
	
	new(gunBase, {Id="flamethrower"; Name="Flamethrower"; Icon="rbxassetid://17005466120"; Tags={"Incendiary"; "Launcher"}; Description="Burn zombies, burn!";});

	new(gunBase, {Id="grenadelauncher"; Name="Grenade Launcher"; Icon="rbxassetid://17005464588"; Tags={"Explosive"; "Launcher"}; Description="Explosion does area-of-effect damage, meaning the damage is divided by the amount of enemies in the area and overall an amazing killing machine.";});
	new(gunBase, {Id="at4"; Name="AT4 Rocket Launcher"; Icon="rbxassetid://6436980949"; Tags={"Explosive"; "Launcher"}; Description="Perfectly designed to annihilate hordes and hordes of zombies.";});
	
	new(gunBase, {Id="tacticalbow"; Name="Tactical Bow"; Icon="rbxassetid://5456918610"; Tags={"Bow"}; NonPremiumTax = 4900; Description="High damage tactical bow.";});
	new(gunBase, {Id="arelshiftcross"; Name="Arelshift Cross"; Icon="rbxassetid://13161587904"; Tags={"Bow";}; NonPremiumTax = 9900; Description="A scoped semi-automatic crossbow.";});

	
	local meleeBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.PremiumOnly;
		Tags = {"Melee"; "Weapon"};
		SkinWear = true;
		NonPremiumTax = 500;
	}
	new(meleeBase, {Id="survivalknife"; Name="Survival Knife"; Icon="rbxassetid://3681185617"; Tags={"Edged Melee"}; Description="Knife designed to be used in survival situations.";});
	new(meleeBase, {Id="machete"; Name="Machete"; Icon="rbxassetid://4469866502"; Tags={"Edged Melee"}; Description="A heavy duty zombie killer, can't get far without it.";});
	new(meleeBase, {Id="jacksscythe"; Name="Jack's Scythe"; Icon="rbxassetid://5816459861"; Tags={"Edged Melee"}; Description="Jack's very own scythe.";});
	new(meleeBase, {Id="chainsaw"; Name="Chainsaw"; Icon="rbxassetid://7319587982"; Tags={"Edged Melee"}; Description="Cutting through zombies has never been easier.";});

	new(meleeBase, {Id="spikedbat"; Name="Spiked Bat"; Icon="rbxassetid://4600968105"; Tags={"Blunt Melee"}; Description="Time to hit some home runs on these zombies.";});
	new(meleeBase, {Id="crowbar"; Name="Crowbar"; Icon="rbxassetid://4843541333"; Tags={"Blunt Melee"}; Description="A handy tool to break free.";});
	new(meleeBase, {Id="sledgehammer"; Name="Sledgehammer"; Icon="rbxassetid://5175332306"; Tags={"Blunt Melee"}; Description="A construction grade sledgehammer.";});
	new(meleeBase, {Id="naughtycane"; Name="Naughty Cane"; Icon="rbxassetid://5966504204"; Tags={"Blunt Melee"}; Description="Bad zombie! *bonk*";});
	new(meleeBase, {Id="shovel"; Name="Shovel"; Icon="rbxassetid://8814526891"; Tags={"Blunt Melee"}; Description="A gardener's trusty shovel. Good for digging graves and maybe sand on the seabed.";});
	
	new(meleeBase, {Id="pickaxe"; Name="Pickaxe"; Icon="rbxassetid://5175332073"; Tags={"Pointed Melee"; "Throwable"}; Description="A construction grade pickaxe. Throwing does 2% of the enemies' max health on impact, minimal throw damage is half of weapon's damage. Does not consume on throw.";});
	new(meleeBase, {Id="broomspear"; Name="Broom Spear"; Icon="rbxassetid://5120882769"; Tags={"Pointed Melee"; "Throwable"}; Description="Chipped out from a broom stick. Throwing does 2% of the enemies' max health on impact, minimal throw damage is half of weapon's damage. Does not consume on throw.";});
	
	new(meleeBase, {Id="fireaxe"; Name="Fire Axe"; Icon="rbxassetid://12865194088"; Tags={"Edged Melee"}; Description="Not exactly an axe on fire. 66% chance to ignite enemies for 5 seconds dealing 50 x Stack + 1% of enemy's Current Health.";});

	new(meleeBase, {Id="inquisitorssword"; Name="The Inquisitor's Sword"; Icon="rbxassetid://12163013682"; Tradable=super.Tradable.Nontradable; Tags={"Edged Melee"; "Unobtainable"}; Description="The Inquisitor's Sword, earned by contributing to the inquisition of bugs and testing in Rise of the Dead.";});
	new(meleeBase, {Id="tankerrebar"; Name="Tanker's Rebar"; Icon="rbxassetid://16798723165"; Tradable=super.Tradable.Nontradable; Tags={"Blunt Melee"; "Unobtainable"}; Description="Rebar with a slab of concrete stuck to its end. Used by the Tanker.";});

	
	--==========================================================[[ Throwables ]]==========================================================--
	local throwableBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.Tradable;
		Tags = {"Throwable"; "Weapon"};
		Stackable = 10;
	}
	
	new(throwableBase, {Id="mk2grenade"; Name="Mk2 Grenade"; Icon="rbxassetid://5018436895"; Tags={"Explosive"}; Description="Throwable explosive thingy. Does 5% of the enemies' max health on explode, minimal damage is 100.";});
	new(throwableBase, {Id="stickygrenade"; Name="Sticky Grenade"; Icon="rbxassetid://5106343976"; Tags={"Explosive"}; Description="Sticks to surfaces thrown on. Does 10% of the enemies' max health on explode, minimal damage is 200.";});
	new(throwableBase, {Id="explosives"; Name="Explosives"; Icon="rbxassetid://7304930076"; Tags={"Explosive"}; Description="Does 10% of the enemies' max health when thrown, minimal damage is 50.";});
	
	new(throwableBase, {Id="molotov"; Name="Molotov"; Icon="rbxassetid://5088295501"; Tags={"Incendiary"}; Description="Ignites surrounding area on fire on impact, does 5%(Min: 10 damage) of the enemies' max health every 0.5 seconds.";});
	
	new(throwableBase, {Id="snowballs"; Name="Snowballs"; Icon="rbxassetid://11464691441"; Stackable=false; Tags={"Frostivus"}; Description="Who wants a snowball fight? Does special damage to Winter Treelums.";});
	
	--==========================================================[[ CLOTHING ]]==========================================================--
	local clothingBase = {
		Type = super.Types.Clothing;
		Tradable = super.Tradable.Tradable;
		Tags = {};
		
		OnInstantiate=function(storageItem, itemData)
			if not super:HasTag(storageItem.ItemId, "Head") then return end;
			
			local rawItemValues = itemData and itemData.Values;
			if rawItemValues and rawItemValues.Seed then return end;
			
			storageItem:SetValues("Seed", math.random(1, 999));
		end
	}
	
	-- Head
	new(clothingBase, {Id="cowboyhat"; Name="Cowboy Hat"; Icon="rbxassetid://4994923375"; Tags={"Head"}; Description="I will be the one yeeee-haw-ing around here.";});
	new(clothingBase, {Id="gasmask"; Name="Gas Mask"; Icon="rbxassetid://6971981402"; Tags={"Head"}; Description="Hudda hudda huuh! Reduce effects and damage from gas clouds and toxic damages.";});
	new(clothingBase, {Id="nekronmask"; Name="Nekron Mask"; Icon="rbxassetid://5419783427"; Tags={"Head"}; Description="Once you put it on, the mask will start consuming itself and some zombies will start looking like you.. (It will continue to consume even if you take the mask off.)"; Sources={"Obtained in <b>Mission: Vindictive Treasure</b>";};  });
	new(clothingBase, {Id="cultisthood"; Name="Cultist Hood"; Icon="rbxassetid://5550425398"; Tags={"Head"}; Description="Live in the shadows and pull the strings.."; Sources={"Obtained in <b>Mission: Vindictive Treasure</b>";};  });
	new(clothingBase, {Id="onyxhoodiehood"; Name="OnyxHound Hoodie's Hood"; Icon="rbxassetid://5644700762"; Tags={"Head"}; Description="Ultra Rare OnyxHound Hood.";});
	new(clothingBase, {Id="disguisekit"; Name="Disguise Kit"; Icon="rbxassetid://5783987908"; Tags={"Head"}; Usable="Disguise"; Description="Disguise yourself as anything available. Right-click to open disguse menu. To unlock new disguises, get kills in order to unlock. Unlock progress only saves on this item, so deleting this item will lose your disguise progression. Trading this item will also lose all kills saved in this item.";});
	new(clothingBase, {Id="nvg"; Name="Night Vision Goggles"; Icon="rbxassetid://6008673515"; Tags={"Head"}; Description="Night vision goggles. Enhances visibility in the dark.";});
	new(clothingBase, {Id="strawhat"; Name="Straw Hat"; Icon="rbxassetid://6416330399"; Tags={"Head"}; Description="It ain't much, but it's honest hard work.";});
	new(clothingBase, {Id="zriceraskull"; Name="Zricera Skull"; Icon="rbxassetid://6806306800"; Tags={"Head"}; Description="Strength of a beast and shield of the skull.";});
	new(clothingBase, {Id="hazmathood"; Name="Hazmat Hood"; Icon="rbxassetid://7021892111"; Tags={"Head"}; Description="Hazmat hood part of the hazmat suit.";});
	new(clothingBase, {Id="tophat"; Name="Top Hat"; Icon="rbxassetid://7558620967"; Tags={"Head"; "Slaughterfest";}; Description="Just like Jack Reap's top hat.";});
	new(clothingBase, {Id="clownmask"; Name="Clown Mask"; Icon="rbxassetid://7558621997"; Tags={"Head"; "Slaughterfest";}; Description="Creepy clown mask.";});
	new(clothingBase, {Id="divinggoggles"; Name="Diving Goggles"; Icon="rbxassetid://10332700358"; Tags={"Head"; "Diving Gear"}; Description="Improves underwater visibility.";});
	new(clothingBase, {Id="balaclava"; Name="Balaclava"; Icon="rbxassetid://8596749820"; Tags={"Head"}; Description="Balaclava just looks funny.";});
	new(clothingBase, {Id="skullmask"; Name="Skull Mask"; Icon="rbxassetid://11235442025"; Tags={"Head"; "Slaughterfest";}; Description="Spooky, scary skeletons. Send shivers down your spine..";});
	new(clothingBase, {Id="maraudersmask"; Name="Marauder's Mask"; Icon="rbxassetid://11269436198"; Tags={"Head"; "Slaughterfest";}; Description="The silent marauder stalks it's prey at night.";});
	new(clothingBase, {Id="clothbagmask"; Name="Cloth Bag Mask"; Icon="rbxassetid://13985462066"; Tags={"Head";}; Description="Cloth bag mask, great for covering hostages' head and limit vision.";});
	new(clothingBase, {Id="hardhat"; Name="Hard Hat"; Icon="rbxassetid://12439223859"; Tags={"Head";}; Description="A construction hard hat, provides light to the surrounding.";});
	new(clothingBase, {Id="fedora"; Name="Fedora"; Icon="rbxassetid://14235302470"; Tags={"Head";}; Description="*Tips Fedora*";});
	new(clothingBase, {Id="santahat"; Name="Santa Hat"; Tradable=super.Tradable.Tradable; Icon="rbxassetid://6108356239"; Tags={"Head"; "Christmas"; "Frostivus"}; Description="Merry Christmas, ho ho ho!";});
	new(clothingBase, {Id="greensantahat"; Name="Green Santa Hat"; Tradable=super.Tradable.Tradable; Icon="rbxassetid://6122942270"; Tags={"Head"; "Christmas"; "Frostivus"}; Description="Merry Christmas, ho ho ho!";});
	new(clothingBase, {Id="bunnymanhead"; Name="Bunny Man's Head"; Icon="rbxassetid://4845183167"; Tags={"Head"; "Easter"}; Description="Bunny Man's Headwear. Normal environmental Zombies will ignore you during the Easter event.\nEvent-Active: "..tostring(modConfigurations.SpecialEvent.Easter); Sources={"Obtained from <b>The Bunny Man in Mission: Bunny Man's Eggs</b>";};});
	new(clothingBase, {Id="jackolantern"; Name="Jack o' Lantern"; Icon="rbxassetid://14951707178"; Tags={"Head";}; Description="Where Jack watches through the jacks o lanterns.";});

	-- Chest
	new(clothingBase, {Id="greytshirt"; Name="T-Shirt"; Icon="rbxassetid://5756503297"; Tags={"Chest"}; Description="Comfy T-Shirt. Gives you 1 armor point for protection.";});
	new(clothingBase, {Id="xmassweater"; Name="Xmas Sweater"; Tradable=super.Tradable.Tradable; Icon="rbxassetid://6126020940"; Tags={"Chest"; "Christmas"; "Frostivus"}; Description="Xmas Sweater.";});
	new(clothingBase, {Id="prisonshirt"; Name="Prisoner's Shirt"; Icon="rbxassetid://5627570767"; Tags={"Chest"}; Description="The Prisoner's Shirt.";});
	new(clothingBase, {Id="onyxhoodie"; Name="OnyxHound Hoodie"; Icon="rbxassetid://5642499590"; Tags={"Chest"}; Description="Rare OnyxHound Hoodie.";});
	new(clothingBase, {Id="labcoat"; Name="Lab Coat"; Icon="rbxassetid://4978200934"; Tags={"Chest"}; Description="\"Education is what remains after one has forgotten everything he learned in school.\" ~ A.E. Also prevents consecutive tick explosion damage.";});
	new(clothingBase, {Id="plankarmor"; Name="Plank Armor"; Icon="rbxassetid://5765969051"; Tags={"Chest"}; Description="Makeshift wooden plank armor.";});
	new(clothingBase, {Id="scraparmor"; Name="Scrap Armor"; Icon="rbxassetid://6996766551"; Tags={"Chest"}; Description="Makeshift metal scrap armor.";});
	new(clothingBase, {Id="highvisjacket"; Name="High Visibility Jacket"; Icon="rbxassetid://8488333823"; Tags={"Chest"}; Description="The high visibility jacket provides warmth and armor points.";});
	new(clothingBase, {Id="nekrostrench"; Name="Nekros Trench Coat"; Icon="rbxassetid://14423236705"; Tags={"Chest"}; Description="Trench coat covered in dried Nekron leather, scales and veins. <b>Passive:</b> +2HP/s, The passive will be disabled for 15s if you take any damage.";});
	new(clothingBase, {Id="tirearmor"; Name="Tire Armor"; Icon="rbxassetid://16791518600"; Tags={"Chest"}; Description="Tire armor, made with tires. <b>Passive:</b> When equipping a melee, grants a 60% chance to block 20 damage from melee attacks. Reduced minimum damage is capped at 1 damage.";});

	-- Pants
	new(clothingBase, {Id="prisonpants"; Name="Prisoner's Pants"; Icon="rbxassetid://5627737032"; Tags={"Legs"}; Description="The Prisoner's Pants.";});
	
	-- Gloves
	new(clothingBase, {Id="leathergloves"; Name="Leather Gloves"; Icon="rbxassetid://16988021003"; Tags={"Gloves"}; Description="Helps reduce pressure on your grips, providing additional 30 max stamina.";});
	new(clothingBase, {Id="armwraps"; Name="Arm Wraps"; Icon="rbxassetid://7068678585"; Tags={"Gloves"}; Description="Everybody was kung fu fightin'.";});
	new(clothingBase, {Id="vexgloves"; Name="Vexeron Gloves"; Icon="rbxassetid://7181328504"; Tags={"Gloves"}; Description="Gloves made with Vexeron skin, providing additional 50 max stamina.";});
	
	-- Shoes
	new(clothingBase, {Id="brownleatherboots"; Name="Brown Leather Boots"; Icon="rbxassetid://4866819545"; Tags={"Shoes"}; Description="These look great on you. Reduces movement impairment debuffs by 10%.";});
	new(clothingBase, {Id="militaryboots"; Name="Military Boots"; Icon="rbxassetid://17022087037"; Tags={"Shoes"}; Description="Military grade boots. Reduces movement impairment debuffs by 20%.";});
	new(clothingBase, {Id="divingfins"; Name="Diving Fins"; Icon="rbxassetid://10334749462"; Tags={"Shoes"; "Diving Gear"}; Description="Improves underwater mobility.";});

	-- Misc Wear
	new(clothingBase, {Id="brownbelt"; Name="Tactical Belt"; Icon="rbxassetid://4789684750"; Tags={"Belt"; "Utility Wear";}; Description="A tactical belt. Adds an extra hot bar slot.";});
	new(clothingBase, {Id="watch"; Name="Watch"; Icon="rbxassetid://6306934431"; Tags={"Utility Wear";}; Description="Tick-tock-tick-tock. Tells the time.";});
	new(clothingBase, {Id="divingsuit"; Name="Diving Suit"; Icon="rbxassetid://10342826622"; Tags={"FullBody"; "Diving Gear"; "Utility Wear";}; Description="Reduces oxygen cost while being underwater and increases oxygen restore rate.";});
	new(clothingBase, {Id="inflatablebuoy"; Name="Inflatable Buoy"; Icon="rbxassetid://10393385339"; Tags={"Utility Wear";}; Description="Helps you float to the top when swimming.";});
	new(clothingBase, {Id="mercskneepads"; Name="Merc's Knee Pads"; Icon="rbxassetid://11026588384"; Tags={"Utility Wear"}; Description="A mercenary's favourite holster and knee pads. Tactical holsters, reduces tool equip time by 40%.";});
	new(clothingBase, {Id="portableautoturret"; TradingTax=9900; Usable="Configure"; CanVanity=false; Name="Portable Auto Turret"; Icon="rbxassetid://16402082812"; Tags={"Utility Wear"}; Description="A wearable portable auto turret designed by the Mysterious Engineer. Requires batteries to run. Configure to equipped your weapon onto the arm and fine tune the P.A.T. to how you want it to function, but due to it's crude nature, the arm's aim accuracy can be underwhelming and reload times are 3x as slow."; Sources={"Obtained in <b>Mission: Belly of the Beast</b>";}; });

	local storageBase = {
		Type = super.Types.Clothing;
		Tradable = super.Tradable.Tradable;
		Tags = {"Storage"};
		Usable="Open";
		Description="Portable storage with 15 max slots. Deleting this item will not lose your items. Right-click to open storage.";
	}

	new(storageBase, {Id="dufflebag"; Name="Duffle Bag"; Icon="rbxassetid://8827967921";});
	new(storageBase, {Id="survivorsbackpack"; Name="Survivor's Backpack"; Icon="rbxassetid://8948320931";});
	new(storageBase, {Id="ammopouch"; Name="Ammo Pouch"; Tags={"Unobtainable"}; Icon="rbxassetid://7335420098";});

	--==========================================================[[ CRATES ]]==========================================================--
	local crateBase = {
		Type = super.Types.Structure;
		Tradable = super.Tradable.Tradable;
		TradingTax = 20;
		Stackable = 10;
		Description = "Open it to see what you got from the crate.";
		Tags = {"Crate"};
		OnAdd = function(data)
			local gameModeData = data.GameMode;
			if gameModeData then
				data.Name = (gameModeData.HardPrefix and gameModeData.HardPrefix.." " or "")..gameModeData.Stage.." "..(gameModeData.CrateSynonym or "Crate");
				data.Description = "Open it to see what you got from "..gameModeData.Mode..": "..gameModeData.Stage.."."
			end
		end;
	};

	new(crateBase, {Id="factorycrate"; Icon="rbxassetid://14312691944"; GameMode={Mode="Raid"; Stage="Factory"}}); --4696383140
	new(crateBase, {Id="officecrate"; Icon="rbxassetid://14312329063"; GameMode={Mode="Raid"; Stage="Office"}}); --4696383140
	new(crateBase, {Id="sectorfcrate"; Icon="rbxassetid://4818954646"; GameMode={Mode="Survival"; Stage="Sector F"}});
	new(crateBase, {Id="ucsectorfcrate"; Icon="rbxassetid://4873382562"; GameMode={Mode="Survival"; Stage="Sector F"; HardPrefix="Unclassified"}});
	new(crateBase, {Id="tombschest"; Icon="rbxassetid://5520269296"; GameMode={Mode="Raid"; Stage="Tombs"}});
	new(crateBase, {Id="banditcrate"; Icon="rbxassetid://5766579781"; GameMode={Mode="Raid"; Stage="BanditOutpost"}});
	new(crateBase, {Id="hbanditcrate"; Icon="rbxassetid://7050600251"; GameMode={Mode="Raid"; Stage="BanditOutpost"; HardPrefix="Murderous"}});
	new(crateBase, {Id="prisoncrate"; Icon="rbxassetid://6254312214"; GameMode={Mode="Survival"; Stage="Prison"}});
	new(crateBase, {Id="nprisoncrate"; Icon="rbxassetid://6254312507"; GameMode={Mode="Survival"; Stage="Prison"; HardPrefix="Notorious"}});
	new(crateBase, {Id="railwayscrate"; Icon="rbxassetid://6503604137"; GameMode={Mode="Raid"; Stage="Railways"}});
	new(crateBase, {Id="sectordcrate"; Icon="rbxassetid://7180738901"; GameMode={Mode="Survival"; Stage="Sector D"}});
	new(crateBase, {Id="ucsectordcrate"; Icon="rbxassetid://7180739567"; GameMode={Mode="Survival"; Stage="Sector D"; HardPrefix="Unclassified"}});
	new(crateBase, {Id="genesiscrate"; Icon="rbxassetid://7432376696"; GameMode={Mode="Coop"; Stage="Genesis"}});
	new(crateBase, {Id="ggenesiscrate"; Icon="rbxassetid://16791016380"; GameMode={Mode="Coop"; Stage="Genesis"; HardPrefix="Golden";}});
	new(crateBase, {Id="sunkenchest"; Icon="rbxassetid://10971583849"; GameMode={Mode="Coop"; Stage="SunkenShip"; CrateSynonym="Chest";}});
	new(crateBase, {Id="abandonedbunkercrate"; Icon="rbxassetid://13495111655"; GameMode={Mode="Raid"; Stage="Abandoned Bunker"}});
	
	new(crateBase, {Id="communitycrate"; Name="Community Crate: Alpha"; Icon="rbxassetid://13967718753"; Description="Obtained from community made maps, check gold shop for maps. Open and see what you get!";});
	new(crateBase, {Id="communitycrate2"; Name="Community Crate: Beta"; Icon="rbxassetid://13967726501"; Description="Obtained from community made maps, check gold shop for maps. Open and see what you get!";});


	--==========================================================[[ RESOURCE PACKAGES ]]==========================================================--
	local resourcePackageBase = {
		Type = super.Types.Structure;
		Tradable = super.Tradable.Tradable;
		TradingTax = 20;
		Stackable = 2;
		Description = "Open it to retrieve a stack of resource.";
		Tags = {"ResourcePackage"; "Crate";};
		OnAdd = function(data)
			local resourceItemId = data.ResourceItemId;
			local itemLib = super:Find(resourceItemId);
			
			if itemLib then
				local stackable = tonumber(itemLib.Stackable) or 1;
				
				data.Name = itemLib.Name .." Package";
				data.Description = "Open it to retrieve <b>".. stackable .." ".. itemLib.Name .."</b>.";
			end
		end;
	};
	new(resourcePackageBase, {Id="metalpackage"; Icon="rbxassetid://11809270023"; ResourceItemId="metal";});
	new(resourcePackageBase, {Id="glasspackage"; Icon="rbxassetid://11809444229"; ResourceItemId="glass";});
	new(resourcePackageBase, {Id="woodpackage"; Icon="rbxassetid://11809443142"; ResourceItemId="wood";});
	new(resourcePackageBase, {Id="clothpackage"; Icon="rbxassetid://11809442095"; ResourceItemId="cloth";});

	
	--=========================================================[[ COMMODITY ]]==========================================================--
	local commodityBase = {
		Type = super.Types.Commodity;
		Tradable = super.Tradable.Tradable;
		Stackable = 10;
	};
	
	new(commodityBase, {Id="charger"; Name="Charger"; Icon="rbxassetid://3598937412"; Description="It is useful for charging electrical devices.";});
	new(commodityBase, {Id="portablestove"; Name="Portable Stove"; Icon="rbxassetid://3610224355"; Stackable=false; Description="It is useful for cooking outdoors.";});
	new(commodityBase, {Id="lantern"; Name="Lantern"; Icon="rbxassetid://3681206568"; Stackable=false; Description="It is used to light up the dark.";});
	new(commodityBase, {Id="handgenerator"; Name="Hand Crank Generator"; Icon="rbxassetid://3681209212"; Description="You can generate electricity using this by kinetic motion. Crank that.. generator.";});
	new(commodityBase, {Id="walkietalkie"; Name="Walkie Talkie"; Icon="rbxassetid://4578978755"; Stackable=false; Description="Long distance communication.";});
	new(commodityBase, {Id="spotlight"; Name="Spotlight"; Icon="rbxassetid://4578977602"; Stackable=false; Description="A strong beam of light useful for spoting in the dark.";});
	new(commodityBase, {Id="musicbox"; Name="Music Box"; Icon="rbxassetid://4706460063"; Stackable=false; Description="Something to help with sanity.";});
	new(commodityBase, {Id="binoculars"; Name="Binoculars"; Icon="rbxassetid://4730982114"; Stackable=false; Description="Essential for spotting long range objects.";});
	new(commodityBase, {Id="boombox"; Name="Boombox"; Icon="rbxassetid://4997111675"; Stackable=false; BaseValues={Power=100}; Description="Used to annoy your neighbors. Press [E] to add custom tracks.";});
	new(commodityBase, {Id="wateringcan"; Name="Watering Can"; Icon="rbxassetid://5191385023"; Stackable=false; Description="Used for watering plants.";});
	new(commodityBase, {Id="gps"; Name="GPS"; Icon="rbxassetid://5932231243"; Stackable=false; Usable="Use"; Description="The item to get you home. Global Positioning System. Used to guide and fast travel to different locations by paying R.A.T. members. Press [E] to select a location.";});
	new(commodityBase, {Id="purplelemon"; Name="Purple Lemon"; Icon="rbxassetid://7188572954"; Stackable=3; Tradable=super.Tradable.PremiumOnly; Description="Purple colored lemons..?";});
	new(commodityBase, {Id="fotlcardgame"; Name="Fall of the Living: Card Game"; Icon="rbxassetid://10862651147"; Stackable=false; Tradable=super.Tradable.PremiumOnly; Description="Card game called Fall of the Living.. Play safe by not bluffing or take risks and bluff to gain an advantage.\n\n<b>Actions:</b>\nScavenging might yield 0-2 resources.\nAttacking with 10 resources is unblockable. \n\n<b>Card:</b>\n<font color='#8c5252'>Rouge</font>: Attack using 4 resources\n<font color='#78476f'>Rat</font>: Scavenge 3 resources\n<font color='#634335'>Bear</font>: Raid others for 2 resources\n<font color='#31564c'>Rabbit</font>: Pick 2 random card and switch cards\n<font color='#52622a'>Zombie</font>: Blocks rouge attacks.\n\nPlayers starts with 2 cards, if they have a card, they can perform the card's action legitimately. If they don't have the card, they can bluff their actions.";});
	new(commodityBase, {Id="rcetablet"; Name="RCE Tablet"; Icon="rbxassetid://14405843549"; Stackable=false; Equippable=true; Tradable=super.Tradable.PremiumOnly; Description="Revive Command Executor tablet, a portable computer that has built in capabilities to hack other devices.";});

	
	--=========================================================[[ STRUCTURE ]]==========================================================--
	local structureBase = {
		Type = super.Types.Structure;
		Tradable = super.Tradable.Tradable;
		Stackable = 4;
		Tags = {"Deployable";};
	};

	new(structureBase, {Id="metalbarricade"; Name="Metal Barricade"; Icon="rbxassetid://4379884129"; Description="Placable metal barricades.";});
	new(structureBase, {Id="scarecrow"; Name="Scarecrow"; Icon="rbxassetid://4493547734"; Description="Place-able scarecrows that baits the zombies with in a 64 unit radius. Not realistic enough to fool bosses though.";});
	new(structureBase, {Id="gastankied"; Name="Gas Tank IED"; Icon="rbxassetid://4494205256"; Description="A Improvised Explosive Device made with circuit boards, wires and some gas tanks. Does 24% Max Health (Max 100k damage) as damage and has an explosion stun of 10s.";});
	new(structureBase, {Id="barbedwooden"; Name="Barbed Wooden Fence"; Icon="rbxassetid://5803776520"; Description="Placable barbed wooden fence that does 1% damage per second to enemies and slows them to 4 units/s when touched.";});
	new(structureBase, {Id="snowman"; Name="Snowman"; Icon="rbxassetid://6122031351"; Description="Place-able snowman that baits the zombies with in a 64 unit radius. Not realistic enough to fool bosses though.";});
	new(structureBase, {Id="ticksnaretrap"; Name="Tick Snare Trap"; Icon="rbxassetid://16334398743"; Description="A snare trap that leashes a Tick that runs over it. Killing the leashed Tick resets the trap. It can leash up the 10 times.";});
	new(structureBase, {Id="barbedmetal"; Name="Barbed Metal Fence"; Icon="rbxassetid://16521233112"; Description="Placable barbed metal fence that does 1% damage per second to enemies and slows them to 2 units/s when touched.";});

	--==========================================================[[ Medical ]]==========================================================--
	local medicalBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.Tradable;
		Stackable = 3;
		Tags = {"Heal";};
	};

	new(medicalBase, {Id="medkit"; Name="Medkit"; Icon="rbxassetid://492009851"; Stackable=5; Description="Heals you for 35 health.";});
	new(medicalBase, {Id="largemedkit"; Name="Large Medkit"; Icon="rbxassetid://508762791"; Description="Heals you for 50 health.";});
	new(medicalBase, {Id="advmedkit"; Name="Advance Medkit"; Icon="rbxassetid://5008764919"; Description="Heals you for 75 health.";});

	--==========================================================[[ Tools ]]==========================================================--
	local toolBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.Tradable;
	}

	new(toolBase, {Id="fireworks"; Name="Fireworks"; Icon="rbxassetid://6235855080"; Stackable=5; Description="Fireworks lighting up the skies for the new year!";});
	new(toolBase, {Id="matchbox"; Name="Matchbox"; Icon="rbxassetid://6269033605"; Stackable=10; Description="Can be used to ignite up flammable liquids or fuses.";});
	new(toolBase, {Id="jerrycan"; Name="Jerrycan"; Icon="rbxassetid://5886813198"; BaseValues={Fuel=100}; Description="Steel-pressed container that holds highly flammable fuel. Ignited fuel will deal 1% of max health as damage (Min: 10).";});
	new(toolBase, {Id="entityleash"; Name="Entity Leash"; Icon="rbxassetid://6984027457"; Description="Used to leash an entity. It hooks on to a target and lock it's limbs with electrical signals.";});
	new(toolBase, {Id="ladder"; Name="Ladder"; Icon="rbxassetid://8423066485"; Description="Handy portable ladder.";});
	new(toolBase, {Id="lasso"; Name="Lasso"; Icon="rbxassetid://4988081716"; Description="\"Y'all need to start running!\" - Hector Shot";});
	new(toolBase, {Id="poster"; Name="Poster"; Icon="rbxassetid://9242720986"; Description="A poster to post decals in the world.";});
	new(toolBase, {Id="envelope"; Name="Envelope"; Icon="rbxassetid://9650288008"; Tags={"Unobtainable"}; Description="A envelope.";});
	new(toolBase, {Id="ammobox"; Name="Ammobox"; Icon="rbxassetid://12513100692"; Description="A box of ammo, can be placed down to refill ammo for one weapon.";})
	
	new(toolBase, {Id="wantedposter"; Name="Wanted Poster"; Icon="rbxassetid://12804897977"; Description="A poster for when you are looking for someone specific. This item can be given to Patrick to guarantee the next survivor in \"Another Survivor\".";
		OnInstantiate=function(storageItem)
			local values = storageItem.Values;
			if values.WantedNpc then return end;

			local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
			local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
			local rewardsList = modRewardsLibrary:Find("safehomeNpcs");
			local rewards = modDropRateCalculator.RollDrop(rewardsList);
			
			values.WantedNpc = rewards[1].Name;
		end;
	});
	
	new(toolBase, {Id="newspaper"; Name="Newspaper"; Icon="rbxassetid://13067267435"; Description="Wrighton Dale Daily, the newspaper.";});
	new(toolBase, {Id="blacklightstick"; Name="Blacklight Stick"; Icon="rbxassetid://13629470305"; Description="Reveals forbidden messages.";});
	new(toolBase, {Id="engineersplanner"; Name="Engineer's Planner"; Icon="rbxassetid://8894342011"; Description="Used to quickly build structures. Unlock structure plans with their respective blueprints to place plans. Interact with the plans to build with the required resources.";});

	--==========================================================[[ FOOD ]]==========================================================--
	local foodBase = {
		Type = super.Types.Food;
		Tradable = super.Tradable.Tradable;
		Stackable = 10;
	}
	
	new(foodBase, {Id="cannedbeans"; Name="Canned Beans"; Icon="rbxassetid://4466508636"; Description="Gives you 2 health per second for 30 seconds.";});
	new(foodBase, {Id="bloxycola"; Name="Bloxy Cola"; Icon="rbxassetid://5094119246"; Description="Increases sprinting speed and melee stamina regen by 20% and reduce regen delay from 5 to 2 seconds.";});
	new(foodBase, {Id="energydrink"; Name="Xp Energy Drink"; Icon="rbxassetid://5627435285"; TradingTax=20; NonPremiumTax=80; Tradable=super.Tradable.PremiumOnly; Description="Enaaargy! The energy drink to double your experience gain for the next hour.";});
	new(foodBase, {Id="chocobar"; Name="Chocolate Bar"; Icon="rbxassetid://5795159539"; Description="Edible happiess.";});
	new(foodBase, {Id="gumball"; Name="Gumball"; Icon="rbxassetid://6122669744"; Description="Chewy Gumball from the gumball machine. Gives you a random buff.";});
	new(foodBase, {Id="cannedfish"; Name="Canned Sardines"; Icon="rbxassetid://6961233944"; Description="Gives you 30% debuff resistance for 60 seconds.";});
	new(foodBase, {Id="annihilationsoda"; Name="Annihilation Soda"; Icon="rbxassetid://10368377851"; Description="Gives you an additional 10% crit chance for 2 minutes, even for weapons without crit chance. Crit multiplier for weapons without crit is x1.5 damage.";});
	new(foodBase, {Id="perkscupcake"; Name="Perks Cupcake"; Icon="rbxassetid://12806349482"; Tags={"Unobtainable";}; Description="Gives you 1000 perks.";});
	new(foodBase, {Id="sandwich"; Name="Sandwich"; Icon="rbxassetid://14880936365"; Description="Gives you 7.5 health per second for 10 seconds.";});
	new(foodBase, {Id="ziphoningserum"; Name="Ziphoning Serum"; Icon="rbxassetid://15936793820"; NonPremiumTax = 10; Description="Cleanse cleansable debuffs and gives you the Ziphoning buff for <b>3 minutes</b>.\nThe Ziphoning buff gives you <b>+1 hp/s</b> <i>(Increasable by Nekrosis Amplifier)</i> consumed from the ziphon health pool, the ziphon health pool only fills up when you do damage to enemies.";});

	--==========================================================[[ MISSION ]]==========================================================--
	local missionBase = {
		Type = super.Types.Mission;
		CanBeRenamed=false;
	};

	new(missionBase, {Id="oddbluebook"; Name="Odd-looking Blue Book"; Icon="rbxassetid://289066042"; Description="An odd looking blue book, I wonder what's it about."; Sources={"Obtained in <b>Mission: Stephanie's Book</b>";};  });
	new(missionBase, {Id="zombiearm"; Name="Zombie Arm"; Icon="rbxassetid://2751766625"; Description="Dr. Deniski needs it."; Sources={"Obtained in <b>Mission: Stephanie's Book</b>";};  });
	new(missionBase, {Id="antibiotics"; Name="Antibiotics"; Icon="rbxassetid://1551829670"; Description="Jefferson needs it."; Sources={"Obtained from a secret mission";};  });
	new(missionBase, {Id="sewerskey1"; Name="Sewers Maintenance Key"; Icon="rbxassetid://4366400646"; Description="Maintenance key used to unlock the maintenance room in the sewers."; Sources={"Obtained from <b>Carlson in Mission: The Backup Plan</b>";};  });
	new(missionBase, {Id="cultistnote1"; Name="Cultist Note"; Icon="rbxassetid://5538983878"; Description="\"A hireling of the venator has stolen the mask. They do not have any clue what they are messing with. Eradicate and retrieve the mask immediately before they unleash hellfire upon everyone.\" ~S.F."; Sources={"Obtained in <b>Mission: Vindictive Treasure</b>";};  });
	new(missionBase, {Id="researchpapers"; Name="Research Papers"; Icon="rbxassetid://11617421144"; Description="\"BioX Nekrosis Osmosis Research Paper\", by Eugene Baileys, Sven Førre, Joseph Mahma"; Sources={"Obtained in <b>Mission: Rats Recruitment</b>";};  });
	new(missionBase, {Id="highvaluepackage"; Name="High Value Package"; Icon="rbxassetid://14889119970"; Description="A package container of high value."; });
	new(missionBase, {Id="bloodsample"; Equippable=true; StorageIncludeList={"Inventory"}; Name="Blood Sample"; Icon="rbxassetid://15845539438"; Description="Test tubes containing blood samples."; });
	new(missionBase, {Id="samplereport"; Name="Sample Report"; StorageIncludeList={"Inventory"}; Icon="rbxassetid://15904123699"; Description="Sample's unintelligible result report."; });
	new(missionBase, {Id="blueprintpiece"; Name="Blueprint Piece"; StorageIncludeList={"Inventory"}; Icon="rbxassetid://16537824817"; Description="A piece of torn up blueprint."; });

	--==========================================================[[ USABLE ]]==========================================================--
	local customizationPack = {
		Type = super.Types.Usable;
		Tradable = super.Tradable.Tradable;
		Stackable = 10;
		OnAdd = function(data)
			local packData = data.UnlockPack;
			if packData then
				data.Name = (packData.Id.. " " ..packData.Type.." Pack");
				data.Description = "Unlocks the "..packData.Id.." "..packData.Type.." Pack.";
			end
		end;
	};
	
	new(customizationPack, {Id="colorlively";Icon="rbxassetid://4788857933"; Tags={"Color Pack"}; UnlockPack={Type="Color"; Id="Lively";};});
	new(customizationPack, {Id="colorarctic";Icon="rbxassetid://5065235473"; Tags={"Color Pack"}; UnlockPack={Type="Color"; Id="Arctic";};});
	new(customizationPack, {Id="colorhellsfire";Icon="rbxassetid://5180692180"; Tags={"Color Pack"}; UnlockPack={Type="Color"; Id="Hellsfire";};});
	new(customizationPack, {Id="colorturquoiseshades";Icon="rbxassetid://12163679259"; Tags={"Color Pack"}; UnlockPack={Type="Color"; Id="TurquoiseShades";};});
	new(customizationPack, {Id="colorsunset";Icon="rbxassetid://12163681091"; Tags={"Color Pack"}; UnlockPack={Type="Color"; Id="Sunset";};});
	
	new(customizationPack, {Id="skinstreetart";Icon="rbxassetid://4788857679"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="StreetArt";};});
	new(customizationPack, {Id="skinwireframe";Icon="rbxassetid://5065159425"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="Wireframe";};});
	new(customizationPack, {Id="skinwraps";Icon="rbxassetid://5065159623"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="Wraps";};});
	new(customizationPack, {Id="skinscaleplating";Icon="rbxassetid://5180744566"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="ScalePlating";};});
	new(customizationPack, {Id="skincarbonfiber";Icon="rbxassetid://5635664589"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="CarbonFiber";};});
	new(customizationPack, {Id="skinhexatiles";Icon="rbxassetid://6534859112"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="Hexatiles";};});
	new(customizationPack, {Id="skinoffline";Icon="rbxassetid://7866873305"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="Offline";};});
	new(customizationPack, {Id="skinice";Icon="rbxassetid://8532443079"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="Ice";};});
	new(customizationPack, {Id="skinwindtrails";Icon="rbxassetid://14250975612"; Tags={"Skin Pack"}; UnlockPack={Type="Skin"; Id="Windtrails";};});
	
	local usableBase = {
		Type = super.Types.Usable;
		Tradable = super.Tradable.Tradable;
		Stackable = 5;
	}
	new(usableBase, {Id="tomeoftweaks"; Name="Tome Of Tweaks"; Icon="rbxassetid://6122866034"; TradingTax=20; Tags={"Misc Usable"}; Description="10 Tips and tricks to tweak your weapon. Consuming this will grant you 10 tweak points.";});
	
	local unlockPapers = {
		Type = super.Types.Usable;
		Tradable = super.Tradable.Tradable;
		Stackable = false;
		OnAdd = function(data)
			local unlockData = data.UnlockData;
			if unlockData then
				data.Name = unlockData.Name.." Unlock Papers";
				data.Description = "Unlocks the ".. unlockData.Name .." ".. unlockData.Type;
			end
		end;
		TradingTax=100;
		Tags={"Unlock Papers"};
	};
	
	new(unlockPapers, {Id="survivorsoutpostunlockpapers"; UnlockData={Id="survivorsoutpost"; Name="Survivor's Outpost"; Type="Safehome"}; Icon="rbxassetid://13898510717";});
	new(unlockPapers, {Id="slaughterwoodsunlockpapers"; UnlockData={Id="slaughterwoods"; Name="Slaughter Woods"; Type="Safehome"}; Icon="rbxassetid://14992038475"; Tags={"Slaughterfest"};});
	new(unlockPapers, {Id="bunkerunlockpapers"; UnlockData={Id="bunker"; Name="Bunker"; Type="Safehome"}; Icon="rbxassetid://15565813997";});

	--==========================================================[[ CRAFTING COMPONENTS ]]==========================================================--
	local weaponCompBase = {
		Type = super.Types.Component;
		Tradable = super.Tradable.PremiumOnly;
		Stackable = 10;
		NonPremiumTax = 25;
		OnAdd = function(data)
			local craftFor = data.CraftFor;
			if craftFor then
				local itemLib = super:Find(craftFor);
				data.Name = itemLib.Name.." Parts";
				data.Description = "Parts used to create the "..itemLib.Name.." and mods.";
				data.Icon = itemLib.Icon;
			end
		end;
	}
	
	new(weaponCompBase, {Id="tacticalbowparts"; CraftFor="tacticalbow";});
	new(weaponCompBase, {Id="at4parts"; CraftFor="at4";});
	new(weaponCompBase, {Id="sr308parts"; CraftFor="sr308";});
	new(weaponCompBase, {Id="vectorxparts"; CraftFor="vectorx";});
	new(weaponCompBase, {Id="rusty48parts"; CraftFor="rusty48";});
	new(weaponCompBase, {Id="arelshiftcrossparts"; CraftFor="arelshiftcross"; Sources={"Obtained within <b>Abandoned Bunker</b>.";}; });
	new(weaponCompBase, {Id="deagleparts"; CraftFor="deagle"; Sources={"Obtained from <b>Board Missions</b>.";};});
	
	
	--=========================================================[[ AMMO ]]==========================================================--
	local ammoBase = {
		Type = super.Types.Ammo;
		Tradable = super.Tradable.Tradable;
	}
	new(ammoBase, {Id="lightammo"; Name="Light Ammo"; Icon="rbxassetid://7242498697"; Stackable=64; Description="Ammunition for pistols, smgs and light weapons.";});
	new(ammoBase, {Id="heavyammo"; Name="Heavy Ammo"; Icon="rbxassetid://7242509621"; Stackable=64; Description="Ammunition for rifles, lmgs and heavy weapons.";});
	new(ammoBase, {Id="shotgunammo"; Name="Shotgun Ammo"; Icon="rbxassetid://7242511854"; Stackable=32; Description="Ammunition for shotguns.";});
	new(ammoBase, {Id="sniperammo"; Name="Sniper Ammo"; Icon="rbxassetid://7242517756"; Stackable=16; Description="Ammunition for sniper rifles.";});
	
	
	--==========================================================[[ MAPS ]]==========================================================--
	local mapBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.Tradable;
		Tags = {"Map"};
		OnAdd = function(data)
			local gameModeData = data.GameMode;
			if gameModeData then
				data.Name = (gameModeData.HardPrefix and gameModeData.HardPrefix.." " or "")..gameModeData.Stage.." Map";
				data.Description = "A map that leads to "..gameModeData.Mode..": "..gameModeData.Stage.."."
			end
		end;
	};
	
	new(mapBase, {Id="klawsmap"; Name="Mr. Klaw's Workshop Map"; Icon="rbxassetid://8388817545"; GameMode={Mode="Coop"; Stage="Mr. Klaw's Workshop"}});
	new(mapBase, {Id="banditoutpostmap"; Name="Bandit Outpost Map"; Icon="rbxassetid://10037182552"; GameMode={Mode="Raid"; Stage="BanditOutpost"}; Sources={"Obtained from <b>Patrick after mission: Double Cross</b>";}; });
	new(mapBase, {Id="communitywaysidemap"; Name="Community Way Side Map"; Icon="rbxassetid://10976330229"; GameMode={Mode="Survival"; Stage="Community WaySide"}; Tradable=super.Tradable.Nontradable; Sources={"Obtained from <b>Gold Shop</b>";};});
	new(mapBase, {Id="communityfissionbaymap"; Name="Community Fission Bay Map"; Icon="rbxassetid://12407594475"; GameMode={Mode="Survival"; Stage="Community FissionBay"}; Tradable=super.Tradable.Nontradable; Sources={"Obtained from <b>Gold Shop</b>";};});
	new(mapBase, {Id="communityrooftopmap"; Name="Community Rooftops Map"; Icon="rbxassetid://14247432855"; GameMode={Mode="Survival"; Stage="Community Rooftops"}; Tradable=super.Tradable.Nontradable; Sources={"Obtained from <b>Gold Shop</b>";};});

	new(mapBase, {
		Id="abandonedbunkermap"; Name="Abandoned Bunker Map"; Icon="rbxassetid://16485911034"; GameMode={Mode="Raid"; Stage="Abandoned Bunker";};
		Tradable=super.Tradable.PremiumOnly;
		NonPremiumTax = 1000;
		OnInstantiate=function(storageItem, itemData)
			local itemValues = storageItem.Values;
			if itemValues.Seed then return end;
			
			itemValues.Seed = math.random(1, 9999);
		end;
	});
	
	--==========================================================[[ INSTRUMENT ]]==========================================================--
	local instrumentBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.Tradable;
		Tags = {"Instrument"};
	};

	new(instrumentBase, {Id="flute"; Name="Flute"; Icon="rbxassetid://6134172781"; Description="A playable flute instrument similar to Carlos's. Can play premade tunes or with keyboard/touch buttons.";});
	new(instrumentBase, {Id="guitar"; Name="Guitar"; Type=super.Types.Clothing; Icon="rbxassetid://6297059208"; Description="A playable guitar instrument. Can play premade tunes or with keyboard/touch buttons.";});
	new(instrumentBase, {Id="keytar"; Name="Keytar"; Tags={"Melee"}; Icon="rbxassetid://15338385507"; Description="A playable keyboard guitar while also being a melee weapon, also known as keytar instrument. Can play premade tunes or with keyboard/touch buttons.";});

	--==========================================================[[ ITEM UNLOCKABLES ]]==========================================================--
	local unlockableBase = {
		Type = super.Types.Usable;
		TypeIcon = "rbxassetid://12964393529";
		
		Tradable = super.Tradable.Tradable;
		Tags = {"Item Unlockable"};
		OnAdd = function(data)
			local unlockable = data.Unlockable;
			if unlockable then
				data.Name = unlockable.." Unlockable";
				data.Description = "Right click to unlocks "..unlockable.." for appearance customization.";
			end
		end;
	};
	
	new(unlockableBase, {Id="greytshirtcamo"; Icon="rbxassetid://6665474794"; Unlockable="Camo Tshirt";});
	new(unlockableBase, {Id="greytshirticyblue"; Icon="rbxassetid://8532617699"; Unlockable="Icy Blue Tshirt";});
	new(unlockableBase, {Id="greytshirticyred"; Icon="rbxassetid://8532659745"; Unlockable="Icy Red Tshirt";});
	
	new(unlockableBase, {Id="prisonshirtblue"; Icon="rbxassetid://6665649672"; Unlockable="Blue Prisoner's Shirt";});
	new(unlockableBase, {Id="prisonpantsblue"; Icon="rbxassetid://6665650148"; Unlockable="Blue Prisoner's Pants";});
	
	new(unlockableBase, {Id="leatherglovesred"; Icon="rbxassetid://16994275555"; Unlockable="Red Leather Gloves";});
	
	new(unlockableBase, {Id="dufflebagstreetart"; Icon="rbxassetid://8828337700"; Unlockable="Street Art Duffle Bag";});
	new(unlockableBase, {Id="dufflebagvintage"; Icon="rbxassetid://8828340427"; Unlockable="Vintage Duffle Bag";});
	new(unlockableBase, {Id="dufflebagarticscape"; Icon="rbxassetid://8828341507"; Unlockable="Artic Scape Duffle Bag";});
	new(unlockableBase, {Id="dufflebagfirstaidgreen"; Icon="rbxassetid://8828351670"; Unlockable="Green First Aid Duffle Bag";});

	new(unlockableBase, {Id="militarybootsdesert"; Icon="rbxassetid://17022737460"; Unlockable="Desert Military Boots";});
	new(unlockableBase, {Id="militarybootsforest"; Icon="rbxassetid://17022741672"; Unlockable="Forest Military Boots";});
	
	new(unlockableBase, {Id="plankarmormaple"; Icon="rbxassetid://6956453007"; Unlockable="Maple Plank Armor";});
	new(unlockableBase, {Id="plankarmorash"; Icon="rbxassetid://6956453176"; Unlockable="Ash Plank Armor";});

	new(unlockableBase, {Id="gasmaskwhite"; Icon="rbxassetid://7021688682"; Unlockable="White Gas Mask";});
	new(unlockableBase, {Id="gasmaskblue"; Icon="rbxassetid://7021573719"; Unlockable="Blue Gas Mask";});
	new(unlockableBase, {Id="gasmaskyellow"; Icon="rbxassetid://7021576890"; Unlockable="Yellow Gas Mask";});
	new(unlockableBase, {Id="gasmaskunionjack"; Icon="rbxassetid://7021608469"; Unlockable="Union Jack Gas Mask";});

	new(unlockableBase, {Id="scraparmorcopper"; Icon="rbxassetid://7021764853"; Unlockable="Copper Scrap Armor";});
	new(unlockableBase, {Id="scraparmorbiox"; Icon="rbxassetid://8366924869"; Unlockable="BioX Scrap Armor";});
	new(unlockableBase, {Id="scraparmormissingtextures"; Icon="rbxassetid://15241479939"; Unlockable="Missing Textures Scrap Armor";});

	new(unlockableBase, {Id="tophatgrey"; Icon="rbxassetid://7647922681"; Unlockable="Grey Top Hat"; Tags={"Slaughterfest";};});
	new(unlockableBase, {Id="tophatpurple"; Icon="rbxassetid://7647923912"; Unlockable="Purple Top Hat"; Tags={"Slaughterfest";};});
	new(unlockableBase, {Id="tophatred"; Icon="rbxassetid://7647948217"; Unlockable="Red Top Hat"; Tags={"Slaughterfest";};});
	new(unlockableBase, {Id="tophatgold"; Icon="rbxassetid://7647949358"; Unlockable="Gold Top Hat"; Tags={"Slaughterfest";};});
	
	new(unlockableBase, {Id="clownmaskus"; Icon="rbxassetid://8367268572"; Unlockable="Star Spangled Banner Clown Mask"; Tags={"Slaughterfest";};});
	new(unlockableBase, {Id="clownmaskmissjoyful"; Icon="rbxassetid://11269655306"; Unlockable="Miss Joyful Clown Mask"; Tags={"Slaughterfest";};});
	
	new(unlockableBase, {Id="disguisekitwhite"; Icon="rbxassetid://8379064603"; Unlockable="White Disguise Kit";});
	
	new(unlockableBase, {Id="zriceraskullinferno"; Icon="rbxassetid://8378956341"; Unlockable="Inferno Zricera Skull";});
	
	new(unlockableBase, {Id="divinggogglesyellow"; Icon="rbxassetid://10333085751"; Unlockable="Yellow Diving Goggles";});
	new(unlockableBase, {Id="divinggogglesred"; Icon="rbxassetid://15008018716"; Unlockable="Red Diving Goggles";});

	new(unlockableBase, {Id="maraudersmaskblue"; Icon="rbxassetid://11269657288"; Unlockable="Blue Marauder's Mask"; Tags={"Slaughterfest";};});

	new(unlockableBase, {Id="watchyellow"; Icon="rbxassetid://13022192307"; Unlockable="Yellow Watch";});
	
	new(unlockableBase, {Id="armwrapsrat"; Icon="rbxassetid://13021422822"; Unlockable="R.A.T. Arm Wraps";});
	new(unlockableBase, {Id="armwrapsmissingtextures"; Icon="rbxassetid://13207932009"; Unlockable="Missing Textures Arm Wraps";});
	
	new(unlockableBase, {Id="inflatablebuoyrat"; Icon="rbxassetid://13021723780"; Unlockable="R.A.T. Inflatable Buoy";});
	
	new(unlockableBase, {Id="brownbeltwhite"; Icon="rbxassetid://13021951870"; Unlockable="White Tactical Belt";});
	
	new(unlockableBase, {Id="vexglovesinferno"; Icon="rbxassetid://13974365409"; Unlockable="Inferno Vexeron Gloves";});
	
	new(unlockableBase, {Id="hardhatorigins"; Icon="rbxassetid://13974944299"; Unlockable="Origins Hard Hat";});
	new(unlockableBase, {Id="dufflebagorigins"; Icon="rbxassetid://13975619757"; Unlockable="Origins Duffle Bag";});
	
	new(unlockableBase, {Id="clothbagmasksuits"; Icon="rbxassetid://13985408173"; Unlockable="Suits Cloth Bag Mask";});

	new(unlockableBase, {Id="cultisthoodnekros"; Icon="rbxassetid://14970995011"; Unlockable="Nekros Cultist Hood";});

	new(unlockableBase, {Id="balaclavasuits"; Icon="rbxassetid://15032728733"; Unlockable="Suits Balaclava";});

	new(unlockableBase, {Id="tirearmorred"; Icon="rbxassetid://16791569263"; Unlockable="Red Tire Armor";});
	
	
	--==========================================================[[ ITEM UNLOCKABLES ]]==========================================================--
	local skinPermBase = {
		Type = super.Types.Usable;
		TypeIcon = "rbxassetid://12964393529";

		Tradable = super.Tradable.Tradable;
		Tags = {"Skin Perm"};
		OnAdd = function(data)
			local skinPerm = data.SkinPerm;
			if skinPerm then
				local itemLib = super:Find(data.ToolItemId);
				
				data.Name = skinPerm.." ".. itemLib.Name .." Skin-Perm";
				data.Description = "Right click to apply "..skinPerm.." skin permanent to a ".. itemLib.Name ..".";
			end
		end;
		TradingTax=10;
	};
	
	new(skinPermBase, {Id="arelshiftcrossantique"; Icon="rbxassetid://13768313905"; SkinPerm="Antique"; ToolItemId="arelshiftcross"; });
	new(skinPermBase, {Id="desolatorheavytoygun"; Icon="rbxassetid://13787997600"; SkinPerm="Toy Gun"; ToolItemId="desolatorheavy"; });
	new(skinPermBase, {Id="czevo3asiimov"; Icon="rbxassetid://13810605651"; SkinPerm="Asiimov"; ToolItemId="czevo3"; });
	new(skinPermBase, {Id="rusty48blaze"; Icon="rbxassetid://13822423304"; SkinPerm="Blaze"; ToolItemId="rusty48"; });
	new(skinPermBase, {Id="sr308slaughterwoods"; Icon="rbxassetid://16570530303"; SkinPerm="Slaughter Woods"; ToolItemId="sr308"; });
	new(skinPermBase, {Id="vectorxpossession"; Icon="rbxassetid://15007719867"; SkinPerm="Possession"; ToolItemId="vectorx"; });
	new(skinPermBase, {Id="sr308horde"; Icon="rbxassetid://16570534063"; SkinPerm="Horde"; ToolItemId="sr308"; });

	
	--==========================================================[[ SUMMONS ]]==========================================================--
	local summonsBase = {
		Type = super.Types.Tool;
		Tradable = super.Tradable.Tradable;
		Tags={"Summon"};
	};
	new(summonsBase, {Id="zricerahorn"; Name="Zricera's Horn"; Icon="rbxassetid://6823417180"; Tags={"Summons"}; Description="Equipping this while entering Zricera arena to activate Hard Mode Zricera.\n\nAfter Zricera sees you holding this, it gets really riled up.";});
	new(summonsBase, {Id="vexling"; Name="Vexling"; Icon="rbxassetid://7109208351"; Tags={"Summons"}; Description="Equipping this while entering Vexeron arena to activate Hard Mode Vexeron.\n\nVexeron is not going to let you harm one of it's own.";});
	new(summonsBase, {Id="nekronparticulatecache"; Name="Nekron Particulate Cache"; Icon="rbxassetid://11154552175"; Tags={"Summons"}; Description="Equipping this while entering Bandit Helicopter arena to activate Hard Mode Bandit Helicopter.\n\nLooks like the Bandits really want some of this.";});
	
	--==========================================================[[ KEY ]]==========================================================--
	local keyBase = {
		Type = super.Types.Key;
		Tradable = super.Tradable.Tradable;
	};
	new(keyBase, {Id="cultistkey1"; Name="Suspicious Key"; Icon="rbxassetid://8662481907"; Description="Suspicious looking key.. Hmmm, what does it unlock?"; Sources={"Obtained from <b>The Wandering Trader</b>";};});
	new(keyBase, {Id="t1key"; Name="Tier 1 Key"; Icon="rbxassetid://1537254647"; Tags={"Unobtainable";}; Description="The Tier 1 Key.";});
	new(keyBase, {Id="t2key"; Name="Tier 2 Key"; Icon="rbxassetid://1541091147"; Tags={"Unobtainable";}; Description="The Tier 2 Key.";});
	
	new(keyBase, {Id="abgreenkey"; Name="Abandoned Bunker: Green Key"; Icon="rbxassetid://13475352377"; Tags={"Raid";}; BaseValues={Uses=3;}; Description="Abandoned bunker green room key.";});
	
	--==========================================================[[ Special ]]==========================================================--
	
	-- April Fools
	new(toolBase, {Id="whoopeechusion"; Name="Whoopee Cushion"; Icon="rbxassetid://4788857044"; Tags={"April Fools"}; Description="WHO FARTED!?";});
	new(toolBase, {Id="rubberchicken"; Name="Rubber Chicken"; Icon="rbxassetid://12924298979"; Tags={"April Fools"}; Description="Annoying chicken";});

	-- Easter 2020
	new(crateBase, {Id="easteregg"; Name="Easter Egg 2020"; Icon="rbxassetid://4836173098"; Tags={"Easter"}; TradingTax=0; Stackable=20; Description="Happy Easter, open it and see what you get!";});
	new(toolBase, {Id="bunnyplush"; Name="Bunny Plush"; Icon="rbxassetid://4843264963"; Tags={"Easter"}; Description="*squuuuuish and cuddles*";});
	new(customizationPack, {Id="coloreaster"; Name="Easter Colors Pack"; Icon="rbxassetid://4836170912"; Tags={"Color Pack"; "Easter"}; UnlockPack={Type="Color"; Id="EasterColors";};});
	new(customizationPack, {Id="skineaster"; Name="Easter Skins Pack"; Icon="rbxassetid://4836171086"; Tags={"Skin Pack"; "Easter"}; UnlockPack={Type="Skin"; Id="EasterSkins";};});
	
	-- Easter 2021
	new(crateBase, {Id="easteregg2021"; Name="Easter Egg 2021"; Icon="rbxassetid://4836173098"; Tags={"Easter"}; TradingTax=0; Stackable=20; Description="Happy Easter, open it and see what you get!";});
	new(toolBase, {Id="chippyplush"; Name="Chippy Plush"; Icon="rbxassetid://6648333467"; Tags={"Easter"}; Description="Chips and squeaks but with a sinister tone.";});
	
	new(unlockableBase, {Id="dufflebageaster1"; Icon="rbxassetid://8828333941"; Tags={"Easter"}; Unlockable="Easter Colors Duffle Bag";});
	new(unlockableBase, {Id="dufflebageaster2"; Icon="rbxassetid://8828335887"; Tags={"Easter"}; Unlockable="Easter Stripes Duffle Bag";});
	new(unlockableBase, {Id="bunnymanheadbenefactor"; Icon="rbxassetid://6665870074"; Tags={"Easter"}; Unlockable="The Benefactor Bunny Man's Head"; Sources={"Obtained from <b>The Bunny Man in Mission: Easter Butchery 2</b>";};});
	
	-- Summer 2020
	new(toolBase, {Id="beachball"; Name="Beachball"; Icon="rbxassetid://5441513828"; Tags={"Summer"}; Description="Does 100 damage on hit.";});
	
	-- Halloween 2020
	new(toolBase, {Id="voodoodoll"; Name="Voodoo Doll"; Icon="rbxassetid://5816461591"; Tags={"Slaughterfest";}; Description="Creepy little voodoo doll that mimic players or characters.";});
	
	
	-- Halloween 2021
	new(resourceBase, {Id="halloweencandy"; Name="Halloween Candy"; Icon="rbxassetid://7558610870"; Stackable=500; Tags={"Slaughterfest";}; Description="A pile of haunted candies.."; Sources={"Obtained from <b>Slaughterfest</b> event";} });
	new(customizationPack, {Id="skinhalloweenpixelart"; Name="Halloween Pixel Art Pack"; Icon="rbxassetid://7605179907"; Tags={"Skin Pack"; "Slaughterfest";}; UnlockPack={Type="Skin"; Id="HalloweenPixelArt";};});
	
	
	-- Halloween 2023
	new(unlockableBase, {Id="nekrostrenchhauntedpumpkin"; Icon="rbxassetid://14971117747"; Unlockable="Haunted Pumpkin Nekros Trench Coat";});
	new(unlockableBase, {Id="skullmaskgold"; Icon="rbxassetid://15007587410"; Unlockable="Gold Skull Mask";});
	new(customizationPack, {Id="skincutebutscary"; Name="Cute But Scary Pack"; Icon="rbxassetid://15016488348"; Tags={"Skin Pack"; "Slaughterfest";}; UnlockPack={Type="Skin"; Id="CuteButScary";};});
	new(unlockableBase, {Id="clothbagmaskcbsskulls"; Icon="rbxassetid://15016732739"; Unlockable="Cute But Scary Skulls Cloth Bag Mask";});
	new(unlockableBase, {Id="armwrapscbsghosts"; Icon="rbxassetid://15016755235"; Unlockable="Cute But Scary Ghosts Arm Wraps";});
	new(unlockableBase, {Id="maraudersmaskcbspumpkins"; Icon="rbxassetid://15016821671"; Unlockable="Cute But Scary Pumpkins Marauder's Mask"; Tags={"Slaughterfest";};});
	
	-- Christmas 2019
	
	new(foodBase, {Id="gingerbreadman"; Name="Gingerbread Man"; Icon="rbxassetid://4533980328"; Tags={"Christmas"; "Frostivus"}; Description="Puts you in a Christmas Spirit.";});
	new(foodBase, {Id="eggnog"; Name="Eggnog"; Icon="rbxassetid://4533980544"; Tags={"Christmas"; "Frostivus"}; Description="Puts you in a Christmas Spirit.";});

	new(crateBase, {Id="xmaspresent"; Name="Christmas Present 2019"; Icon="rbxassetid://4527344935"; Tags={"Christmas"; "Frostivus"}; TradingTax=0; Description="Merry Christmas, open it and see what you get!";});
	
	-- Christmas 2020
	new(crateBase, {Id="xmaspresent2020"; Name="Christmas Present 2020"; Icon="rbxassetid://6122546020"; Tags={"Christmas"; "Frostivus"}; TradingTax=0; Description="Merry Christmas, open it and see what you get!";});

	-- Christmas 2021
	new(crateBase, {Id="xmaspresent2021"; Name="Christmas Present 2021"; Icon="rbxassetid://8402074470"; Tags={"Christmas"; "Frostivus"}; TradingTax=0; Description="Merry Christmas, open it and see what you get!";});
	new(unlockableBase, {Id="disguisekitxmas"; Icon="rbxassetid://8379062918"; Tags={"Christmas"; "Frostivus"}; Unlockable="Christmas Disguise Kit";});
	new(unlockableBase, {Id="leatherglovesxmasred"; Icon="rbxassetid://17032671301"; Tags={"Christmas"; "Frostivus"}; Unlockable="Christmas Red Leather Gloves";});
	new(unlockableBase, {Id="leatherglovesxmasgreen"; Icon="rbxassetid://17032671567"; Tags={"Christmas"; "Frostivus"}; Unlockable="Christmas Green Leather Gloves";});
	new(unlockableBase, {Id="leatherglovesxmasrgb"; Icon="rbxassetid://17032671890"; Tags={"Christmas"; "Frostivus"}; Unlockable="Christmas Rainbow Leather Gloves";});
	new(unlockableBase, {Id="gasmaskxmas"; Icon="rbxassetid://8402308646"; Tags={"Christmas"; "Frostivus"}; Unlockable="Christmas Gas Mask";});

	-- Christmas 2022
	new(crateBase, {Id="xmaspresent2022"; Name="Christmas Present 2022"; Icon="rbxassetid://11787305747"; Tags={"Christmas"; "Frostivus"}; TradingTax=0; Description="Merry Christmas, open it and see what you get!";});
	new(unlockableBase, {Id="santahatwinterfest"; Icon="rbxassetid://11812491624"; Unlockable="Frostivus Santa Hat"; Tags={"Christmas"; "Frostivus";};});
	new(unlockableBase, {Id="mercskneepadswinterfest"; Icon="rbxassetid://11812666419"; Unlockable="Frostivus Merc's Knee Pads"; Tags={"Christmas"; "Frostivus";};});
	new(unlockableBase, {Id="xmassweatergreen"; Icon="rbxassetid://11863066782"; Unlockable="Xmas Sweater Green & Red"; Tags={"Christmas"; "Frostivus";};});
	new(unlockableBase, {Id="xmassweateryellow"; Icon="rbxassetid://11863078091"; Unlockable="Xmas Sweater Yellow & Blue"; Tags={"Christmas"; "Frostivus";};});
	
	-- Christmas 2023
	new(crateBase, {Id="xmaspresent2023"; Name="Christmas Present 2023"; Icon="rbxassetid://15565768345"; Tags={"Christmas"; "Frostivus"}; TradingTax=0; Description="Merry Christmas 2023!\n\n<i>\"I hope you're having a great holiday, I know RotD is lacking updates this winter and because of having to deal with a lot of irl things, there won't be a full winterfest update.\n\nI hope you'll enjoy this end of the year gift of a random cosmetic!\n~Khronos\"</i>\n\nOpen it and see what you get!";});

	-- Easter 2023
	new(crateBase, {Id="easteregg2023"; Name="Easter Egg 2023"; Icon="rbxassetid://12961679377"; Tags={"Easter"}; TradingTax=0; Description="Happy Easter, open it and see what you get!";});
	new(customizationPack, {Id="skineaster2023"; Name="Easter Skins 2023 Pack"; Icon="rbxassetid://12963885465"; Tags={"Skin Pack"; "Easter"}; UnlockPack={Type="Skin"; Id="EasterSkins2023";};});
	new(unlockableBase, {Id="hardhatcherryblossom"; Icon="rbxassetid://12963903837"; Tags={"Easter"}; Unlockable="Cherry Blossom Hard Hat";});
	new(unlockableBase, {Id="highvisjacketfallenleaves"; Icon="rbxassetid://12963945448"; Tags={"Easter"}; Unlockable="Fallen Leaves High Visibility Jacket";});
	new(unlockableBase, {Id="scraparmorcherryblossom"; Icon="rbxassetid://12963959744"; Tags={"Easter"}; Unlockable="Cherry Blossom Scrap Armor";});
	
	
	--==========================================================[[ META ]]==========================================================--
	local metaBase = {
		Type = super.Types.None;
		Tradable = super.Tradable.Nontradable;
		Stackable = false;
	};
	
	new(metaBase, {Id="gold"; Name="Gold"; Icon="rbxassetid://4734610249"; Description="Gold, the currency of protagonists."; Tags={"Unobtainable"};});
	new(crateBase, {Id="unknowncrate"; Name="Unknown Crate"; Icon="rbxassetid://10980446265"; Description="Recycler's unknown crate."; Type=super.Types.None; Tags={"Unobtainable"};});
	
	
	--==========================================================[[ DEV ]]==========================================================--
	new(toolBase, {Id="placeitem"; Name="Place Item"; Icon="rbxassetid://8894342011"; Tags={"Unobtainable"; "Dev"}; Description="Used for placing a pick up item.";});
	
	
	for _, obj in pairs(script:GetChildren()) do
		if not obj:IsA("ModuleScript") then continue end;
		obj.Parent = super.Script;
	end
end

return ItemsLibrary;