export type GAME_EVENT_KEY_ROTD =
    | "EventPass.OnLevelUp"
    | "EventPass.PuzzleInvoke"
    | "GameModeManager.DisconnectPlayer"
    | "Skills.OnResourceGatherers"
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
    | "Zombie"
    | "Bandit"
    | "Rat"
    | "Cultist"
    | "Military"
    ;

--MARK: EquipmentClass
export type EquipmentClassRotd = EquipmentClass & { 
    AddModifier: (self: EquipmentClass, modifierId: string, config: {
        BaseValues: anydict?;
        SetValues: anydict?;
        SumValues: anydict?;
        ProductValues: anydict?;
        MaxValues: anydict?;
        MinValues: anydict?;
    }) -> nil;
    
    ApplyModifiers: (self: EquipmentClass, storageItem: StorageItem) -> nil;
    ProcessModifiers: (self: EquipmentClass, processType: string, ...any) -> nil;
    GetClassAsModifier: (self: EquipmentClass, siid: string, configModifier: ConfigModifier?) -> ConfigModifier;

    [any]: any;
};
