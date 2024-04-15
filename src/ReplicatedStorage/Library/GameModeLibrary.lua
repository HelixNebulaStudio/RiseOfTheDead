local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = Debugger:Require(game.ReplicatedStorage.Library.Configurations);

local Shuffle = {
	SurvivalFailed={};
	BossKilledTrack={};
	WaveStartTrack={};
	WaveEndTrack={};
};

local GameModeLibrary = {};
GameModeLibrary.RequestEnums = {
	OpenInterface = 1;
	CloseInterface = 2;
	CreateRoom = 3;
	LeaveRoom = 4;
	JoinRoom = 5;
	Ready = 6;
	Unready = 7;
}

GameModeLibrary.RoomStatesEnums = {
	Idle = 1;
	Intermission = 2;
	InProgress = 3;
	Ending = 4;
	Close = 5;
}

GameModeLibrary.DefaultReadyLength = 6;

GameModeLibrary.GameModes={
	Boss={
		Module="Boss";
		Stages={
			["The Prisoner"]={
				Index=1;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=1978092491";
				Description="A prisoner zombie.. His right arm appears to be wrapped around with chains, maybe he can shackle me with those chains. But I wonder why this zombie is different from the others.";
				
				CrateId="prisoner";
				RewardsId="prisoner";
				Prefabs={
					["The Prisoner"]=Vector3.new(0.2, -1, 0);
				};
				Soundtrack="Soundtrack:Urban";
				HardModeEnabled=true;
			};
			["Tanker"]={
				Index=2;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=3187524766";
				Description="This zombie looks like someone I wouldn't mess with. Fortunately, he's a zombie now.";
				
				CrateId="tanker";
				RewardsId="tanker";
				Prefabs={
					["Tanker"]=Vector3.new(0.2, -1.5, 0);
				};
				Soundtrack="Soundtrack:Meet the Boss";
				HardModeEnabled=true;
			};
			["Fumes"]={
				Index=3;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=2034733375";
				Description="This one's a smelly one.";
				
				CrateId="fumes";
				RewardsId="fumes";
				Prefabs={
					["Fumes"]=Vector3.new(0.2, -1.1, 0);
				};
				Soundtrack="Soundtrack:The Boss";
			};
			["Corrosive"]={
				Index=4;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=2034744144";
				Description="It spills corrosive goo everywhere. What has it been feasting on?!";
				
				CrateId="corrosive";
				RewardsId="corrosive";
				Prefabs={
					["Corrosive"]=Vector3.new(0.2, -1.1, 0);
				};
				Soundtrack="Soundtrack:The Final Countdown";
			};
			["Zpider"]={
				Index=5;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=2034740441";
				Description="This is one big spider, there were rumors of BioX experimenting with spiders. I'm guessing this is it...";
				
				CrateId="zpider";
				RewardsId="zpider";
				Prefabs={
					["Zpider"]=Vector3.new(0.2, -0.6, 0);
				};
				Soundtrack="Soundtrack:Horror Race";
			};
			["Shadow"]={
				Index=6;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=3621243641";
				Description="It's really hard to see him, watch your backs.. It won't move unless it has to.";
				
				CrateId="shadow";
				RewardsId="shadow";
				Prefabs={
					["Shadow"]=Vector3.new(0.2, -1.1, 0);
				};
				Soundtrack="Soundtrack:The Depths Of Hell";
			};
			["Zomborg"]={
				Index=7;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=4320205133";
				Description="Which insane person decided it was a good idea to upgrade the zombies!?";
				
				CrateId="zomborg";
				RewardsId="zomborg";
				Prefabs={
					["Zomborg"]=Vector3.new(0.2, -1.1, 0);
				};
				Soundtrack="Soundtrack:Jailbreak";
			};
			["The Billies"]={
				Index=8;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=4517207657";
				Description="Someone should put these two lunatics to sleep. I think I'm up for it.";
				
				CrateId="billies";
				RewardsId="billies";
				Prefabs={
					["Karl"]=Vector3.new(-2.5, -1.1, 0); 
					["Klyde"]=Vector3.new(2.5, -1.1, 0)
				};
				Soundtrack="Soundtrack:Trapped";
				HardModeEnabled=true;
			};
			["Hector Shot"]={
				Index=9;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=4982655356";
				Description="He has yee'd his last haw.";
				
				CrateId="hectorshot";
				RewardsId="hectorshot";
				Prefabs={
					["Hector Shot"]=Vector3.new(0.2, -1.1, 0);
				};
				Soundtrack="Soundtrack:All Guts No Glory";
				HardModeEnabled=true;
			};
			["Zomborg Prime"]={
				Index=10;
				MaxPlayers=3;
				TitleImage="http://www.roblox.com/asset/?id=6805877114";
				Description="Looks like Zomborg has a mecha upgrade...";

				CrateId="zomborgprime";
				RewardsId="zomborgprime";
				Prefabs={
					["Zomborg Prime"]=Vector3.new(0.2, -1.1, 0);
				};
				Soundtrack="Soundtrack:Rise Of The Robot";
				HardModeEnabled=false;
			};
			
			
			--== Extreme Bosses
			["Zricera"]={
				MaxPlayers=8;
				TitleImage="http://www.roblox.com/asset/?id=3640418603";
				Description="I think I better get some help for this.";
				
				CrateId="zricera";
				RewardsId="zricera";
				Prefabs={
					["Zricera"]=Vector3.new(0, -5, -25);
				};
				Soundtrack="Soundtrack:Deadly Drone Assault";
				HardSoundtrack="Soundtrack:Deadly Drone Assault Hardcore";
				
				IsExtreme=true;
				SingleArena=true;
				HealthPerPlayer=8000;
				ReadyLength=20;
				
				HardModeEnabled=true;
				HardModeItem="zricerahorn";
			};
			
			["Vexeron"]={
				MaxPlayers=8;
				TitleImage="http://www.roblox.com/asset/?id=4601671040";
				Description="Fight it in it's domain, sure, why not..";
				
				CrateId="vexeron";
				RewardsId="vexeron";
				Prefabs={
					["Vexeron"]=Vector3.new(0, -5, -25);
				};
				Soundtrack="Soundtrack:SeeYouInHell";
				HardSoundtrack="Soundtrack:Relentless Guard";
				
				IsExtreme=true;
				SingleArena=true;
				HealthPerPlayer=16000;
				ReadyLength=20;
				
				HardModeEnabled=true;
				HardModeItem="vexling";
			};
			
			["Pathoroth"]={
				MaxPlayers=8;
				TitleImage="http://www.roblox.com/asset/?id=5712929087";
				Description="Appears to be stronger with zombies around it, and it just morphed into one of us!";

				CrateId="pathoroth";
				RewardsId="pathoroth";
				Prefabs={
					["Pathoroth"]=Vector3.new(0, -5, -25);
				};
				Soundtrack="Soundtrack:Ghost Warriors";

				IsExtreme=true;
				SingleArena=true;
				HealthPerPlayer=16000;
				ReadyLength=20;
			};
			
			["Mothena"]={
				MaxPlayers=8;
				TitleImage="http://www.roblox.com/asset/?id=6313471097";
				Description="Lamps";

				CrateId="mothena";
				RewardsId="mothena";
				Prefabs={
					["Mothena"]=Vector3.new(0, -5, -25);
				};
				Soundtrack="Soundtrack:Kill or Be Killed";

				IsExtreme=true;
				SingleArena=true;
				ExitTeleport=false;
				HealthPerPlayer=16000;
				ReadyLength=20;
				NoArenaBoundaries=true;
			};
			
			["Bandit Helicopter"]={
				MaxPlayers=8;
				TitleImage="http://www.roblox.com/asset/?id=5101726655";
				Description="Should I bring a knife to fight a helicopter?";
				
				CrateId="banditheli";
				RewardsId="banditheli";
				Prefabs={
					["Bandit Pilot"]=Vector3.new(0, -5, -25);
				};
				Soundtrack="Soundtrack:Dubstep Army";
				HardSoundtrack="Soundtrack:Dubstep Conquest";
				
				IsExtreme=true;
				SingleArena=true;
				ExitTeleport=false;
				HealthPerPlayer=32000;
				ReadyLength=20;
				NoArenaBoundaries=true;

				HardModeEnabled=true;
				HardModeItem="nekronparticulatecache";
			};
			
			
			["Vein Of Nekron"]={
				MaxPlayers=8;
				TitleImage="http://www.roblox.com/asset/?id=8750128901";
				Description="Looks like it's trying to spread, we should probably stop it from spreading..";
				
				CrateId="veinofnekron";
				RewardsId="veinofnekron";
				Prefabs={
					["Vein Of Nekron"]=Vector3.new(0, -5, -25);
				};
				Soundtrack="Soundtrack:Smiling Skulls";
				
				IsExtreme=true;
				SingleArena=true;
				ExitTeleport=false;
				HealthPerPlayer=16000;
				ReadyLength=20;
				NoArenaBoundaries=true;
			};
			
		};
	};
	
	Survival={
		Module="Survival";
		HardModeText="Endless";
		HardModeTitleImage="http://www.roblox.com/asset/?id=12409876370";
		Stages={
			["Sector F"]={
				WorldId="SectorF";
				ExitSpawn="CXsecF2";
				TitleImage="http://www.roblox.com/asset/?id=4817414130";
				MaxPlayers=4;
				RewardsId="sectorfcrate";
				RewardsIds={"sectorfcrate"; "ucsectorfcrate"};
				
				SurvivalFailedTrack="SectorFSoundtrack";
				BossKilledTrack="SectorFBossKilled";
				WaveStartTrack="SectorFWaveStart";
				WaveEndTrack="SectorFWaveEnd";
				
				LeaderboardDataKey="EWaves";
				
				HardModeEnabled=true;
			};
			["Prison"]={
				WorldId="Prison";
				ExitSpawn="hacClinic1";
				TitleImage="http://www.roblox.com/asset/?id=5943256940";
				MaxPlayers=4;
				RewardsId="prisoncrate";
				RewardsIds={"prisoncrate"; "nprisoncrate"};
				
				SurvivalFailedTrack="PrisonSoundtrack";
				BossKilledTrack="PrisonBossKilled";
				WaveStartTrack="PrisonWaveStart";
				WaveEndTrack="PrisonWaveEnd";
				
				LeaderboardDataKey="EWaves";

				HardModeEnabled=true;
			};
			["Sector D"]={
				WorldId="SectorD";
				ExitSpawn="sectorDToRes";
				TitleImage="http://www.roblox.com/asset/?id=7145049831";
				MaxPlayers=5;
				RewardsId="sectordcrate";
				RewardsIds={"sectordcrate"; "ucsectordcrate"};
				
				SurvivalFailedTrack="SectorDSoundtrack";
				BossKilledTrack="SectorDBossKilled";
				WaveStartTrack="SectorDWaveStart";
				WaveEndTrack="SectorDWaveEnd";
				
				LeaderboardDataKey="EWaves";

				HardModeEnabled=true;
			};
			["Community WaySide"]={
				WorldId="CommunityWaySide";
				TitleImage="http://www.roblox.com/asset/?id=10976370766";
				MaxPlayers=5;
				RewardsId="communitycrate";

				SurvivalFailedTrack="Soundtrack:Sin Doctor";
				BossKilledTrack=Shuffle.BossKilledTrack;
				WaveStartTrack=Shuffle.WaveStartTrack;
				WaveEndTrack=Shuffle.WaveEndTrack;

				LeaderboardDataKey="Waves";

				HardModeEnabled=true;
			};
			["Community FissionBay"]={
				WorldId="CommunityFissionBay";
				TitleImage="http://www.roblox.com/asset/?id=12401525448";
				MaxPlayers=5;
				RewardsId="communitycrate";

				SurvivalFailedTrack=Shuffle.SurvivalFailed;
				BossKilledTrack=Shuffle.BossKilledTrack;
				WaveStartTrack=Shuffle.WaveStartTrack;
				WaveEndTrack=Shuffle.WaveEndTrack;

				LeaderboardDataKey="Waves";

				HardModeEnabled=true;
			};
			["Community Rooftops"]={
				WorldId="CommunityRooftops";
				TitleImage="http://www.roblox.com/asset/?id=13951712046";
				MaxPlayers=5;
				RewardsId="communitycrate2";

				SurvivalFailedTrack=Shuffle.SurvivalFailed;
				BossKilledTrack=Shuffle.BossKilledTrack;
				WaveStartTrack=Shuffle.WaveStartTrack;
				WaveEndTrack=Shuffle.WaveEndTrack;

				LeaderboardDataKey="Waves";

				HardModeEnabled=true;
			};
		};
	};
	
	Raid={
		Module="Raid";
		Stages={
			["Factory"]={
				WorldId="Factory";
				ExitSpawn="factoryExit";
				MaxPlayers=1;
				TitleImage="http://www.roblox.com/asset/?id=4664135775";
				--CrateId="factoryRaid";
				RewardsId="factorycrate";
				Soundtrack="Soundtrack:Falster Trap";
			};
			
			["Office"]={
				WorldId="Office";
				ExitSpawn="officeExit";
				MaxPlayers=6;
				TitleImage="http://www.roblox.com/asset/?id=4665901752";
				RewardsId="officecrate";
				Soundtrack=(modConfigurations.SpecialEvent.Halloween and "Soundtrack:Creepy" or "Soundtrack:High Velocity");
			};
			
			["BanditOutpost"]={
				WorldId="BanditOutpost";
				ExitSpawn="patrick";
				MaxPlayers=6;
				TitleImage="http://www.roblox.com/asset/?id=4930132199";
				RewardsId="banditcrate";
				RewardsIds={"banditcrate"; "hbanditcrate"};
				Soundtrack="Soundtrack:Born With It";
				
				HardModeEnabled=true;
			};
			
			["Tombs"]={
				WorldId="Tombs";
				ExitSpawn="officeExit";
				MaxPlayers=6;
				TitleImage="http://www.roblox.com/asset/?id=5496384877";
				RewardsId="tombschest";
				Soundtrack="Soundtrack:Kill or Be Killed";
			};
			
			["Railways"]={
				WorldId="Railways";
				ExitSpawn="trainstation";
				MaxPlayers=6;
				TitleImage="http://www.roblox.com/asset/?id=6471930503";
				RewardsId="railwayscrate";
				Soundtrack="Soundtrack:Born Ready";
			};

			["Abandoned Bunker"]={
				WorldId="AbandonedBunker";
				ExitSpawn="communitySh";
				MaxPlayers=6;
				TitleImage="http://www.roblox.com/asset/?id=13496701772";
				RewardsId="abandonedbunkercrate";
				Soundtrack="Soundtrack:Into The Abyss";
				MapItemId="abandonedbunkermap";
			};
			
		};
	};
	
	
	Coop={
		Module="Coop";
		Stages={
			["Genesis"]={
				WorldId="Genesis";
				ExitSpawn="communitySh";
				TitleImage="http://www.roblox.com/asset/?id=7431603916";
				
				MaxPlayers=4;
				RewardsId="genesiscrate";
				RewardsIds={"genesiscrate"; "ggenesiscrate"};
				
				Soundtrack="Soundtrack:Void";

				HardModeEnabled=true;
			};
			
			["Mr. Klaw's Workshop"]={
				WorldId="KlawsWorkshop";
				TitleImage="http://www.roblox.com/asset/?id=8402447350";
				
				MaxPlayers=4;
				RewardsId= modConfigurations.SpecialEvent.Christmas and "xmaspresent2021" or nil;
				RewardsIds= modConfigurations.SpecialEvent.Christmas and {"xmaspresent2021";} or nil;
				
			};

			["SunkenShip"]={
				WorldId="SunkenShip";
				ExitSpawn="sewersToharbor";
				TitleImage="http://www.roblox.com/asset/?id=11114580671";
				Description="I think I'm going to need some diving goggles..";

				MaxPlayers=4;
				RewardsId="sunkenchest";
				RewardsIds={"sunkenchest";};

				Soundtrack="Soundtrack:Drowning World";

			};
		};
	};
};

