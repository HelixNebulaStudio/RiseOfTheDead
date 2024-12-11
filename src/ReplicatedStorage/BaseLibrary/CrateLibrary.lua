local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local CrateLibrary = {};
CrateLibrary.__index = CrateLibrary;

--== Script;
function CrateLibrary:Init(super)
	-- MARK: Test
	super.New{
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

	-- MARK: Raids
	super.New{
		Id="factorycrate";
		Name="Factory Reward Crate";
		PrefabName="factorycrate";
		RewardsId="factorycrate";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};

		EmptyLabel="Empty Crate";
	};

	super.New{
		Id="officecrate";
		Name="Office Reward Crate";
		PrefabName="officecrate";
		RewardsId="officecrate";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};

		EmptyLabel="Empty Crate";
	};

	super.New{
		Id="genesiscrate";
		Name="Genesis Crate";
		PrefabName="genesiscrate";
		RewardsId="genesiscrate";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};

		EmptyLabel="Empty Crate";
	};

	super.New{
		Id="ggenesiscrate";
		Name="Golden Genesis Reward Crate";
		PrefabName="ggenesiscrate";
		RewardsId="ggenesiscrate";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};

		EmptyLabel="Empty Crate";
	};

	--
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
--
	super.New{
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

	-- MARK: Crate Rewards
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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

	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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
	
	super.New{
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

	super.New{
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

	super.New{
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
	
	-- MARK: Rewards
	super.New{
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

	super.New{
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


	--MARK: Events
	super.New{
		Id="xmaspresent";
		Name="Christmas Present 2019";
		PrefabName="XmasPresent";
		RewardsId="xmaspresent";

		EmptyLabel="Empty Present";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};

	super.New{
		Id="xmaspresent2020";
		Name="Christmas Present 2020";
		PrefabName="XmasPresent2020";
		RewardsId="xmaspresent2020";

		EmptyLabel="Empty Present";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};

	super.New{
		Id="xmaspresent2021";
		Name="Christmas Present 2021";
		PrefabName="XmasPresent2021";
		RewardsId="xmaspresent2021";

		EmptyLabel="Empty Present";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};

	super.New{
		Id="xmaspresent2022";
		Name="Christmas Present 2022";
		PrefabName="XmasPresent2022";
		RewardsId="xmaspresent2022";

		EmptyLabel="Empty Present";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};

	super.New{
		Id="xmaspresent2023";
		Name="Christmas Present 2023";
		PrefabName="XmasPresent2023";
		RewardsId="xmaspresent2023";

		EmptyLabel="Empty Present";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};
	
	super.New{
		Id="xmaspresent2024";
		Name="Christmas Present 2024";
		PrefabName="XmasPresent2024";
		RewardsId="xmaspresent2024";

		EmptyLabel="Empty Present";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};
	
	super.New{
		Id="easteregg";
		Name="Easter Egg 2020";
		PrefabName="EasterEgg";
		RewardsId="easteregg";

		EmptyLabel="Empty Egg";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};

	super.New{
		Id="easteregg2021";
		Name="Easter Egg 2021";
		PrefabName="EasterEgg";
		RewardsId="easteregg2021";

		EmptyLabel="Empty Egg";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};
	
	super.New{
		Id="easteregg2023";
		Name="Easter Egg 2023";
		PrefabName="EasterEgg";
		RewardsId="easteregg2023";

		EmptyLabel="Empty Egg";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};

	super.New{
		Id="slaughterfestcandybag";
		Name="Slaughterfest Candy Bag";
		PrefabName="CandyBag";
		RewardsId="slaughterfestcandybag";

		EmptyLabel="Empty Bag";
		Configurations={
			Persistent=false;
			Settings={
				WithdrawalOnly=true;
				DestroyOnEmpty=true;
			}
		};
	};


	-- MARK: Safehouse Gifts
	super.New{
		Id="sundaysGift";
		Name="Sunday's Gift";
		PrefabName="Crate";
		RewardsId="sundaysGift";
		Configurations={
			Persistent=true;
			Settings={
				WithdrawalOnly=true;
			}
		};
	};

	super.New{
		Id="underbridgeGift";
		Name="Underbridge's Gift";
		PrefabName="Crate";
		RewardsId="underbridgeGift";
		Configurations={
			Persistent=true;
			Settings={
				WithdrawalOnly=true;
			}
		};
	};

	super.New{
		Id="mallGift";
		Name="Mall's Gift";
		PrefabName="Crate";
		RewardsId="mallGift";
		Configurations={
			Persistent=true;
			Settings={
				WithdrawalOnly=true;
			}
		};
	};


	super.New{
		Id="clinicGift";
		Name="Clinic's Gift";
		PrefabName="Crate";
		RewardsId="clinicGift";
		Configurations={
			Persistent=true;
			Settings={
				WithdrawalOnly=true;
			}
		};
	};


	super.New{
		Id="harborGift";
		Name="Harbor's Gift";
		PrefabName="Crate";
		RewardsId="harborGift";
		Configurations={
			Persistent=true;
			Settings={
				WithdrawalOnly=true;
			}
		};
	};
	
	super.New{
		Id="residentialGift";
		Name="Residential's Gift";
		PrefabName="Crate";
		RewardsId="residentialGift";
		Configurations={
			Persistent=true;
			Settings={
				WithdrawalOnly=true;
			}
		};
	};
	

	-- MARK: Resource Packages
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	local resourcePackagesLib = modItemsLibrary.Library:ListByKeyValue("ResourceItemId", function(v) return v ~= nil; end);
	for a=1, #resourcePackagesLib do
		local itemLib = resourcePackagesLib[a];
		--local resourceItemId = itemLib.ResourceItemId;
		--local resourceItemLib = modItemsLibrary:Find(resourceItemId);

		super.New{
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
end

return CrateLibrary;