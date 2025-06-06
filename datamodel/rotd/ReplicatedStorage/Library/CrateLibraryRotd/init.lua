local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modCrateLibrary = shared.require(game.ReplicatedStorage.Library.CrateLibrary);

--== Script;
function modCrateLibrary.onRequire()
	-- MARK: Test
	modCrateLibrary.New{
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

	modCrateLibrary.New{
		Id="raresunkencrate";
		Name="Eaten Sunken Crate";
		PrefabName="Raresunkenchest";
		RewardsId="empty";
		StoragePresetId="lootcrate";
	
		EmptyLabel="Empty Crate";
	};

	-- MARK: Crate Rewards
	modCrateLibrary.New{
		Id="prisoner";
		Name="The Prisoner Crate";
		PrefabName="Crate";
		RewardsId="prisoner";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="tanker";
		Name="The Tanker Crate";
		PrefabName="Crate";
		RewardsId="tanker";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="fumes";
		Name="The Fumes Crate";
		PrefabName="Crate";
		RewardsId="fumes";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="corrosive";
		Name="The Corrosive Crate";
		PrefabName="Crate";
		RewardsId="corrosive";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="zpider";
		Name="The Zpider Crate";
		PrefabName="Crate";
		RewardsId="zpider";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="shadow";
		Name="The Shadow Crate";
		PrefabName="Crate";
		RewardsId="shadow";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="zomborg";
		Name="The Zomborg Crate";
		PrefabName="Crate";
		RewardsId="zomborg";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="billies";
		Name="The Billies Crate";
		PrefabName="Crate2";
		RewardsId="billies";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="hectorshot";
		Name="Hector Shot Crate";
		PrefabName="Crate2";
		RewardsId="hectorshot";
		
		EmptyLabel="Empty";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="zomborgprime";
		Name="Zomborg Prime Crate";
		PrefabName="Crate2";
		RewardsId="zomborgprime";
	
		EmptyLabel="Empty";
		StoragePresetId="rewardcrate";
	};

	modCrateLibrary.New{
		Id="zricera";
		Name="The Zricera Crate";
		PrefabName="Crate2";
		RewardsId="zricera";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="vexeron";
		Name="The Vexeron Crate";
		PrefabName="Crate2";
		RewardsId="vexeron";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="mothena";
		Name="Mothena Crate";
		PrefabName="Crate2";
		RewardsId="mothena";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="pathoroth";
		Name="Pathoroth Crate";
		PrefabName="Crate2";
		RewardsId="pathoroth";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="banditheli";
		Name="The Bandit Helicopter Crate";
		PrefabName="Crate2";
		RewardsId="banditheli";
		StoragePresetId="rewardcrate";
	};
	
	modCrateLibrary.New{
		Id="veinofnekron";
		Name="Vein Of Nekron Crate";
		PrefabName="Crate2";
		RewardsId="veinofnekron";
		StoragePresetId="rewardcrate";
	};

	modCrateLibrary.New{
		Id="zenithcrate";
		Name="Zeniths Reward Crate";
		PrefabName="Crate4";
		RewardsId="zenithcrate";
		StoragePresetId="rewardcrate";
		EmptyLabel="Empty Crate";
	};

	modCrateLibrary.New{
		Id="wintertreelum";
		Name="Winter Treelum Crate";
		PrefabName="WinterCrate";
		RewardsId="wintertreelum";
	
		EmptyLabel="Empty";
		StoragePresetId="rewardcrate";
	};
	

	-- MARK: Safehouse Gifts
	modCrateLibrary.New{
		Id="sundaysGift";
		Name="Sunday's Gift";
		PrefabName="Crate";
		RewardsId="sundaysGift";
		StoragePresetId="giftcrate";
	};

	modCrateLibrary.New{
		Id="underbridgeGift";
		Name="Underbridge's Gift";
		PrefabName="Crate";
		RewardsId="underbridgeGift";
		StoragePresetId="giftcrate";
	};

	modCrateLibrary.New{
		Id="mallGift";
		Name="Mall's Gift";
		PrefabName="Crate";
		RewardsId="mallGift";
		StoragePresetId="giftcrate";
	};


	modCrateLibrary.New{
		Id="clinicGift";
		Name="Clinic's Gift";
		PrefabName="Crate";
		RewardsId="clinicGift";
		StoragePresetId="giftcrate";
	};


	modCrateLibrary.New{
		Id="harborGift";
		Name="Harbor's Gift";
		PrefabName="Crate";
		RewardsId="harborGift";
		StoragePresetId="giftcrate";
	};
	
	modCrateLibrary.New{
		Id="residentialGift";
		Name="Residential's Gift";
		PrefabName="Crate";
		RewardsId="residentialGift";
		StoragePresetId="giftcrate";
	};
	
end

return modCrateLibrary;