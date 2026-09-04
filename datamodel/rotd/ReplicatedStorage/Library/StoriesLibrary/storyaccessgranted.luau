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
            {N="Russell"; L=`Hey, you two might want to see this. *Looking at something protruding like it's hidden in haste*`; F="Serious";};
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
            {N="Lennon"; L=`Go get 'em! *Cheering as he peeks over from behind some crates..*`; F="Joyful"};
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
            {L="*The horde surrounds them tigher and the roar grows louder. Zombies being knocked out of the way as the behemoth charges through them.*";};
            {N="Mason"; L="Dodge now!"; F="Surprise";};
            {L="*The Corrosive beast crashes into the horde behind Mason like a bunch of bowling pins.*";};
            {N="Mason"; L="*Tosses the grenade into the crowd.*"; F="Angry"};
            {N="Mason"; L="Take cover!"; F="Angry"};
            {N="Russell"; L="*Jumps behind a bunch of dead bodies.*"};
            {N="Lennon"; L="*Hides behind a desk panel.*"};
            {L="*The grenade explodes and shook the whole building.*"};
        };
        {--20
            {L="*The build is filled with smoke and Zombie parts rains everywhere.*"};
            {N="Lennon"; L="*cough* *cough* Is it dead?"; F="Joyful"};
            {L="*The smoke fades slowly and a new beam of light shines through.*"};
            {L="*Corrosive appears to be missing from the spot it was last seen, but instead, they see warped metal sheets and a hole into another room.*"};
            {N="Russell"; L="Might not be.."; F="Skeptical"};
            {L="*The smoke cloud fades away, revealing rusty pipes and moldy walls.*"};
            {N="Mason"; L="Is that the sewers?!"};
        };
        {--21
            {N="Lennon"; L="*shrugs*"; F="Hehe"};
            {N="Russell"; L="Whether it's dead or alive, we should barricade the wall with something so it doesn't come back."; F="Serious"};
            {N="Mason"; L="*Pushes a heavy machinary with Lennon, blocking off the hole in the wall.*"; F="Frustrated"};
            {L="*Out of no where, a zombie flew at Mason, knocking him out*"};
            {N="Russell"; L="Mason!"; F="Disbelief"};
            {N="Lennon"; L="*Headshots the Zombie that was thrown to ensure it's dead*"; F="Surprise"};
            {N="Russell"; L="*Dashes towards Mason*"; F="Angry"};
        };
        {--22
            {L="*Another horde cries was heard. This time it echos louder and denser.*";};
            {L="*Tens upon tens of Zombies rushes into the facility.*"};
            {N="Lennon"; L="*Rapidly pulling the trigger like he's firing at full auto*"; F="Frustrated"};
            {N="Lennon"; L="Today's not the day Lennon dies!"; F="Angry"};
            {L="*Zombie bodies piles up, slowing down the horde and buying them time..*"};
            {N="Russell"; L="MASON! WAKE UP!! *Shakes Mason violently*"; F="Scared"};
        };
        {--23
            {N="Mason"; L="*...Regaining consciousness, but struggles to focus on anything*"; F="Yeesh"};
            {L="*A Heavy pushes in, grabs and toss another Zombie. This time at Lennon.*"};
            {N="Lennon"; L="*Evaded the zombie, but the Garand's barrel got caught and gets knocked out of his hand.*"; F="Disbelief"};
            {L="*All the exits are blocked off by zombies trying to squeeze through, they are surrounded*"};
            {N="Russell"; L="Lennon, we need a way out! I'll carry Mason."; F="Frustrated";};
            {N="Lennon"; L="I'll try to make a path out."; F="Serious"};
            {N="Lennon"; L="*With the zombie laying on his Garand, he pulls out a knife and starts stabbing Zombies. Trying to make a path, but it was of no avail*"; F="Serious"};
        };
        {--24
            {N="Lennon"; L="It's no good buddy. We're trapped.."; F="Skeptical"};
            {L="*A thin sword out of nowhere pierces the head of a Zombie from behind.*";};
            {N="Russell"; L="Who the heck?"; F="Surprised";};
            {L="*In quick sucession, zombies after zombies falls to the ground by the sound of a blade precisely cutting through bodies*"};
            {L="*Russell and Lennon reliefed knowing they aren't trapped anymore*"};
            {N="Lennon"; L="*Takes the chance to shove the Zombie away to pick up his Garand and starts reloading it.*"; F="Smirk";};
        };
        {--25
            {N="Russell"; L="*Swing his fire axe at the zombie attempting to grab him.*"; F="Angry"};
            {N="Valeria"; UnknownName=true; L="*Pulls out her sword from a dead zombie*"; F="Serious"};
            {N="Lennon"; L="Oh, she's back."; F="Surprise"};
            {N="Valeria"; UnknownName=true; L="*Sheathes her sword and puts out her hand for Mason*"; F="Confident"};
            {N="Mason"; L="*With his concussion fading, he sees a hand reaching out for him.*"; F="Skeptical"};
            {N="Mason"; L="*Pulls himself up with the help of the stranger.*"; F="Yeesh"};
        };
        {--26
            {N="Mason"; L="Err.. Thanks.. But why did you come back?"; F="Smile"};
            {N="Valeria"; UnknownName=true; L="I'm not gonna lie, I'm also here to find something behind that door."; F="Skeptical"};
            {N="Russell"; L="Well, tough luck. We don't have a way in.. *Hiding the fact that the keycard is lost somewhere under the bodies.*"; F="Bored"};
            {N="Valeria"; UnknownName=true; L="*Pulls out a keycard* You mean this keycard?"; F="Suspicious"};
            {N="Valeria"; UnknownName=true; L="I found this on the ground.."; F="Skeptical"};
            {N="Russell"; L="Heck, there it is! Glad you found it."; F="Oops"};
        };
        {--27
            {N="Mason"; L="We just need.. the medkits. *Abit stuttery from his injuries.*"; F="Surprise"};
            {N="Valeria"; UnknownName=true; L="Don't worry, you can have it. I'm looking for a way out of Wrighton dale.."; F="Worried"};
            {N="Lennon"; L="Why would anyone want to leave???"; F=""};
            {N="Mason"; L=".. I think we want to know more is what could be in the room that would help you leave Wrighton Dale?"; F="Surprise";};
            {N="Valeria"; UnknownName=true; L="... The borders all barricaded off and you need the protocol to get pass the military checkpoint."; F="Frustrated";};
            {N="Valeria"; UnknownName=true; L="BioX employees has a protocol to get pass the Golden Bridge checkpoint, I need to find them to get ."; F="Skeptical";};
        };
        {--28
            {N="Lennon"; L="The military works with BioX, who would've guessed.. Wait! I would've guessed actually."; F="Hehe";};
            {N="Mason"; L="*Walks toward the keycard panel and pressed a button to see if it is still powered.*"; F="Suspicious";};
            {N="Valeria"; UnknownName=true; L="*Walks to the panel with the card out*"; F="Confident";};
            {N="Mason"; L="Go on ahead, miss.."; F="Smile";};
            {N="Valeria"; L="Valeria. Nice to meet you."; F="Confident"};
            {N="Mason"; L="Mason, like-wise."; F="Happy";};
        };
        {--29
            {N="Valeria"; L="*Taps the card on the panel*"; F="";};
            {L="*The screen on the panel turns on. Sparks shoots down from the ceiling. A static buzzing plays like it's been untouched for a long time.*"};
            {N="Mason"; L="*Shelters his eyes like it's really sunny out*"; F="Surprise";};
            {L="*Nothing happens for a few seconds, then the screen turns green.*"};
            {N="Russell"; L="*Brings his fire axe up to a ready stance*"; F="Suspicious";};
            {N="Lennon"; L="Here we gooo.."; F="Hehe";};
            {L="*A dark smoke emits from the sliding doors onto the ground.. A charm plays from the keypad and the screen says: [ ACCESS GRANTED ]*"};
        };
        {--30
            {L="*The scent of death blooms out from the gaps of the sliding doors as it slides open*";};
            {L="*Metal sounds clink and rattle louder and louder, and POP. The doors stops opening, only opened large enough to squeeze through*"};
            {N="Lennon"; L="AW C'MON"; F="Angry"};
            {N="Mason"; L="*Pulls out his crowbar* Alright, c'mon help me pull this open.."; F="Bored"};
            {N="Valeria"; L="*Pulls on the other sliding door enough to get through."; F="Serious"};
            {N="Russell"; L="*Turns around to keep an eye out*"; F="Skeptical"};
        };
        {--31
            {L="*They got through the door and saw bones behind the door is what cause the sliding door to jam up.*"};
            {N="Mason"; L="This looks like some kind of trial chamber.."; F="Suspicious"};
            {N="Valeria"; L="Human.. Trials.. "; F="Serious"};
            {L="*The deeper they walk into the room, the more horrors reveals.*";};
            {N="Mason"; L="It's as if we could still hear the screams of the patients.."; F="Serious"};
            {N="Mason"; L="*Opens up a dusty cabinet, a bloom of dust puff into the air* *Cough cough* Found some papers.."; F="Yeesh"};
        };
        {--32
            {N="Lennon"; L="*Knocks on a fogged up glass into an aquarium-like tank to see if there's anything alive*"; F="Skeptical";};
            {N="Lennon"; L="Looks like there some dead plants in here.."; F=""};
            {N="Mason"; L="*Pulls up a random file from the cabinet* ..Some kind of record ..Trail#27 ..Patient#72, 2 dosage Omega 3 removed .."; F="Skeptical"};
            {N="Valeria"; L="Read the title.."; F="Angry"};
            {N="Mason"; L="Project BioEnchancer, Super Human Serum Trial"; F="Serious"};
        };
        {--33
            {N="Russell"; L="Ah, of course. Creating super solders.."; F="Bored"};
            {N="Valeria"; L="*Scavenging through other cabinets..*"; F="Worried"};
            {N="Mason"; L="*Reading from the file..* ..Test unsuccesful, patient present symtoms of reduced motivation and the drive to survive.."; F="";};
            {N="Mason"; L="Patient appears to mimick the same .. I think I've read enough horrors for today.."; F="Angry"};
            {N="Valeria"; L="Found what you've been looking for.. General purpose medical supplies."; F="Smile"};
        };
        {--34
            {N="Mason"; L="Yes! Thank you. *Gestures Russell to come over.* We'll bag it up."; F="Joyful";};
            {N="Mason"; L="You sure you don't need any?"; F="Surprise"};
            {N="Valeria"; L="I already got my own, but thanks."; F="Smile"};
            {N="Valeria"; L="*Resumes searching for the BioX protocols.*"; F="Bored"};
            {N="Valeria"; L="*Stumbles onto a manual as thick as a phone book. Titled: BioX Employee Handbook* This should be it."; F="Smirk"};
        };
        {--35
            {L="*The BioX Employee Handbook, looks like it's written in the 90s with a bunch of listed fax numbers. Chapters upon chapters of procedures.*";};
            {N="Mason"; L="Guess this whole secret experimentations aren't new to them. Appears to be decades in the making.."; F="Serious"};
            {N="Valeria"; L="*Skimming through the chapters..* Chapter 8, Parasite Contamination."; F="Skeptical"};
            {N="Valeria"; L="In event of parasite contamination, 1. Hit the clean room lockdown button. 2. Remove all equipment and apparel and deposit items into the decontamination bag. 3. Remain in the isolation ward for observation for at minimum 3 days."; F="Question"};
            {N="Russell"; L="Some one probably breahced protocol there.."; F="Angry"};
            {N="Valeria"; L=`Aha, "Evacuation Procedures". In an inevitable scenario of a wildspread outbreak..`; F="Skeptical"};
            {N="Russell"; L="Inevitable?!"; F="Angry"};
        };
        {--36
            {N="Lennon"; L="They bound to know this would happen eventually. Literally happens in every Zombie-themed movies and shows."; F=""};
            {N="Valeria"; L="Employees are recommended to always evacuate eastword to the next BioX certified hospital for re-assimilation."; F="Skeptical"};
            {N="Valeria"; L="At Military checkpoints, request for a Zephernal serum for pain relief as a coded phase. If there are authorized BioX militants, they will escort you through for verification."; F="Angry"};
            {N="Valeria"; L="*Sigh* There isn't details about the second part. I don't know if I can bypass the verification."; F="Worried"};
            {N="Mason"; L="*Zipping up his duffle bag* You can always stay with us."; F="Happy"};
        };
        {--37
            {N="Valeria"; L="I'm afraid I can't do that. Rumors are the whole town's getting wiped.."; F="Disbelief"};
            {N="Valeria"; L="Just no clue how.."; F="Disbelief"};
            {N="Mason"; L="Look, they would've done so months ago if that's the case.."; F="Confident"};
            {N="Mason"; L="And there's no information that places outside Wrighton Dale is any safer."; F="Suspicious"};
            {N="Valeria"; L="Well, I still intend to find out. *Rips a few pages from the handbook and shoves it into her backpack.*"; F="Serious"};
        };
        {--38
            {N="Mason"; L="Guess this is where we part ways.. *Reaches out for a handshake*"; F="Happy"};
            {N="Valeria"; L="*Shakes hand with Mason* We'll probably meet again, and thank you guys too.."; F="Smile"};
            {N="Russell"; L="You can come by our safehouse any time."; F="Suspicious"};
            {N="Lennon"; L="I'll be guarding this door right here, if you need healing, come to me."; F="Joyful"};
            {L="*With Sector F's door unlocked, and a Corrosive monster trapped inside a sewers maintainance room, they all part ways to their own journy.*"};
        };
    };
};

return storyPackage;