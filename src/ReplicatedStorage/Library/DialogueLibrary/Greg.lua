local NpcDialogues = {};

NpcDialogues.Initial = {
	"What do you want, hippy.";
	"What's the big idea man?";
	"Get out of here, trying to do some work here.";
};

NpcDialogues.Dialogues = {
	{Tag="shop_ratShop";
		Dialogue="Do you sell anything?";
		Reply="No, go talk to the others..";
	};
	
	{Tag="general_mean";
		Dialogue="Why are you so mean?";
		Reply="You imbecile, mind your own gawd darn business and stop whining so much about things that are out of your control.";
	};
	
};

return NpcDialogues;