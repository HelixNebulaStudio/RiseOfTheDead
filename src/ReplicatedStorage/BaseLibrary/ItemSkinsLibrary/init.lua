local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ItemSkinsLibrary = {};
ItemSkinsLibrary.__index = ItemSkinsLibrary;

--== Script;
function ItemSkinsLibrary:Init(super)

    function super.GetSkinIdFromOldId(oldId)
        oldId = tostring(oldId);

        if super:Find(oldId) then
            return oldId;
        end

        for itemSkinId, itemSkinLib in pairs(super:GetAll()) do
            if itemSkinLib.OldId == nil then continue end;
            if itemSkinLib.OldId == tostring(oldId) then
                return itemSkinId;
            end
        end

        return;
    end

    function super:FindVariant(skinId, variantId)
        if skinId == nil or variantId == nil then return end;
        local lib = super:Find(skinId);

        if lib.Type == super.SkinType.Pattern then
            for _, variantLib in pairs(lib.Patterns) do
                if variantLib.Id == variantId then
                    return lib, variantLib;
                end
            end

        elseif lib.Type == super.SkinType.Texture then
            for _, variantLib in pairs(lib.Textures) do
                if variantLib.Id == variantId then
                    return lib, variantLib;
                end
            end

        end

        return lib;
    end

    for _, obj in pairs(script:WaitForChild("SurfaceAppearances"):GetChildren()) do
        obj.Parent = super.Script;
    end

    --== MARK: Pattern Skins
    super:Add{
        Id="skincamo";
        Type=super.SkinType.Pattern;
        OldId="Camo";

        Name="Camo";
        Icon="rbxassetid://17635624742";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://4386335941"; };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://4386336507"; };
            {Id="v3"; Name="Varient 3"; Image="rbxassetid://4386337276"; };
            {Id="v4"; Name="Varient 4"; Image="rbxassetid://4386480680"; };
            {Id="v5"; Name="Varient 5"; Image="rbxassetid://4386479893"; };
            {Id="v6"; Name="Varient 6"; Image="rbxassetid://4386481250"; };
        };
    };

    super:Add{
        Id="skinstreetart";
        Type=super.SkinType.Pattern;
        OldId="StreetArt";

        Name="Street Art";
        Icon="rbxassetid://4788857679";
    
        Patterns={
            {Id="v1"; Name="Jerry"; Image="rbxassetid://4610326832"; };
            {Id="v2"; Name="The Helix"; Image="rbxassetid://4611060133"; };
            {Id="v3"; Name="Genetical"; Image="rbxassetid://4611094988"; };
            {Id="v4"; Name="Wave"; Image="rbxassetid://4641413755"; };
        };
    };

    super:Add{
        Id="skinwireframe";
        Type=super.SkinType.Pattern;
        OldId="Wireframe";

        Name="Wireframe";
        Icon="rbxassetid://5065159425";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://4790500605"; };
        };
    };

    super:Add{
        Id="skinwraps";
        Type=super.SkinType.Pattern;
        OldId="Wraps";

        Name="Wraps";
        Icon="rbxassetid://5065159623";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://5065061974"; };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://5065128803"; };
            {Id="v2"; Name="Variant 3"; Image="rbxassetid://5065128031"; };
            {Id="v2"; Name="Variant 4"; Image="rbxassetid://5065127222"; };
        };
    };

    super:Add{
        Id="skinscaleplating";
        Type=super.SkinType.Pattern;
        OldId="ScalePlating";

        Name="Scale Plating";
        Icon="rbxassetid://5180744566";
    
        Patterns={
            {Id="v1"; Name="Flat"; Image="rbxassetid://18142621094"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v2"; Name="Engraved"; Image="rbxassetid://18142621388"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v3"; Name="Glow"; Image="rbxassetid://18142621636"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v4"; Name="Bevel"; Image="rbxassetid://18142621852"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v5"; Name="Rainbow"; Image="rbxassetid://5180772738"; ScaleRatio=Vector2.new(0.5, 0.5); };
        };
    };

    super:Add{
        Id="skincarbonfiber";
        Type=super.SkinType.Pattern;
        OldId="CarbonFiber";

        Name="Carbon Fiber";
        Icon="rbxassetid://5635664589";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://5635457255"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://5635675457"; ScaleRatio=Vector2.new(0.5, 0.5); };
        };
    };

    super:Add{
        Id="skinhexatiles";
        Type=super.SkinType.Pattern;
        OldId="Hexatiles";

        Name="Hexatiles";
        Icon="rbxassetid://6534859112";
    
        Patterns={
            {Id="v1"; Name="Flat"; Image="rbxassetid://18142774057"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v2"; Name="Engrave"; Image="rbxassetid://18142774245"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v3"; Name="Bevel"; Image="rbxassetid://18142774369"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v4"; Name="Glow"; Image="rbxassetid://18142774495"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v5"; Name="Rainbow"; Image="rbxassetid://6534829842"; };
        };
    };

    super:Add{
        Id="skinhalloweenpixelart";
        Type=super.SkinType.Pattern;
        OldId="HalloweenPixelArt";

        Name="Halloween Pixel Art";
        Icon="rbxassetid://7605179907";
    
        Patterns={
            {Id="v1"; Name="Pixel Skeletons"; Image="rbxassetid://7605195491"; ScaleRatio=Vector2.new(0.3, 0.3); };
            {Id="v2"; Name="Zombie Face"; Image="rbxassetid://7605205046"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v3"; Name="Possessed Jane"; Image="rbxassetid://7605214869"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v4"; Name="Pixel Ghost"; Image="rbxassetid://7605218975"; ScaleRatio=Vector2.new(0.4, 0.4); };
            {Id="v5"; Name="Cursed Cat"; Image="rbxassetid://7605222982"; ScaleRatio=Vector2.new(0.6, 0.6); };
        };
    };

    super:Add{
        Id="skinice";
        Type=super.SkinType.Pattern;
        OldId="Ice";

        Name="Ice";
        Icon="rbxassetid://8532443079";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://8532292678"; ScaleRatio=Vector2.new(4, 4); };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://8532360403"; ScaleRatio=Vector2.new(4, 4); };
            {Id="v3"; Name="Variant 3"; Image="rbxassetid://8532366520"; ScaleRatio=Vector2.new(4, 4); };
        };
    };

    super:Add{
        Id="skinwindtrails";
        Type=super.SkinType.Pattern;
        OldId="Windtrails";

        Name="Windtrails";
        Icon="rbxassetid://14250975612";
    
        Patterns={
            {Id="v1"; Name="Wind Vertical"; Image="rbxassetid://14249893630"; ScaleRatio=Vector2.new(1.5, 1); };
            {Id="v2"; Name="Wind Horizontal"; Image="rbxassetid://14249961683"; ScaleRatio=Vector2.new(1.5, 1); };
            {Id="v3"; Name="Wind 2 Right"; Image="rbxassetid://14250624431"; ScaleRatio=Vector2.new(1.5, 1); };
            {Id="v4"; Name="Wind 2 Up"; Image="rbxassetid://14250629686"; ScaleRatio=Vector2.new(1.5, 1); };
            {Id="v5"; Name="Cloud Right"; Image="rbxassetid://14250875240"; ScaleRatio=Vector2.new(1, 1);};
            {Id="v6"; Name="Cloud Left"; Image="rbxassetid://14250921231"; ScaleRatio=Vector2.new(1, 1);};
            {Id="v7"; Name="Cloud Up"; Image="rbxassetid://14250924060"; ScaleRatio=Vector2.new(1, 1);};
            {Id="v8"; Name="Cloud Down"; Image="rbxassetid://14250925805"; ScaleRatio=Vector2.new(1, 1);};
        };
    };

    super:Add{
        Id="skinxmas";
        Type=super.SkinType.Pattern;
        OldId="Xmas";

        Name="Xmas";
        Icon="rbxassetid://18142364038";
    
        Patterns={
            {Id="v1"; Name="Stripes 1"; Image="rbxassetid://4527242130"; ScaleRatio=Vector2.new(0.3, 0.3); };
            {Id="v2"; Name="Stripes 2"; Image="rbxassetid://4527242331"; ScaleRatio=Vector2.new(0.3, 0.3); };
            {Id="v3"; Name="Stars 1"; Image="rbxassetid://4527242469"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v4"; Name="Stars 2"; Image="rbxassetid://4527242591"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v5"; Name="Crystal 1"; Image="rbxassetid://4527242713"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v6"; Name="Crystal 2"; Image="rbxassetid://4527242820"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v7"; Name="Crystal 3"; Image="rbxassetid://4527259843"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v8"; Name="Crystal 4"; Image="rbxassetid://4527259963"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v9"; Name="Checkers 1"; Image="rbxassetid://4527257042"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="va"; Name="Checkers 2"; Image="rbxassetid://4527242932"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="vb"; Name="Checkers 3"; Image="rbxassetid://4527256263"; ScaleRatio=Vector2.new(0.5, 0.5); };
        };
    };

    super:Add{
        Id="skineaster";
        Type=super.SkinType.Pattern;
        OldId="EasterSkins";

        Name="Easter Skins";
        Icon="rbxassetid://4836171086";
    
        Patterns={
            {Id="v1"; Name="Egg 1"; Image="rbxassetid://4835841001"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v2"; Name="Egg 2"; Image="rbxassetid://4836204240"; ScaleRatio=Vector2.new(0.2, 0.2); };
            {Id="v3"; Name="Stripes 1"; Image="rbxassetid://4835841305"; ScaleRatio=Vector2.new(1, 1); };
            {Id="v4"; Name="Stripes 2"; Image="rbxassetid://4835841576"; ScaleRatio=Vector2.new(1, 1); };
            {Id="v5"; Name="Stripes 3"; Image="rbxassetid://4835841746"; ScaleRatio=Vector2.new(1, 1); };
        };
    };

    super:Add{
        Id="skinhalloween";
        Type=super.SkinType.Pattern;
        OldId="Halloween";

        Name="Halloween";
        Icon="rbxassetid://18142364602";
    
        Patterns={
            {Id="v1"; Name="Pumpkins"; Image="rbxassetid://5888890391"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v2"; Name="Skulls"; Image="rbxassetid://5888891774"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v3"; Name="Witch hats"; Image="rbxassetid://5888922149"; ScaleRatio=Vector2.new(0.5, 0.5); };
        };
    };

    super:Add{
        Id="skinfestivewrapping";
        Type=super.SkinType.Pattern;
        OldId="FestiveWrapping";

        Name="Festive Wrapping";
        Icon="rbxassetid://18142364818";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://6109052204"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://6109059756"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v3"; Name="Variant 3"; Image="rbxassetid://6109074464"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v4"; Name="Variant 4"; Image="rbxassetid://6109088388"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v5"; Name="Variant 5"; Image="rbxassetid://6109084797"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v6"; Name="Variant 6"; Image="rbxassetid://6109085983"; ScaleRatio=Vector2.new(0.1, 0.1); };
            {Id="v7"; Name="Variant 7"; Image="rbxassetid://6109157985"; ScaleRatio=Vector2.new(0.5, 0.5); };
            {Id="v8"; Name="Variant 8"; Image="rbxassetid://6109215107"; ScaleRatio=Vector2.new(0.2, 0.2); };
        };
    };

    super:Add{
        Id="skineaster2023";
        Type=super.SkinType.Pattern;
        OldId="Easter2023";

        Name="Easter 2023";
        Icon="rbxassetid://12963885465";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://12961909431"; };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://12961914801"; };
            {Id="v3"; Name="Variant 3"; Image="rbxassetid://12961916162"; };
        };
    };

    super:Add{
        Id="skincutebutscary";
        Type=super.SkinType.Pattern;
        OldId="CuteButScary";

        Name="Cute But Scary";
        Icon="rbxassetid://15016488348";
    
        Patterns={
            {Id="v1"; Name="Pumpkins 1"; Image="rbxassetid://15016449317"; };
            {Id="v2"; Name="Pumpkins 2"; Image="rbxassetid://15016458759"; };
            {Id="v3"; Name="Cute Skulls 1"; Image="rbxassetid://15016462697"; };
            {Id="v4"; Name="Cute Skulls 2"; Image="rbxassetid://15016466372"; };
            {Id="v5"; Name="Cute Skulls Greyscale"; Image="rbxassetid://15016503835"; };
            {Id="v6"; Name="Cute Ghosts 1"; Image="rbxassetid://15016470436"; };
            {Id="v7"; Name="Cute Ghosts 2"; Image="rbxassetid://15016474733"; };
            {Id="v8"; Name="Cute Ghosts Greyscale"; Image="rbxassetid://15016524848"; };
        };
    };

    super:Add{
        Id="skinfancy";
        Type=super.SkinType.Pattern;
        OldId="Fancy";

        Name="Fancy";
        Icon="rbxassetid://17281999442";
    
        Patterns={
            {Id="v1"; Name="Flat"; Image="rbxassetid://18142686355"; ScaleRatio=Vector2.new(2, 2); };
            {Id="v2"; Name="Engraved"; Image="rbxassetid://18142692314"; ScaleRatio=Vector2.new(2, 2); };
            {Id="v3"; Name="Glow"; Image="rbxassetid://18142697060"; ScaleRatio=Vector2.new(2, 2); };
            {Id="v4"; Name="Bevel"; Image="rbxassetid://18142697244"; ScaleRatio=Vector2.new(2, 2); };
        };
    };
    super:Add{
        Id="skinoffline";
        Type=super.SkinType.Pattern;
        OldId="Offline";

        Name="Offline";
        Icon="rbxassetid://7866873305";
    
        Patterns={
            {Id="v1"; Name="Colored Static"; Image="rbxassetid://7866772353"; };
            {Id="v2"; Name="Mono Static"; Image="rbxassetid://7866840036"; };
        };
    };
    
    --== MARK: Animated Patterns;
    super:Add{
        Id="skinpixelskeletons";
        Type=super.SkinType.Pattern;
        OldId="145";

        Name="Pixel Skeletons";
        Icon="rbxassetid://18456012800";
        Rare=true;

        OldPackId="HalloweenPixelArt";
        UnlockPack="skinhalloweenpixelart";
        SkinsListReplacable=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://7605228557"; ScaleRatio=Vector2.new(0.3, 0.3);};
        };

        PatternPreset={
            TextureAnimationId="FadeRGB";
            Scale=Vector2.new(0.3, 0.3);
        };
    };

    super:Add{
        Id="skinpixelghosts";
        Type=super.SkinType.Pattern;
        OldId="146";

        Name="Pixel Ghosts";
        Icon="rbxassetid://18456013143";
        Rare=true;
        
        OldPackId="HalloweenPixelArt";
        UnlockPack="skinhalloweenpixelart";
        SkinsListReplacable=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://7605250341"; ScaleRatio=Vector2.new(0.4, 0.4);};
        };

        PatternPreset={
            TextureAnimationId="FadeRGB";
            Scale=Vector2.new(0.4, 0.4);
        };
    };

    super:Add{
        Id="skincuteskulls";
        Type=super.SkinType.Pattern;
        OldId="195";

        Name="Cute Skulls";
        Icon="rbxassetid://18456013486";
        Rare=true;

        OldPackId="CuteButScary";
        UnlockPack="skincutebutscary";
        SkinsListReplacable=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://15016521823";};
        };

        PatternPreset={
            TextureAnimationId="FadeRGB";
        };
    };

    super:Add{
        Id="skincuteghosts";
        Type=super.SkinType.Pattern;
        OldId="199";

        Name="Cute Ghosts";
        Icon="rbxassetid://18456013933";
        Rare=true;

        OldPackId="CuteButScary";
        UnlockPack="skincutebutscary";
        SkinsListReplacable=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://15016528084";};
        };

        PatternPreset={
            TextureAnimationId="FadeRGB";
        };
    };
    
    
    --== MARK: Special Patterns;
    super:Add{
        Id="skindiamonds";
        Type=super.SkinType.Pattern;
        OldId="101";

        Name="Diamonds";
        Icon="rbxassetid://18188893834";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://2751750764"; ScaleRatio=Vector2.new(0.1, 0.1);};
        };

        PatternPreset={
            Color=Color3.fromRGB(79, 238, 255);
            Scale=Vector2.new(0.1, 0.1);
        };
    };

    super:Add{
        Id="skindeathcamo";
        Type=super.SkinType.Pattern;
        OldId="102";

        Name="Death Camo";
        Icon="rbxassetid://18188894318";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://4386399917"; };
        };
    };

    super:Add{
        Id="skincottonfade";
        Type=super.SkinType.Pattern;
        OldId="103";

        Name="Cotton Fade";
        Icon="rbxassetid://18188894651";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://4873625719"; ScaleRatio=Vector2.new(4, 4);};
        };

        PatternPreset={
            TextureAnimationId="SoftMotion";
            Scale=Vector2.new(4, 4);
        };
    };

    super:Add{
        Id="skingalaxy";
        Type=super.SkinType.Pattern;
        OldId="104";

        Name="Galaxy";
        Icon="rbxassetid://18188893351";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://8769490320"; ScaleRatio=Vector2.new(2, 2);};
        };

        PatternPreset={
            TextureAnimationId="Parallax";
            Scale=Vector2.new(2, 2);
        };
    };

    super:Add{
        Id="skinfrostivus";
        Type=super.SkinType.Pattern;
        OldId="105";

        Name="Frostivus";
        Icon="rbxassetid://18188894862";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://18467334699";}; --rbxassetid://11796319046 rbxassetid://18429493237 
        };

        PatternPreset={
            TextureAnimationId="HueShift";
        };
    };

    super:Add{
        Id="skinfortune";
        Type=super.SkinType.Pattern;
        OldId="106";

        Name="Fortune";
        Icon="rbxassetid://18188895079";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://11853778222"; ScaleRatio=Vector2.new(0.3, 0.3); };
        };

        PatternPreset={
            Scale=Vector2.new(0.3, 0.3);
        };
    };

    super:Add{
        Id="skindevtexture";
        Type=super.SkinType.Pattern;
        OldId="109";

        Name="Dev Texture";
        Icon="rbxassetid://18188895302";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://17633873288"; ScaleRatio=Vector2.new(4, 4); };
        };

        PatternPreset={
            Scale=Vector2.new(4, 4);
        };
    };

    super:Add{
        Id="skinpolaris";
        Type=super.SkinType.Pattern;

        Name="Polaris";
        Icon="rbxassetid://18467999802";
        Rare=true;
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://18469158896";};
        };

        PatternPreset={
            TextureAnimationId="HueShift";
        };
    };

    --== MARK: Texture Skins
    super:Add{
        Id="toygun";
        Type=super.SkinType.Texture;
        OldId="201";

        Name="Toy Gun";
        Icon="rbxassetid://13846887623";
    
        Textures={
            ["czevo3"]={Id="czevo3toygun"; Image="rbxassetid://5013618682"; Icon="rbxassetid://13810605651"; };
            ["desolatorheavy"]={Id="desolatorheavytoygun"; Image="rbxassetid://12929982078"; Icon="rbxassetid://13787997600"; };
        };
    };

    super:Add{
        Id="asiimov";
        Type=super.SkinType.Texture;
        OldId="202";

        Name="Asiimov";
        Icon="rbxassetid://13846887623";
    
        Textures={
            ["czevo3"]={Id="czevo3asiimov"; Image="rbxassetid://13846887623"; Icon="rbxassetid://13810605651"; };
        };
    };
    
    super:Add{
        Id="antique";
        Type=super.SkinType.Texture;
        OldId="203";

        Name="Antique";
        Icon="rbxassetid://13768313905";
    
        Textures={
            ["arelshiftcross"]={Id="arelshiftcrossantique"; Image="rbxassetid://13157322160"; Icon="rbxassetid://13768313905"; };
        };
    };
    
    super:Add{
        Id="blaze";
        Type=super.SkinType.Texture;
        OldId="204";

        Name="Blaze";
        Icon="rbxassetid://13822423304";
    
        Textures={
            ["rusty48"]={Id="rusty48blaze"; Image="rbxassetid://13822368962"; Icon="rbxassetid://13822423304"; };
            ["flamethrower"]={Id="flamethrowerblaze"; Image="rbxassetid://17229432117"; Icon="rbxassetid://17229367894"; };
        };
    };
    
    super:Add{
        Id="slaughterwoods";
        Type=super.SkinType.Texture;
        OldId="205";

        Name="Slaughter Woods";
        Icon="rbxassetid://16570530303";
    
        Textures={
            ["sr308"]={Id="sr308slaughterwoods"; Image="rbxassetid://16494491062"; Icon="rbxassetid://16570530303"; };
        };
    };
    
    super:Add{
        Id="possession";
        Type=super.SkinType.Texture;
        OldId="206";

        Name="Possession";
        Icon="rbxassetid://15007719867";
    
        Textures={
            ["vectorx"]={Id="vectorxpossession"; Image="rbxassetid://15006578225"; Icon="rbxassetid://15007719867"; };
        };
    };
    
    super:Add{
        Id="horde";
        Type=super.SkinType.Texture;
        OldId="207";

        Name="Horde";
        Icon="rbxassetid://16570534063";
    
        HasAlphaTexture=true;
        Textures={
            ["sr308"]={Id="sr308horde"; Image="rbxassetid://16570456572"; Icon="rbxassetid://16570534063"; };
        };
    };
    
    super:Add{
        Id="cryogenics";
        Type=super.SkinType.Texture;
        OldId="208";

        Name="Cryogenics";
        Icon="rbxassetid://16570534063";
    
        Textures={
            ["deagle"]={Id="deaglecryogenics"; Image="rbxassetid://17227620804"; Icon="rbxassetid://17227806515"; };
        };
    };

end

return ItemSkinsLibrary;