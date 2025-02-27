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
	
end

return CrateLibrary;