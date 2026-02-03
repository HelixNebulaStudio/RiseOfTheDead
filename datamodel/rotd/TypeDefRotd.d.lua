export type GAME_EVENT_KEY_ROTD =
    | "Boss_BindDefeated"
    | "Dialogue_BindMedicHeal"
    | "EventPass_BindLevelUp"
    | "EventPass_BindPuzzleInvoke"
    | "GameModeManager_BindDisconnectPlayer"
    | "GameModeManager_BindGameModeStart"
    | "GameModeManager_BindGameModeComplete"
    | "Interactables_BindCollectibleInteract"
    | "Skills_BindResourceGatherers"
    | "Shop_BindActionEvent"
    | "Survivor_BindInventoryChanged"
    | "WorkbenchService_BindInterfaceToggle"
    | "WorkbenchService_BindItemSelect"
    | "WorkbenchService_BindModEquip"
    | "WorkbenchService_BindStartBuild"
    | "WorkbenchService_BindClaimBuild"
    | "WorkbenchService_BindCheckBlueprintCost"
    | "WorkbenchService_BindItemUpgraded"
    ;

export type DAMAGE_TYPE_ROTD =
    | "Bleed"
    | "Crit"
    | "Explosive"
    | "Fire"
    | "Frost"
    | "Electric"
    | "Toxic"
    | "Thorn"
    ;

export type HUMANOID_TYPE_ROTD =
    | "Bandit"
    | "Cultist"
    | "Military"
    | "Rat"
    | "Zombie"
    ;

--MARK: ProfileRotd
export type ProfileRotd = Profile & {
    ItemUnlockables: anydict;
    Trader: anydict;
    Safehome: anydict;
    BattlePassSave: anydict;
    NpcTaskData: anydict;
    Faction: anydict;
}

--MARK: GameSaveRotd
export type GameSaveRotd = GameSave & {
    Spawn: string;
    
    Wardrobe: Storage;
    Masteries: anydict;
    Blueprints: anydict;

    -- @methods
    GetMasteries: (GameSaveRotd, itemId: string) -> number;
    SetMasteries: (GameSaveRotd, itemId: string, amount: number) -> nil;
}

--MARK: EquipmentClass
export type EquipmentClassRotd = EquipmentClass & {
};


--MARK: 