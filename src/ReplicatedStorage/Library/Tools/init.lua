local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);

--==
local metaTools = {};
metaTools.__index = metaTools;

metaTools.Modules = {};

local Tools = {};

function metaTools:LoadToolLib(itemId)
	if itemId and Tools.Modules[itemId] == nil then
		Tools.Modules[itemId] = Tools[itemId].NewToolLib();
	end
	return Tools.Modules[itemId];
end

function AddTool(data)
	local module = script:WaitForChild(data.ItemId);
	
	local packet = {
		ItemId=data.ItemId;
		Type=data.Type;
		Animations=data.Animations;
		Audio=data.Audio;
		Welds=data.Welds or {
			ToolGrip=(data.Generic or data.ItemId);
		};
		Module=module;
		WoundEquip = data.Type == "HealTool";
	};
	Tools[data.ItemId] = packet;
	
	packet.NewToolLib = function(handler)
		return require(packet.Module)(handler);
	end;
	
	local itemModel = module:FindFirstChild("itemModel");
	if itemModel then
		itemModel.Name = data.ItemId;
		itemModel.Parent = game.ReplicatedStorage.Prefabs.Items;
	end
	
	if data.Audio then
		for soundType, audioProperties in pairs(data.Audio) do
			local audioId = audioProperties.Id;
			local soundFile = game.ReplicatedStorage.Library.Audio:FindFirstChild(tostring(audioId));
			if soundFile then
				modAudio.Library[audioId] = soundFile;
				
			else
				if modAudio.Library[audioId] == nil then
					soundFile = Instance.new("Sound", script);
					soundFile.Name = audioId;
					soundFile.SoundId = "rbxassetid://"..audioId;
					soundFile.PlaybackSpeed = audioProperties.Pitch;
					soundFile.EmitterSize = 5;
					if soundType == "PrimaryFire" then
						soundFile.RollOffMaxDistance = 128;
					elseif soundType == "Empty" then
						soundFile.RollOffMaxDistance = 16;
					else
						soundFile.RollOffMaxDistance = 32;
					end
					soundFile.SoundGroup = game.SoundService.WeaponEffects;
					soundFile.Volume = audioProperties.Volume ~= nil and audioProperties.Volume or 0.5;

					if modAudio.ModdedSelf then
						modAudio.ModdedSelf.OnWeaponAudioLoad(soundType, audioProperties, soundFile);
					end
					modAudio.Library[audioId] = soundFile;
				end
			end
		end
	end
end

--AddTool{
--	ItemId="medkit";
--	Type="HealTool";
--	Animations={
--		Core={Id=3296519824;};
--		Use={Id=3296558467;};
--		UseOthers={Id=16167636769;};
--	};
--	Audio={
--	};
--}

--AddTool{
--	ItemId="largemedkit";
--	Type="HealTool";
--	Animations={
--		Core={Id=3296519824;};
--		Use={Id=3296558467;};
--		UseOthers={Id=16167636769;};
--	};
--	Audio={
--	};
--}

-- AddTool{
-- 	ItemId="advmedkit";
-- 	Type="HealTool";
-- 	Animations={
-- 		Core={Id=5011163984;};
-- 		Use={Id=5011194350;};
-- 		UseOthers={Id=5011194350;};
-- 	};
-- 	Audio={
-- 	};
-- }

--== Food
--AddTool{
--	ItemId="cannedbeans";
--	Type="FoodTool";
--	Animations={
--		Core={Id=3296519824;};
--		Use={Id=4466630712;};
--	};
--	Audio={
--	};
--}

--AddTool{
--	ItemId="energydrink";
--	Type="FoodTool";
--	Animations={
--		Core={Id=5096936519;};
--		Use={Id=8862317214;};
--	};
--	Audio={
--	};
--}

-- AddTool{
-- 	ItemId="gingerbreadman";
-- 	Type="FoodTool";
-- 	Animations={
-- 		Core={Id=3296519824;};
-- 		Use={Id=4534092581;};
-- 	};
-- 	Audio={
-- 	};
-- }

-- AddTool{
-- 	ItemId="eggnog";
-- 	Type="FoodTool";
-- 	Animations={
-- 		Core={Id=3296519824;};
-- 		Use={Id=4534077346;};
-- 	};
-- 	Audio={
-- 	};
-- }

