export type GAME_EVENT_KEY_ROTD =
    | "EventPass_OnLevelUp"
    | "EventPass_PuzzleInvoke"
    | "GameModeManager_OnDisconnectPlayer"
    | "Skills_OnResourceGatherers"
    | "Shop_OnActionEvent"
    | "WorkbenchService_OnInterfaceToggle"
    | "WorkbenchService_OnItemSelect"
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
    SkillTree: anydict;
    ItemUnlockables: anydict;
    Trader: anydict;
    Safehome: anydict;
    BattlePassSave: anydict;
    NpcTaskData: anydict;
    Faction: anydict;
}

--MARK: GameSaveRotd
export type GameSaveRotd = GameSave & {
    Wardrobe: Storage;
    Masteries: anydict;
    Blueprints: anydict;
}

--MARK: EquipmentClass
export type EquipmentClassRotd = EquipmentClass & {
};


--MARK: 