function GameModeLibrary.GetGameMode(name)
	if GameModeLibrary.GameModes[name] == nil then
		Debugger:Warn("Could not get gamemode (",name,")");
	end
	return GameModeLibrary.GameModes[name];
end

function GameModeLibrary.GetStage(gamemode, name)
	if GameModeLibrary.GetGameMode(gamemode) then
		if GameModeLibrary.GameModes[gamemode].Stages[name] == nil then
			Debugger:Warn("Could not get stage (",name,") from gamemode (",gamemode,")");
		end
		return GameModeLibrary.GameModes[gamemode].Stages[name];
	end
end


for gamemode, _ in pairs(GameModeLibrary.GameModes) do
	for stageName, _ in pairs(GameModeLibrary.GameModes[gamemode].Stages) do
		local stageLib = GameModeLibrary.GameModes[gamemode].Stages[stageName];
		
		if stageLib.LeaderboardDataKey then
			local dataKey = stageLib.LeaderboardDataKey;
			stageLib.LeaderboardKeyTable = {};
			
			local modeKey = stageName..dataKey;
			stageLib.LeaderboardKeyTable["AllTime"..modeKey]={
				DatastoreName="LAT_"..modeKey;
				DatastoreId="LAT_"..modeKey;
				Folder="AllTimeStats";
				DataKey="LAT_"..modeKey;
			};
			stageLib.LeaderboardKeyTable["Weekly"..modeKey]={
				DatastoreName="LW_"..modeKey;
				DatastoreId="LW_"..modeKey;
				Folder="WeeklyStats";
				DataKey="LW_"..modeKey;
			};
			stageLib.LeaderboardKeyTable["Daily"..modeKey]={
				DatastoreName="LD_"..modeKey;
				DatastoreId="LD_"..modeKey;
				Folder="DailyStats";
				DataKey="LD_"..modeKey;
			};
		end
		
		if stageLib.SurvivalFailedTrack and typeof(stageLib.SurvivalFailedTrack) == "string" then
			table.insert(Shuffle.SurvivalFailed, stageLib.SurvivalFailedTrack)
		end
		if stageLib.BossKilledTrack and typeof(stageLib.BossKilledTrack) == "string" then
			table.insert(Shuffle.BossKilledTrack, stageLib.BossKilledTrack)
		end
		if stageLib.WaveStartTrack and typeof(stageLib.WaveStartTrack) == "string" then
			table.insert(Shuffle.WaveStartTrack, stageLib.WaveStartTrack)
		end
		if stageLib.WaveEndTrack and typeof(stageLib.WaveEndTrack) == "string" then
			table.insert(Shuffle.WaveEndTrack, stageLib.WaveEndTrack)
		end
		
	end
end

table.insert(Shuffle.SurvivalFailed, "ErrorSoundtrack");
table.insert(Shuffle.BossKilledTrack, "ErrorBossKilled");
table.insert(Shuffle.WaveStartTrack, "ErrorWaveStart");
table.insert(Shuffle.WaveEndTrack, "ErrorWaveEnd");

return GameModeLibrary;


-- Set Lobby Camera;
-- local s = game:GetService("Selection"):Get()[1]; s.CFrame = workspace.CurrentCamera.CFrame * CFrame.Angles(0, math.rad(90), 0); s.WorldPosition = workspace.CurrentCamera.CFrame.Position;