local NpcDialogues = {};

NpcDialogues.Initial = {
	"A can of beans a day, keeps the doctor away..";
	"Needda patch up?";
	"I was a veterinarian, I guess it's not too different from an actual doctor right..?";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Patching you right up!"};
	
	--Spiking Up
	{MissionId=39; Tag="spikingUp_start"; CheckMission=39; Dialogue="Sure, what do you need?"; Reply="The zombies are often walking into the store gate and causing a lot of noise, could you build something to prevent that?"};
	{MissionId=39; Tag="spikingUp_sure"; Dialogue="How about some wooden spikes on the gates?"; Reply="Yeah! That's what I had in mind."};
	
	{MissionId=39; Tag="spikingUp_complete"; Dialogue="Yeah, it done. Hope you like it."; Reply="Great, now I can eat my beans in peace."};
	
};

return NpcDialogues;