-- AddTool{
-- 	ItemId="chocobar";
-- 	Type="FoodTool";
-- 	Animations={
-- 		Core={Id=3296519824;};
-- 		Use={Id=5795297695;};
-- 	};
-- 	Audio={
-- 	};
-- }

-- AddTool{
-- 	ItemId="gumball";
-- 	Type="FoodTool";
-- 	Animations={
-- 		Core={Id=3296519824;};
-- 		Use={Id=6122752703;};
-- 	};
-- 	Audio={
-- 	};
-- }

-- AddTool{
-- 	ItemId="cannedfish";
-- 	Type="FoodTool";
-- 	Animations={
-- 		Core={Id=6961217852;};
-- 		Use={Id=6961218719;};
-- 	};
-- 	Audio={
-- 	};
-- }

AddTool{
	ItemId="annihilationsoda";
	Type="FoodTool";
	Animations={
		Core={Id=5096936519;};
		Use={Id=10370762593;}; --5096948650
	};
	Audio={
	};
}

AddTool{
	ItemId="ziphoningserum";
	Type="FoodTool";
	Animations={
		Core={Id=5096936519;};
		Use={Id=10370762593;};
	};
	Audio={
	};
}

--== Melee
--AddTool{
--	ItemId="survivalknife";
--	Type="Melee";
--	Animations={
--		Core={Id=3659818803;};
--		Load={Id=7181051159;};
--		PrimaryAttack={Id=3660094559};
--		PrimaryAttack2={Id=5044881440};
--		Inspect={Id=3660032617;};
--		Unequip={Id=7181055107};
--	};
--	Audio={
--		Load={Id=2304904662; Pitch=1; Volume=0.4;};
--		PrimaryHit={Id=9141019032; Pitch=1; Volume=1;};
--		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
--	};
--}

--AddTool{
--	ItemId="machete";
--	Type="Melee";
--	Animations={
--		Core={Id=4469912045;};
--		Load={Id=7181066235;};
--		PrimaryAttack={Id=4469937191};
--		PrimaryAttack2={Id=5044884973};
--		HeavyAttack={Id=4473902088};
--		Inspect={Id=3660032617;};
--		Unequip={Id=7181070871};
--	};
--	Audio={
--		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
--		PrimaryHit={Id=9141019032; Pitch=0.6; Volume=1;};
--		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
--		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
--	};
--}

--AddTool{
--	ItemId="spikedbat";
--	Type="Melee";
--	Animations={
--		Core={Id=4602819736;};
--		PrimaryAttack={Id=4602852728};
--		Inspect={Id=4603104523;};
--	};
--	Audio={
--		Load={Id=4601593953; Pitch=1; Volume=2;};
--		PrimaryHit={Id=4602930505; Pitch=1; Volume=2;};
--		PrimarySwing={Id=4601593953; Pitch=1; Volume=2;};
--	};
--}

--AddTool{
--	ItemId="crowbar";
--	Type="Melee";
--	Animations={
--		Core={Id=4843574016;};
--		PrimaryAttack={Id=4843606923};
--		Inspect={Id=4847803007;};
--	};
--	Audio={
--		Load={Id=4601593953; Pitch=1; Volume=2;};
--		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
--		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
--	};
--}

--AddTool{
--	ItemId="sledgehammer";
--	Type="Melee";
--	Animations={
--		Core={Id=5185258181;};
--		PrimaryAttack={Id=5185437208};
--		ComboAttack3={Id=5185285686};
--		Inspect={Id=5185272920;};
--		Unequip={Id=7181070871};
--	};
--	Audio={
--		Load={Id=4601593953; Pitch=1; Volume=2;};
--		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
--		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
--	};
--}

--AddTool{
--	ItemId="pickaxe";
--	Type="Melee";
--	Animations={
--		Core={Id=5185289436;};
--		PrimaryAttack={Id=5185294640};
--		Inspect={Id=5185292342;};
		
--		Charge={Id=5653774465;};
--		Throw={Id=12645593609};
--	};
--	Audio={
--		Throw={Id=5083063763; Pitch=1; Volume=1;};
		
--		Load={Id=4601593953; Pitch=1; Volume=2;};
--		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
--		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
--	};
--}

