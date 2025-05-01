---
tags:
  - completed
  - rework
---

(stc) = Subject to change

## Concept

This picture below shows a graph with a curve, this curve represents the tweak strength, basically, peaks (in orange) are Nekronomical, and other tiers denoted with red, pink, purple and blue.

Green is where the initial roll would be, first tweak will still be rng, (So is the graph). But tweaks after that will be decided by the player, there will be options on how far left or right the player wants to tweak which will shift the green bar.

### Tweak Details

Using a single tweak point, you can tweak -3 to +3 (stc) on the direction you want. The graph is currently 300px (stc). And every time you tweak, it reveals the graph that you traversed.

There will also be the legacy option to random roll a tweak, and it will randomly select a point on the graph for you.

### Graph Details

The graph will be independent to each weapon. It guarantees a Nekronomical tier, which means all weapons can be tweaked until it’s Nekronomical.

Initially the graph will be hidden, the more you tweak, the more the graph is revealed. Sub-concept: New weaponsmith safehome NPC can help you reveal more of the graphs.

### Technicals

Since originally, tweak upgrades are generated based on the seed of the tier (Every time you roll a tweak, you get a seed that creates the entire tweak), in this rework, it would no longer be viable to use these number since they do not correlate to the graph.

### Tweak Upgrades

Thus with this rework, if you have Nekronomical, you will only get one type of upgrade. See Tweak Upgrade Region image.

Orange could be like an additional FireRate mod.  
Green could be an additional AmmoCap mod.  
Blue could be an additional Damage mod.

These will still be random and maybe a Weaponsmith NPC can do something about it.

### Pros

- More control over tweaks
    
- Interesting puzzle minigame
    
- Probably overall lower cost for Nekronomical
    
- Weapon’s tweak upgrades are no longer a separate config table (This is for me so less balancing work) and will be based on the weapon’s own mod category.
    

Cons

- Reduces rarity of Nekronomical
    
- No longer provides multi spec upgrades all together like (dmg, firerate, ammo, hs%, etc..) at the same time.
    
- It creates case for rare Nekronmical upgrades that adds unexpected mod upgrades to your weapon. E.g. Skullcracker Nekronmical upgrade for snipers(Won’t stack if you have a better skullcracker installed though)
    
- (Maybe) Adds complexity but only if you want to opt-in

### Development

Graph generation
- Requires at least 2 peeks


```lua

local function MapNum(x, inMin, inMax, outMin, outMax)
	return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end
local function lerp(a, b, t) return a * (1-t) + (b*t); end

Self.Seed = math.random(1, 99999);

local seed = Self.Seed;
local data = Self.Data;

table.clear(data);

local points = {};
local pool = {};

log("Seed", seed)
local newRng = Random.new(seed);

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
	    local j = newRng:NextInteger(1, i)
	    tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl;
end

table.insert(points, {
	X=newRng:NextNumber(0.2, 0.8);
	Y=newRng:NextInteger(1, 2) == 1 and 1 or -1;
});

local function addToPool(count, min, max)
	for a=1, count do
		table.insert(pool, newRng:NextNumber(min, max)
 * (newRng:NextInteger(1,2) == 1 and 1 or -1));
	end
end
addToPool(1, 0.7, 0.8);
addToPool(2, 0.5, 0.7);
addToPool(3, 0.3, 0.5);
addToPool(4, 0.0, 0.3);

shuffle(pool);

local lastX = 0;
local pSpacing = 1/#pool;
for a=1, #pool do
	local newX = lastX;
	table.insert(points, {
		X= newX + pSpacing;
		Y= pool[a];
	});
	lastX = newX + pSpacing;
end

table.sort(points, function(a, b) return a.X < b.X end)

table.insert(points, 1, {X=0;Y=0;});
table.insert(points, {X=1;Y=0;});

print(points)

local easingStyles = {
	Enum.EasingStyle.Quad;
	Enum.EasingStyle.Quart;
	Enum.EasingStyle.Circular;
	Enum.EasingStyle.Cubic;
}
local easingDirection = {
	Enum.EasingDirection.InOut;
}

local activeIndex = 1;
local prevPoint = points[1];
local nextPoint = points[2];

local activeStyle, activeDirection = Enum.EasingStyle.Sine, Enum.EasingDirection.Out;

for i=1, 100 do
	if i/100 > nextPoint.X then
		activeIndex = activeIndex+1;
		prevPoint = nextPoint;
		nextPoint = points[activeIndex+1];

		activeStyle = easingStyles[newRng:NextInteger(1, #easingStyles)];
		activeDirection = easingDirection[newRng:NextInteger(1, #easingDirection)]
	end

	local a = prevPoint.Y;
	local b = nextPoint.Y;
	local t = MapNum(i/100, prevPoint.X, nextPoint.X, 0, 1);
	local v = lerp(a,b,t);
	local sign = math.sign(v);
	v = TweenService:GetValue(math.abs(v),
		activeStyle, activeDirection
	)
	table.insert(data, v * sign *100);

end


local function MapNum(x, inMin, inMax, outMin, outMax)
	return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end

print(MapNum(0.75, 0, 1, 0, 2))
```