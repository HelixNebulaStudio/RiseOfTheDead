local RunService = game:GetService("RunService");

local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modTools = require(game.ReplicatedStorage.Library.Tools);

local CrateLibrary = {};
local library = {};
CrateLibrary.Library = library;

function CrateLibrary.Get(id)
	return library[id];
end

function CrateLibrary.New(data)
	if library[data.Id] ~= nil then error("CrateLibrary>>  Crate ID ("..data.Id..") already exist for ("..data.Name..").") end;
	library[data.Id] = data;
	if RunService:IsServer() then
		if data.Prefab == nil then
			data.Prefab = game.ServerStorage.PrefabStorage.Objects:FindFirstChild(data.PrefabName);
		end
		
		if data.Prefab == nil then
			data.Prefab = game.ReplicatedStorage.Prefabs.Items:FindFirstChild(data.PrefabName);
		end

		if data.Prefab == nil and modTools[data.Id] then
			data.Prefab = modTools[data.Id].Prefab;
		end
		
		if data.Prefab == nil then
			error("CrateLibrary>>  Crate ID ("..data.Id..") invalid crate prefab ("..data.PrefabName..").");
		end
	end
end

CrateLibrary.New{
	Id="donation";
	Name="The Void Crate";
	PrefabName="Crate";
	RewardsId={
		{ItemId="largemedkit"; Chance=100;};
	};
	Configurations={
		Persistent=false;
		Settings={
			DepositOnly=true;
			ScaleByContent=true;
		}
	};
};

--CrateLibrary.New{
--	Id="limit";
--	Name="The Limit Crate";
--	PrefabName="Crate";
--	RewardsId="sundaysGift";
--	Configurations={
--		Persistent=false;
--	};
--};

--== Boss

