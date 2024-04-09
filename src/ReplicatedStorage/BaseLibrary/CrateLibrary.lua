local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local CrateLibrary = {};
CrateLibrary.__index = CrateLibrary;
--== Script;
function CrateLibrary:Init(super)

	--== Gifts
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
