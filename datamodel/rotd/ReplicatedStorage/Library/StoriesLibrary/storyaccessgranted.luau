local storyPackage = {
    Title = `Access Granted`;
    Plots = {
        {--1
            {N="Mason"; L=`Russell, help me pry open this door.`; F="Angry";};
            {L=`*Mason jams a crowbar in between the door*`;};
            {N="Russell"; L=`It's no good. This door is shut tight.`; F="Skeptical";};
            {N="Mason"; L=`God####it, this is the last place to search for the meds without crossing over to the North.`; F="Skeptical";};
            {N="Mason"; L=`Or brush up against the Rats in the South..`; F="Skeptical";};
            {N="Russell"; L=`Heck, what's so bad about buying it from the Rats?..`; F="Suspicious";};
        };
        {--2
            {N="Mason"; L=`You don't even want to interact with Jesse..`; F="Bored";};
            {N="Mason"; L=`I'm sure you know why..`; F="Bored";};
            {N="Russell"; L=`Then why are we still letting him operate here?`; F="Serious";};
            {N="Mason"; L=`Protection Russell.. Protection.`; F="Ugh";};
            {N="Russell"; L=`Whaat?.. Don't tell me you are scared of the Bandits all the way west?`; F="Question";};
        };
        {--3
            {N="Mason"; L=`Look, bandits won't bother us as long as they know that we have a Rat operating here..`; F="Bored";};
            {N="Russell"; L=`Yeah, sure, we'll eventually see the long con that's coming.`; F="Hehe";};
            {N="Russell"; L=`Then we'll see who's worse..`; F="Hehe";};
            {L=`*Footsteps from behind grows louder and louder*`;};
            {L=`*Mason and Russell both turn around and pointed their guns*`;};
        };
        {--4
            {N="Lennon"; L=`Woaaaaaah, easy there fellas`; F="Oops";};
            {N="Mason"; L=`Lennon? What the hell are you doing down here?`; F="Angry";};
            {N="Lennon"; L=`I live here, nothing beats the comfort of dripping water.`; F="Bored";};
            {N="Russell"; L=`Know anything about getting in this here door?`; F="Suspicious";};
            {N="Lennon"; L=`Sector F? Everyone with half a brain knows about what this is. The question is who's got the guts to actually go in.`; F="Hehe";};
            {N="Mason"; L=`And you're saying you've got the guts?`; F="Skeptical";};
            {N="Lennon"; L=`HA! I've got whole lot of nothing to lose and I may know a way in.`; F="Serious";};
        };
        {--5
            {N="Russell"; L=`Wait wait wait, hold on. What's in it for you?`; F="Suspicious";};
            {N="Lennon"; L=`What's in it for me? I get to see what's behind that door. That's payment enough.`; F="Hehe";};
            {N="Mason"; L=`You're a strange man, Lennon.`; F="Bored";};
            {N="Lennon"; L=`Strange is what keeps you alive out here. Now come on, the tunnel entrance is about a hundred yards east.`; F="Serious";};
            {L=`*Lennon starts walking, flashlight cutting through the dark*`;};
            {N="Russell"; L=`I don't trust him, Mason.`; F="Suspicious";};
            {N="Mason"; L=`I don't trust anyone. But he's got a way in, and we've got nothing.`; F="Ugh";};
            {N="Russell"; L=`Famous last words.`; F="Skeptical";};
        };
        {--6
            {L=`*They find the maintenance tunnel and crawl inside, the rusted grate screeching shut behind them*`;};
            {N="Mason"; L=`This tunnel's been used recently. Fresh boot prints in the muck.`; F="Suspicious";};
            {N="Russell"; L=`Fresh? How fresh?`; F="Question";};
            {N="Mason"; L=`A day, maybe two. Someone's been in here.`; F="Serious";};
            {N="Lennon"; L=`Could be scavengers. Could be something else.`; F="Bored";};
            {N="Russell"; L=`What exactly are you hinting at, Lennon?`; F="Skeptical";};
            {N="Lennon"; L=`It's probably nothing but those prints also leads to that broken wall over there..`; F="Serious";};
        };
        {--7
            {L=`*The tunnel behind the cracked wall opens into a wider passage. Pipes line the walls, dripping with glowing goo*`};
            {N="Lennon"; L=`If I remembered correctly, this runs under the whole sector and comes up in the sub-basement of the main lab.`; F="Bored";};
            {N="Mason"; L=`Sub-basement. Sounds pleasant.`; F="Ugh";};
            {N="Lennon"; L=`Whatever you're looking for, it's gotta be there.`; F="Serious";};
            {N="Russell"; L=`And if there's something else down there?`; F="Suspicious";};
            {N="Mason"; L=`Then we deal with it. Same as we deal with everything else.`; F="Serious";};
        };
        {--8
            {L=`*They climb a rusted ladder into the sub-basement. The vast complex stretches out before them*`;};
            {N="Mason"; L=`It's huge.`; F="Question";};
            {N="Lennon"; L=`BioX didn't do things by halves. This was their crown jewel.`; F="Bored";};
            {N="Russell"; L=`Was.`; F="Skeptical";};
            {N="Lennon"; L=`Was. Look around. This place has been gutted.`; F="Serious";};
            {L=`*Mason darts his head towards a eerie doorway*`};
            {N="Mason"; L=`Wait.. Did you hear that?`; F="Question";};
            {L=`*Russell and Lennon instantly went on high alert*`};
        };
        {--9
            {L=`*They move quietly closer towards the doorway as the rustling sound grows louder.`};
            {L=`*Mason peaks into the  *`};
        };
    };
};

return storyPackage;