CrateLibrary.New{
	Id="prisoner";
	Name="The Prisoner Crate";
	PrefabName="Crate";
	RewardsId="prisoner";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="tanker";
	Name="The Tanker Crate";
	PrefabName="Crate";
	RewardsId="tanker";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="fumes";
	Name="The Fumes Crate";
	PrefabName="Crate";
	RewardsId="fumes";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="corrosive";
	Name="The Corrosive Crate";
	PrefabName="Crate";
	RewardsId="corrosive";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="zpider";
	Name="The Zpider Crate";
	PrefabName="Crate";
	RewardsId="zpider";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="shadow";
	Name="The Shadow Crate";
	PrefabName="Crate";
	RewardsId="shadow";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="zomborg";
	Name="The Zomborg Crate";
	PrefabName="Crate";
	RewardsId="zomborg";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="billies";
	Name="The Billies Crate";
	PrefabName="Crate2";
	RewardsId="billies";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="hectorshot";
	Name="Hector Shot Crate";
	PrefabName="Crate2";
	RewardsId="hectorshot";
	
	EmptyLabel="Empty";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="zomborgprime";
	Name="Zomborg Prime Crate";
	PrefabName="Crate2";
	RewardsId="zomborgprime";

	EmptyLabel="Empty";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

-- Winter Treelum

CrateLibrary.New{
	Id="wintertreelum";
	Name="Winter Treelum Crate";
	PrefabName="WinterCrate";
	RewardsId="wintertreelum";

	EmptyLabel="Empty";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

--== Extreme boss

CrateLibrary.New{
	Id="zricera";
	Name="The Zricera Crate";
	PrefabName="Crate2";
	RewardsId="zricera";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="vexeron";
	Name="The Vexeron Crate";
	PrefabName="Crate2";
	RewardsId="vexeron";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="mothena";
	Name="Mothena Crate";
	PrefabName="Crate2";
	RewardsId="mothena";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="pathoroth";
	Name="Pathoroth Crate";
	PrefabName="Crate2";
	RewardsId="pathoroth";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="banditheli";
	Name="The Bandit Helicopter Crate";
	PrefabName="Crate2";
	RewardsId="banditheli";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

CrateLibrary.New{
	Id="veinofnekron";
	Name="Vein Of Nekron Crate";
	PrefabName="Crate2";
	RewardsId="veinofnekron";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};


--== Raid
CrateLibrary.New{
	Id="factoryRaid";
	Name="Factory Raid Crate";
	PrefabName="Crate";
	EmptyLabel="Empty Crate";
	RewardsId="factoryRaid";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
		}
	};
};

--CrateLibrary.New{
--	Id="factorycrate";
--	Name="Factory Reward Crate";
--	PrefabName="factorycrate";
--	RewardsId="factorycrate";
--	Configurations={
--		Persistent=false;
--		Settings={
--			WithdrawalOnly=true;
--			DestroyOnEmpty=true;
--		}
--	};

--	EmptyLabel="Empty Crate";
--};

--CrateLibrary.New{
--	Id="officecrate";
--	Name="Office Reward Crate";
--	PrefabName="officecrate";
--	RewardsId="officecrate";
--	Configurations={
--		Persistent=false;
--		Settings={
--			WithdrawalOnly=true;
--			DestroyOnEmpty=true;
--		}
--	};
	
--	EmptyLabel="Empty Crate";
--};

CrateLibrary.New{
	Id="sectorfcrate";
	Name="Sector F Reward Crate";
	PrefabName="genericCrate";
	RewardsId="sectorfcrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	
	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="ucsectorfcrate";
	Name="Unclassified Sector F Reward Crate";
	PrefabName="genericCrate";
	RewardsId="ucsectorfcrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	
	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="tombschest";
	Name="Tombs Treasure Chest";
	PrefabName="tombschest";
	RewardsId="tombschest";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	
	EmptyLabel="Empty Chest";
};

CrateLibrary.New{
	Id="banditcrate";
	Name="Bandit Crate";
	PrefabName="banditcrate";
	RewardsId="banditcrate";
	
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="hbanditcrate";
	Name="Hard-Mode Bandit Crate";
	PrefabName="banditcrate";
	RewardsId="hbanditcrate";
	
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="prisoncrate";
	Name="Prison Reward Crate";
	PrefabName="prisoncrate";
	RewardsId="prisoncrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="nprisoncrate";
	Name="Notorious Prison Reward Crate";
	PrefabName="prisoncrate";
	RewardsId="nprisoncrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="railwayscrate";
	Name="Railways Reward Crate";
	PrefabName="railwayscrate";
	RewardsId="railwayscrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="sectordcrate";
	Name="Sector D Reward Crate";
	PrefabName="sectordcrate";
	RewardsId="sectordcrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	
	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="ucsectordcrate";
	Name="Unclassified Sector D Reward Crate";
	PrefabName="ucsectordcrate";
	RewardsId="ucsectordcrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};
	
	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="sunkenchest";
	Name="Sunken Chest";
	PrefabName="sunkenchest";
	RewardsId="sunkenchest";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};


CrateLibrary.New{
	Id="communitycrate";
	Name="Community Crate Alpha";
	PrefabName="communitycrate";
	RewardsId="communitycrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="communitycrate2";
	Name="Community Crate Beta";
	PrefabName="communitycrate2";
	RewardsId="communitycrate2";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="zenithcrate";
	Name="Zeniths Reward Crate";
	PrefabName="Crate4";
	RewardsId="zenithcrate";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=true;
		}
	};

	EmptyLabel="Empty Crate";
};

CrateLibrary.New{
	Id="raresunkencrate";
	Name="Eaten Sunken Crate";
	PrefabName="Raresunkenchest";
	RewardsId="empty";
	Configurations={
		Persistent=false;
		Settings={
			WithdrawalOnly=true;
			DestroyOnEmpty=false;
		}
	};

	EmptyLabel="Empty Crate";
};





--CrateLibrary.New{
--	Id="abandonedbunkercrate";
--	Name="Abandoned Bunker Crate";
--	PrefabName="abandonedbunkercrate";
--	RewardsId="abandonedbunkercrate";
--	Configurations={
--		Persistent=false;
--		Settings={
--			WithdrawalOnly=true;
--			DestroyOnEmpty=true;
--		}
--	};

--	EmptyLabel="Empty Chest";
--};

local resourcePackagesLib = modItemsLibrary.Library:ListByKeyValue("ResourceItemId", function(v) return v ~= nil; end);
for a=1, #resourcePackagesLib do
	local itemLib = resourcePackagesLib[a];
	local resourceItemId = itemLib.ResourceItemId;
	local resourceItemLib = modItemsLibrary:Find(resourceItemId);

	CrateLibrary.New{
		Id=itemLib.Id;
		Name=itemLib.Name;
		PrefabName="resourcecrate";
		RewardsId=itemLib.Id;
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};

		EmptyLabel="Empty Crate";
	};
end


local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(CrateLibrary); end

return CrateLibrary;