---
tags:
  - concept
  - rework
---
[[2.3]]
Current behavior design is based on [this](https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work).
But the old implementation may be too unintuitive.

Before:
```lua
Logic={
Root={"Or"; "RestSequence"; "IdleSequence";};
RestSequence={"And"; "ShouldRest"; "DoRest";};
IdleSequence={"And"; "PickIdleTask"; "DoIdleTask";};
}
```

- This uses abit of boolean notation, "Or", "And" to cycle through the tree nodes.
- `Root` uses a `Or` logic, if `RestSequence` returns false, the tree continues to `IdleSequence`.
- In `RestSeqeunce`, it uses a `And` logic, if `ShouldRest` returns true, it continues to `DoRest`.

At a glance, the tree table is hard to read and write. Below are ideas to improve that.

## Concept 1 BoolString Algebra

Using BoolStrings
```lua
Logic={
	Default="RestTree | IdleTree";
	RestTree="ShouldRest & [DoRest]";
	IdleTree="(PickIdleTask & [DoIdleTask]) | [TakeANap]";
}

or 

Logic={
Default="(ShouldRest & [DoRest]) | ((PickIdleTask & [DoIdleTask]) | [TakeANap])";
}
```

Nodes with `[]` are end nodes, once reached, they will stop the flow chain.

Start with Default, left to right. `RestTree` -> `ShouldRest`.
- If `ShouldRest` function returns `true` -> `[DoRest]`.
- If `false`, return to `Default` -> `IdleTree`.

`IdleTree` -> `PickIdleTask`:
- if `true` -> `[DoIdleTask]`
- if `false` -> `[TakeANap]`

Test if this design is flexible and coherent when used in a large scale brain map.

## Bandit Behavior Test

Starting off with an simple assumption that Bandits will branch off between `Alert` and `Idle`. 
They are likely mutually exclusive, which should give us the default check of `Alert or Idle`.
For `Idle`, some things a Bandit might do while idling:
- `IsHungry` -> `EatFood`
- `WantToCleanGun` -> `CleanGun`
- `TalkToBandits`
For `Alert`, seeking for a enemy, experience an anomaly, etc..
- `IsEnemyInVision` -> `HasWeapon` -> `CanFireWeapon` -> `FireWeapon`
- `IsEnemyMIA` -> `SearchEnemy`

While writing this out, even `Alert` and `Idle` needs checks.
- For bandit to be alert, it needs to  know there is an enemy.
- So now instead of `Alert or Idle`, it's more like `HasEnemyData & Alert | IsSafe & Idle`

What if we want a patrol mechanic? It's seems neither `Alert` or `Idle`. 
- Maybe a new logic tree for `Duty`. 
How about if bandit is in danger, like about to die? 
- A new tree for `Danger`.
How about bandit interaction with other bandits?
- Probably inside the `IsSafe` flow, in order for bandits to help or interact with other bandits as `Help`, `Talk`.

The flow of two NPC logic trees interacting together should probably look something like this.
**BanditA**:  `IsSafe` -> `IsBanditNearby` -> `RequestBanter` -> `WaitForRequestAccept` -> `[BanterA]`
**BanditB**: `IsSafe` -> `HasBanterRequest` -> `AcceptBanter` -> `RespondToBanter`

Priority of trees:
`Danger` > `Alert` > `Duty` > `Idle`

```lua
Logic = {
	Default = "DangerTree | AlertTree | DutyTree | IdleTree";
	
	DangerTree = "HasEnemyData & (IsLowHp & FleeTree | FightTree)";
	FleeTree = "EnemyIsInVision & (HideTree | BanditMedicTree)";
	HideTree = "HasHidingSpot & [RunToHide]";
	BanditMedicTree = "FindBanditMedic & [GoToBanditMedicForHeal]";
	FightTree = "EnemyIsInVision & FireWeaponTree | ReloadTree";
	FireWeaponTree = "CanFireWeapon & [FireAtEnemy]";
	ReloadTree = "CanReload & [ReloadWeapon]";
	
	AlertTree = "HasEnemyData & HuntTree | HealTree | AnomalyTree";
	HuntTree = "KnowEnemyExist & ShouldSearchForEnemy & [FindEnemy]";
	HealTree = "IsLowHp & BanditMedicTree";
	AnomalyTree = "HasAnomaly & [InvestigateAnomaly]";

	DutyTree = "IsOnDuty & PatrolTree";
	PatrolTree = "HasPatrolPath & [PatrolPath] | HasPostStand & [StandPost]";
	
	IdleTree = "ShouldRest & [DoRest] | HasIdleTask & [DoIdleTask]";
};

--This tree can be internally expanding into a single boolstring.
defaultBoolString = "(HasEnemyData & (IsLowHp & (EnemyIsInVision & ((HasHidingSpot & [RunToHide]) | (FindBanditMedic & [RunToBanditMedic]))) | (EnemyIsInVision & (CanFireWeapon & [FireAtEnemy]) | (CanReload & [ReloadWeapon])))) | (HasEnemyData & (KnowEnemyExist & ShouldSearchForEnemy & [FindEnemy]) | (HasAnomaly & [InvestigateAnomaly])) | (IsOnDuty & (HasPatrolPath & [PatrolPath] | HasPostStand & [StandPost])) | (ShouldRest & [DoRest] | PickIdleTask & [DoIdleTask])"
```

Conclusion:
- Quicker to write and read(not at first glance?).
- Reusable tree logic.

```lua
SurvivorCombatTree

LogicString = {
	Default = "HasEnemy & (InMeleeRange & MeleeTree | RangeTree) | [UnequipWeapon]";
	MeleeTree = "HaveMeleeAndEquip & [SwingMelee]";
	RangeTree = "HaveGunAndEquip & CanFireGun & [FireGun] | [ReloadGun]";
}


```