--AddTool{
--	ItemId="broomspear";
--	Type="Melee";
--	Animations={
--		Core={Id=5653496321;}; --   5120333177
--		PrimaryAttack={Id=5653533735};
--		Inspect={Id=4603104523;};
		
--		Charge={Id=5120543664;};
--		Throw={Id=5120553382};
--	};
--	Audio={
--		--Charge={Id=5088355920; Pitch=1; Volume=1;};
--		--ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
--		Throw={Id=5083063763; Pitch=1; Volume=1;};
		
--		Load={Id=4601593953; Pitch=1; Volume=2;};
--		PrimaryHit={Id=1884075293; Pitch=1; Volume=2;};
--		PrimarySwing={Id=5083063763; Pitch=1.4; Volume=2;};
--	};
--}

--AddTool{
--	ItemId="jacksscythe";
--	Type="Melee";
--	Animations={
--		Core={Id=5701493481;};
--		PrimaryAttack={Id=5701595766};
--		PrimaryAttack2={Id=5703121217};
--		HeavyAttack={Id=5729677503};
--		Inspect={Id=5701586555;};
--	};
--	Audio={
--		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
--		PrimaryHit={Id=9141019032; Pitch=0.6; Volume=1;};
--		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
--		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
--	};
--}

--AddTool{
--	ItemId="naughtycane";
--	Type="Melee";
--	Animations={
--		Core={Id=4602819736;};
--		PrimaryAttack={Id=4602852728};
--		Inspect={Id=4603104523;};
--	};
--	Audio={
--		Load={Id=4601593953; Pitch=1; Volume=2;};
--		PrimaryHit={Id=4602930505; Pitch=1; Volume=2;};
--		PrimarySwing={Id=4601593953; Pitch=1; Volume=2;};
--	};
--}

--AddTool{
--	ItemId="chainsaw";
--	Type="Melee";
--	Animations={
--		Core={Id=7319667560;};
--		Load={Id=7320739268;};
--		PrimaryAttack={Id=7320729671};
--		HeavyAttack={Id=5729677503};
--		Inspect={Id=7334426224;};
--	};
--	Audio={
--		Core={Id=7326200210; Pitch=1; Volume=0.4;};
--		Load={Id=7326258540; Pitch=1; Volume=1;};
--		PrimaryHit={Id=1869594237; Pitch=1; Volume=1;};
--		PrimarySwing={Id=7326259044; Pitch=1; Volume=1;};
--	};
--}

--AddTool{
--	ItemId="shovel";
--	Type="Melee";
--	Animations={
--		Core={Id=4469912045;};
--		Load={Id=7181066235;};
--		PrimaryAttack={Id=4469937191};
--		PrimaryAttack2={Id=5044884973};
--		HeavyAttack={Id=4473902088};
--		Inspect={Id=3660032617;};
--		Unequip={Id=7181070871};
--	};
--	Audio={
--		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
--		PrimaryHit={Id=8814671013; Pitch=1; Volume=1;};
--		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
--	};
--}


