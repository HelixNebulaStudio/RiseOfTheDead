local storyPackage = {
    Title = `Access Granted`;
    Plots = {
        {
            {N="Mason"; L=`Russell, help me pry open this door.`; F="Angry";};
            {L=`*Mason jams a crowbar in between the door*`;};
            {N="Russell"; L=`It's no good. This door is shut tight.`; F="Skeptical";};
            {N="Mason"; L=`God####it, this is the last place to search for the meds without crossing over to the North.`; F="Skeptical";};
            {N="Mason"; L=`Or brush up against the Rats in the South..`; F="Skeptical";};
            {N="Russell"; L=`Heck, what's so bad about buying it from the Rats?..`; F="Suspicious";};
        };
        {
            {N="Mason"; L=`You don't even want to interact with Jesse..`; F="Bored";};
            {N="Mason"; L=`I'm sure you know why..`; F="Bored";};
            {N="Russell"; L=`Then why are we still letting him operate here?`; F="Serious";};
            {N="Mason"; L=`Protection Russell.. Protection.`; F="Ugh";};
            {N="Russell"; L=`Whaat?.. Don't tell me you are scared of the Bandits all the way west?`; F="Question";};
        };
        {
            {N="Mason"; L=`Look, bandits won't bother us as long as they know that we have a Rat operating here..`; F="Bored";};
            {N="Russell"; L=`Yeah, sure, we'll eventually see the long con that's coming.`; F="Hehe";};
            {N="Russell"; L=`Then we'll see who's worse..`; F="Hehe";};
            {L=`*Footsteps from behind grows louder and louder*`;};
            {L=`*Mason and Russell both turn around and pointed their guns*`;};
        };
        {
            {N="Lennon"; L=`Woaaaaaah, easy there fellas`; F="Oops";};
            {N="Mason"; L=`Lennon? What the hell are you doing down here?`; F="Angry";};
            {N="Lennon"; L=`I live here, nothing beats the comfort of dripping water.`; F="Bored";};
            {N="Russell"; L=`Know anything about getting in this here door?`; F="Suspicious";};
            {N="Lennon"; L=`Sector F? Everyone with half a brain knows about what this is. The question is who's got the guts to actually go in.`; F="Hehe";};
            {N="Mason"; L=`And you're saying you've got the guts?`; F="Skeptical";};
            {N="Lennon"; L=`HA! I've got whole lot of nothing to lose and I may know a way in.`; F="Serious";};
        };
    };
};

return storyPackage;