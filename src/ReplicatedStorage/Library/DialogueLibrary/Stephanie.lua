local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hmmmm..? What do you want?";
	"Need something or what?";
};

NpcDialogues.Dialogues = {
	-- Chain Reaction
	{MissionId=15; Tag="chainReaction_start"; CheckMission=15; Dialogue="Interesting, what is it?"; Reply="Well, this one's called Electric Charge, I believe it damages nearby enemeis, seems useful for taking out multiple enemies."};
	{MissionId=15; Tag="chainReaction_useful"; Dialogue="That's definitely useful."; Reply="Yeah, I finished reading the book and there are two more of these elemental mods which I couldn't figure out how to make the blueprint for."};
	{MissionId=15; Tag="chainReaction_otherTwo"; Dialogue="Which are they?"; Reply="Frost and toxic.. I've worked out the fire and electricity mods blueprints now, but for the other two, I'm not sure what the materials are. Anyways, I'll call you when I figured it out."};
	
	{Tag="guide_battery"; Dialogue="Where can I find batteries?"; Reply="I think there might be some in the warehouse, if not maybe corrosive might have some..."};
	{Tag="guide_wires"; Dialogue="Where can I find wires?"; Reply="I think there might be some in the factory, if not maybe zpider might have some..."};
	
	-- Fail to meet requirements
	{Tag="startFail1"; Dialogue=""; Reply="Come back later, I'm not yet ready."};
	{Tag="startFail2"; Dialogue=""; Reply="I think you're not ready for this, come back when you're ready."};
	{Tag="startFail3"; Dialogue=""; Reply="Umm maybe you need to get better before you do this."};
};

return NpcDialogues;