--== Throwabels
AddTool{
	ItemId="mk2grenade";
	Type="Throwable";
	Animations={
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		Charge={Id=5082994235; Pitch=1; Volume=1;};
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
}

AddTool{
	ItemId="molotov";
	Type="Throwable";
	Animations={
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		Charge={Id=5088355920; Pitch=1; Volume=1;};
		ProjectileBounce={Id=5088356214; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
}

AddTool{
	ItemId="stickygrenade";
	Type="Throwable";
	Animations={
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		Charge={Id=5082994235; Pitch=1; Volume=1;};
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
}

AddTool{
	ItemId="beachball";
	Type="Throwable";
	Animations={
		Core={Id=5441598768;};
		Charge={Id=5441607436;};
		Throw={Id=5075441987};
	};
	Audio={
		--Charge={Id=5088355920; Pitch=1; Volume=1;};
		--ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=1863039220; Pitch=1; Volume=1;};
	};
}

AddTool{
	ItemId="fireworks";
	Type="Throwable";
	Animations={
		Core={Id=6235891614;};
		Throw={Id=6235897108};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
}

AddTool{
	ItemId="matchbox";
	Type="Throwable";
	Animations={
		Core={Id=7326904292;};
		Load={Id=7326901815;};
		Throw={Id=6235897108};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
	Welds={
		LeftToolGrip="matchbox";
	};
}

AddTool{
	ItemId="explosives";
	Type="Throwable";
	Animations={
		Core={Id=7326823684;};
		Load={Id=7326830371;};
		Reload={Id=7326830371;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		--Charge={Id=6269203967; Pitch=1; Volume=1;};
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
}

AddTool{
	ItemId="snowballs";
	Type="Throwable";
	Animations={
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		--Charge={Id=5082994235; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
}

--== Structures
AddTool{
	ItemId="metalbarricade";
	Type="StructureTool";
	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={
	};
}

AddTool{
	ItemId="scarecrow";
	Type="StructureTool";
	Animations={
		Core={Id=4493584242;};
		Placing={Id=4493588865};
	};
	Audio={
	};
}

AddTool{
	ItemId="snowman";
	Type="StructureTool";
	Animations={
		Core={Id=4493584242;};
		Placing={Id=4493588865};
	};
	Audio={
	};
}

AddTool{
	ItemId="gastankied";
	Type="StructureTool";
	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={
	};
}

AddTool{
	ItemId="barbedwooden";
	Type="StructureTool";
	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={
	};
}

AddTool{
	ItemId="barbedmetal";
	Type="StructureTool";
	Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
	};
	Audio={
	};
}

--== Containers
--AddTool{
--	ItemId="officecrate";
--	Generic="crate";
--	Type="StructureTool";
--	Animations={
--		Core={Id=4696835207;};
--		Placing={Id=4696837086};
--	};
--	Audio={
--	};
--}

--AddTool{
--	ItemId="sectorfcrate";
--	Generic="crate";
--	Type="StructureTool";
--	Animations={
--		Core={Id=4696835207;};
--		Placing={Id=4696837086};
--	};
--	Audio={
--	};
--}

--AddTool{
--	ItemId="ucsectorfcrate";
--	Generic="crate";
--	Type="StructureTool";
--	Animations={
--		Core={Id=4696835207;};
--		Placing={Id=4696837086};
--	};
--	Audio={
--	};
--}

AddTool{
	ItemId="tombschest";
	Generic="tombschest";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="prisoncrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="nprisoncrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="xmaspresent";
	Type="StructureTool";
	Animations={
		Core={Id=4527394855;};
		Placing={Id=4527422890};
	};
	Audio={
	};
}

AddTool{
	ItemId="xmaspresent2020";
	Type="StructureTool";
	Animations={
		Core={Id=4527394855;};
		Placing={Id=4527422890};
	};
	Audio={
	};
}

AddTool{
	ItemId="xmaspresent2021";
	Type="StructureTool";
	Animations={
		Core={Id=4527394855;};
		Placing={Id=4527422890};
	};
	Audio={
	};
}

AddTool{
	ItemId="xmaspresent2022";
	Type="StructureTool";
	Animations={
		Core={Id=11813098572;};
		Placing={Id=11813106523};
	};
	Audio={
	};
}

AddTool{
	ItemId="xmaspresent2023";
	Type="StructureTool";
	Animations={
		Core={Id=11813098572;};
		Placing={Id=11813106523};
	};
	Audio={
	};
}

AddTool{
	ItemId="banditcrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="hbanditcrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="easteregg";
	Type="StructureTool";
	Animations={
		Core={Id=4527394855;};
		Placing={Id=4527422890};
	};
	Audio={
	};
}

AddTool{
	ItemId="easteregg2021";
	Type="StructureTool";
	Animations={
		Core={Id=4527394855;};
		Placing={Id=4527422890};
	};
	Audio={
	};
}

AddTool{
	ItemId="railwayscrate";
	Generic="railwayscrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="sectordcrate";
	Generic="sectordcrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="ucsectordcrate";
	Generic="ucsectordcrate";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="sunkenchest";
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
	Audio={
	};
}

AddTool{
	ItemId="communitycrate";
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={
	};
}

AddTool{
	ItemId="communitycrate2";
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={
	};
}

AddTool{
	ItemId="metalpackage";
	Generic="resourcecrate";
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={
	};
}

AddTool{
	ItemId="clothpackage";
	Generic="resourcecrate";
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={
	};
}

AddTool{
	ItemId="glasspackage";
	Generic="resourcecrate";
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={
	};
}

AddTool{
	ItemId="woodpackage";
	Generic="resourcecrate";
	Type="StructureTool";
	Animations={
		Core={Id=10964629394;};
		Placing={Id=10964648124};
	};
	Audio={
	};
}

--== Roleplay Tools;

AddTool{
	ItemId="lantern";
	Type="RoleplayTool";
	Animations={
		Core={Id=4705965700;};
		Use={Id=13631843548};--4705968788
	};
	Audio={
	};
}

AddTool{
	ItemId="walkietalkie";
	Type="RoleplayTool";
	Animations={
		Core={Id=4706146901;};
		Use={Id=4706147696};
	};
	Audio={
	};
}

AddTool{
	ItemId="portablestove";
	Type="RoleplayTool";
	Animations={
		Core={Id=4706359805;};
	};
	Audio={
	};
}

AddTool{
	ItemId="spotlight";
	Type="RoleplayTool";
	Animations={
		Core={Id=4706387367;};
		SwimCore={Id=14120032381;};
	};
	Audio={
	};
}

AddTool{
	ItemId="musicbox";
	Type="RoleplayTool";
	Animations={
		Core={Id=4706449989;};
		Use={Id=4706454123};
	};
	Audio={
	};
}

AddTool{
	ItemId="binoculars";
	Type="RoleplayTool";
	Animations={
		Core={Id=4731631834;};
		Use={Id=4731676746};
	};
	Audio={
	};
}

AddTool{
	ItemId="bunnyplush";
	Type="RoleplayTool";
	Animations={
		Core={Id=4843250039;};
		Use={Id=4706454123};
	};
	Audio={
	};
}

AddTool{
	ItemId="voodoodoll";
	Type="RoleplayTool";
	Animations={
		Core={Id=4843250039;};
		Use={Id=4706454123};
	};
	Audio={
	};
}

AddTool{
	ItemId="boombox";
	Type="RoleplayTool";
	Animations={
		Core={Id=4997124843;};
		Use={Id=4997138529};
	};
	Audio={
	};
}

AddTool{
	ItemId="lasso";
	Type="RoleplayTool";
	Animations={
		Core={Id=4988030453;};
		Use={Id=4988004803};
	};
	Audio={
	};
}

AddTool{
	ItemId="wateringcan";
	Type="RoleplayTool";
	Animations={
		Core={Id=5191611634;};
		Use={Id=5191647600};
	};
	Audio={
	};
}


AddTool{
	ItemId="jerrycan";
	Type="RoleplayTool";
	Animations={
		Core={Id=5888506042;};
		Use={Id=5966533550};--5888499091
	};
	Audio={
	};
}

AddTool{
	ItemId="gps";
	Type="RoleplayTool";
	Animations={
		Core={Id=5932487712;};
		Use={Id=5932203028};
	};
	Audio={
	};
}


AddTool{
	ItemId="guitar";
	Type="RoleplayTool";
	Animations={
		Core={Id=6297114327;};
		Use={Id=6297131484};
	};
	Audio={
	};
}

AddTool{
	ItemId="chippyplush";
	Type="RoleplayTool";
	Animations={
		Core={Id=4843250039;};
		Use={Id=4706454123};
	};
	Audio={
	};
}

AddTool{
	ItemId="zricerahorn";
	Type="RoleplayTool";
	Animations={
		Core={Id=6823445409;};
		Use={Id=6823445409};
	};
	Audio={
	};
}

AddTool{
	ItemId="vexling";
	Type="RoleplayTool";
	Animations={
		Core={Id=6823445409;};
		Use={Id=6823445409};
	};
	Audio={
	};
}

AddTool{
	ItemId="nekronparticulatecache";
	Type="RoleplayTool";
	Animations={
		Core={Id=5011163984;};
		--Use={Id=5011194350;};
	};
	Audio={
	};
}

AddTool{
	ItemId="entityleash";
	Type="RoleplayTool";
	Animations={
		Core={Id=6984018985;};
		--Use={Id=5932203028};
	};
	Audio={
	};
}

AddTool{
	ItemId="ladder";
	Type="RoleplayTool";
	Animations={
		Core={Id=8423098901;};
		Use={Id=8423148305};
	};
	Audio={
	};
}


AddTool{
	ItemId="placeitem";
	Type="PlacePickup";
	Animations={
		Core={Id=8388875136;};
		Use={Id=8388988860};
	};
	Audio={
	};
}


AddTool{
	ItemId="poster";
	Type="RoleplayTool";
	Animations={
		Core={Id=8388875136;};
		Use={Id=8388988860};
	};
	Audio={
	};
}

AddTool{
	ItemId="envelope";
	Type="RoleplayTool";
	Animations={
		Core={Id=3296519824;};
		Use={Id=6418497950;};
	};
	Audio={
	};
}

AddTool{
	ItemId="fotlcardgame";
	Type="RoleplayTool";
	Animations={
		Core={Id=10862726322;};
		--Use={Id=10862726322};
	};
	Audio={
	};
}

--AddTool{
--	ItemId="inquisitorssword";
--	Type="Melee";
--	Animations={
--		Core={Id=12173306866;};
--		Load={Id=12173309710;};
--		PrimaryAttack={Id=12173307810};
--		PrimaryAttack2={Id=12173308621};
--		HeavyAttack={Id=12173311102};
--		Inspect={Id=12173309089;};
--		Unequip={Id=12173310352};
--	};
--	--Animations={
--	--	Core={Id=4469912045;};
--	--	Load={Id=7181066235;};
--	--	PrimaryAttack={Id=4469937191};
--	--	PrimaryAttack2={Id=5044884973};
--	--	HeavyAttack={Id=4473902088};
--	--	Inspect={Id=3660032617;};
--	--	Unequip={Id=7181070871};
--	--};
--	Audio={
--		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
--		PrimaryHit={Id=9141019032; Pitch=0.6; Volume=1;};
--		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
--		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
--	};
--}

--AddTool{
--	ItemId="keytar";
--	Type="Melee";
--	Animations={
--		Core={Id=15338236803;};
--		Load={Id=7181066235;};
--		RoleplayCore={Id=15346268252};
--		Inspect={Id=3660032617;};
--		Unequip={Id=7181070871};
--		PrimaryAttack={Id=15346411192;};
--		HeavyAttack={Id=4473902088};
--	};
--	Audio={
--		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
--		PrimaryHit={Id=9141019032; Pitch=0.6; Volume=1;};
--		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
--		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
--	};
--}

function metaTools:LoadToolModule(module)
	if not module:IsA("ModuleScript") then return end;

	local itemId = module.Name;
	local toolPackage = require(module);

	toolPackage.ItemId = toolPackage.ItemId or itemId;
	toolPackage.Animations = toolPackage.Animations or {};
	toolPackage.Audio = toolPackage.Audio or {};
	toolPackage.Welds = toolPackage.Welds or {
		ToolGrip=(toolPackage.Generic or toolPackage.ItemId);
	};
	toolPackage.Module = module;
	toolPackage.WoundEquip = toolPackage.Type == "HealTool";
	
	local itemModel = module:FindFirstChild("itemModel");
	if itemModel then
		itemModel.Name = itemId;
		itemModel.Parent = game.ReplicatedStorage.Prefabs.Items;

		toolPackage.Prefab = itemModel;
	end
	
	if toolPackage.Audio then
		for soundType, audioProperties in pairs(toolPackage.Audio) do
			local audioId = audioProperties.Id;
			local soundFile = game.ReplicatedStorage.Library.Audio:FindFirstChild(tostring(audioId));
			if soundFile then
				modAudio.Library[audioId] = soundFile;

			else
				if modAudio.Library[audioId] == nil then
					soundFile = Instance.new("Sound", script);
					soundFile.Name = audioId;
					soundFile.SoundId = "rbxassetid://"..audioId;
					soundFile.PlaybackSpeed = audioProperties.Pitch;
					soundFile.EmitterSize = 5;
					if soundType == "PrimaryFire" then
						soundFile.RollOffMaxDistance = 128;
					elseif soundType == "Empty" then
						soundFile.RollOffMaxDistance = 16;
					else
						soundFile.RollOffMaxDistance = 32;
					end
					soundFile.SoundGroup = game.SoundService.WeaponEffects;
					soundFile.Volume = audioProperties.Volume ~= nil and audioProperties.Volume or 0.5;

					if modAudio.ModdedSelf then
						modAudio.ModdedSelf.OnWeaponAudioLoad(soundType, audioProperties, soundFile);
					end
					modAudio.Library[audioId] = soundFile;
				end
			end
		end
	end
	
	Tools[itemId] = toolPackage;
end

setmetatable(Tools, metaTools);

for _, m in pairs(script:GetChildren()) do
	if m.Name == "Template" then continue end;
	if m:GetAttribute("ToolPackage") ~= true then continue end;
	metaTools:LoadToolModule(m);
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Tools); end

return Tools;