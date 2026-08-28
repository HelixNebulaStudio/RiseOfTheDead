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
            {N="Lennon"; L=`Strange is what keeps you alive out here. Now come on, there's an entrance about down the tunnel.`; F="Serious";};
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
            {L=`*Mason peaks into the room with his revolver over and flashlight under pointing at a person crouched over a container*`};
            {N="Mason"; L=`Hands where I can see 'em!`; F="Skeptical";};
            {N="Valeria"; UnknownName=true; L=`*Slowly turns around with both her hands carefully raised*`; F="Serious";};
            {N="Russell"; L=`State your name, and who you are affiliated!`; F="Angry";};
            {N="Lennon"; L=`*Looks around the room, noticing scratches and dented all over.*`; F="Surprise";};
            {N="Valeria"; UnknownName=true; L=`*Does not respond and appears unfazed.*`; F="Serious";};
        };
        {--10;
            {N="Mason"; L=`Look, we are just looking for medical supplies here.. If you let us know who you're with or what you are doing here, maybe we could help each other.`; F="Suspicious";};
            {N="Valeria"; UnknownName=true; L=`*Still non-responding to the question, but slowly side steps towards the other doorway*`; F="Suspicious";};
            {L=`*The stranger slips out the door and ran away. Mason and Russell lowers their guard.*`};
            {N="Russell"; L=`What the heck was that?`; F="Ugh";};
            {N="Mason"; L=`Hmmm, can't blame them. It's everyone for themselves nowadays.`; F="Surprise";};
            {N="Mason"; L=`We should probably start searching quickly, she might be in a group and they might not be so kind.`; F="Surprise";};
            {N="Russell"; L=`I want to be out of this place ASAP. This place gives me the creeps.`; F="Ugh";};
        };
        {--11
            {L=`*They sweep the room, overturning crates and rifling through cabinets. Russell stops at a dented locker.*`};
            {N="Russell"; L=`Hey, you two might want to see this.`; F="Serious";};
            {N="Mason"; L=`What is it?`; F="Question";};
            {N="Russell"; L=`A keycard..`; F="Surprised";};
            {N="Russell"; L=`Dr. Baileys.. Know anyone by that name?`; F="Suspicious";};
            {N="Mason"; L=`No clue, regardless, try the keycard on that panel over there. *Pointing at a screen and panel on the wall with a keycard reader*`; F="Confident";};
            {N="Lennon"; L=`Umm guys.. *Calling out for attention while being carefully loud to not alert anything else*`; F="Serious";};
        };
        {--12
            {L=`*A LOUD ROAR ECHOS at the entrance, drawing Russell's attention before he reached the panel.*`};
            {N="Lennon"; L=`WATCH OOO..`; F="Surprise";};
            {L=`*Before Lennon could finish alerting them, a creature the size larger than a door charges at Russell*`};
            {L=`Slamming on to the metal plated walls of the facility, knocking Russell off his feet.`};
            {N="Mason"; L=`HOLY ####!`; F="Angry";};
            {N="Mason"; L=`*Mag dumps onto the creature with green goo sizzling out at every point where the bullets land.*`; F="Frustrated";};
            {N="Lennon"; L=`Go get 'em! *Cheering as he peeks over from behind some crates..`; F="Joyful"};
            {N="Russell"; L=`*Scrabbling backwards over broken cables, moving away from the creature as it slowly regain conscious after slamming onto the wall*`};
        };
        {--13
            {L=`*Sizzling goo drips onto the floor as Russell regains his footing.*`};
            {N="Mason"; L=`Russell!! Get out!`; F="Angry";};
            {N="Russell"; L=`*Swiftly picks up the keycard he dropped but realizes his pistol is half melted away by its goo*`; F="Frustrated";};
            {N="Russell"; L=`We got to use the keycard Mason! We need to get something out of this!`; F="Angry";};
            {N="Mason"; L=`*Reluctantly agrees* Fine! *Takes another shot at the goo spewing giant.*`; F="Serious"};
            {L="*The huge beast regains mobility and slowly turns towards Mason*"};
            {N="Lennon"; L=`Oh now he mad!!`; F="Hehe"};
        };
        {--14
            {N="Mason"; L=`Over here big guy!`; F="Smirk"};
            {L=`*The big guy growls as it readys to charge.*`};
            {N="Russell"; L=`*Slowly inching closer to an opening to get to the access panel.*`; F="Skeptical";};
            {L=`*As the massive zombie starts charging, its leg gets tangled with a broken cable, but it forces through and drags the cable along as it charges towards Mason.*`};
            {L=`*In a twist of fate, the coiled cables Russell was stepping over tightens around his foot.*`};
            {N="Russell"; L=`*Gets knocked over, dropping the keycard and dragged along where the goo-titan was charging.*`};
        };
        {--15
            {N="Mason"; L=`*Leaps and slide away a hair's breadth of collision and watches as the unstoppable force slams onto the metal plated walls.*`; F="Surprise"};
            {N="Russell"; L=`Get this off me! *Struggling to untie himself from the old cable strangling his foot`; F="Frustrated"};
            {N="Lennon"; L=`I'll help Russell, go get the keycard!`; F="Confident"};
            {N="Mason"; L=`*Sprints towards the keycard, however a horde of zombies floods into the room, walking over the keycard.`; F="Skeptical";};
            {N="Mason"; L=`This is not good, we are getting surrounded.`; F="Serious"};
            {N="Lennon"; L=`*Untangles Russell from the cables and pulls out a rusty-but-trusty Grand Garand.`; F="Hehe"};
        };
        {--16
            {N="Russell"; L=`Where have you been hiding that?!`; F="Question"};
            {N="Lennon"; L=`Well, this piece of master craftmenship is actually a piece of antique passed down from generations to generation..`; F="Joyful"};
            {N="Russell"; L=`Nevermind me asking.`; F="Bored"};
            {N="Lennon"; L=`*Adjusts his scope and aim's down the sight.`; F="Yeesh"};
            {N="Lennon"; L=`*Chambers a bullet and pulls the trigger.*`; F="Smirk"};
        };
        {--17
            {L=`*As the Garand's clings echo, the projectile flies through head after heads of zombies.*`;};
            {L=`*The bullet leaves glowing streak as it sparks hitting the wall and a loud zzzing, the bullet ricochets onto a few more zombies.*`;};
            {N="Mason"; L=`Wow, look at it go!`; F="Surprise"};
            {N="Russell"; L=`How on earth?!`; F="Surprise"};
            {N="Mason"; L=`You sure are full of surprises Lennon..`; F="Smirk"};
            {L=`*The corrosive gaint regains consciousness shaking and roaring and the room continues to flood with zombies.*`};
        };
        {--18
            {N="Lennon"; L="There're way too many of them!"; F="Frustrated"};
            {N="Mason"; L="Guess now it's a good of time as ever. *Pulls out a pear shaped device.*"; F="Serious"};
            {N="Russell"; L="Is that what I think it is?"; F="Joyful"};
            {N="Mason"; L="Yep, haha got it from the vending machine."; F="Smirk"};
            {N="Mason"; L="Alright, get ready! That thing's going to charge at us, and I will drop this nade below him."};
            {N="Lennon"; L="AND BLOW THEM ALL TO SMITHEREENS!"; F="Joyful"};
        };
        {--19
            {L="**";};
        };
    };
};

return storyPackage;