type notifyTypes = "Inform" | "Positive" | "Negative" | "Reward" | "Message" | "Important";

--MARK: shared
declare shared: {
    MasterScriptInit: boolean,

    IsNan: (number) -> boolean,
    Notify: (player: Player, message: string, notifyTypes: notifyTypes) -> nil,

    modPlayers: PlayerClasses,
    modProfile: Profiles,
    modCommandsLibrary: CommandsLibrary,
    modStorage: Storages,
    modPlayerEquipment: PlayerEquipment
}

--MARK: Debugger
export type Debugger = {
    AwaitShared: (string) -> nil;
    Expire: (Instance, number?) -> nil;
    new: (ModuleScript) -> Debugger;

    Require: (self: Debugger, ModuleScript, boolean?) -> any;
    Ray: (self: Debugger, Ray, BasePart?, Vector3?, Vector3?) -> BasePart;
    Point: (self: Debugger, (CFrame | Vector3), Instance) -> Attachment;
    PointPart: (self: Debugger, (CFrame | Vector3)) -> BasePart;

    Stringify: (self: Debugger, ...any) -> string;
    StudioLog: (self: Debugger, ...any) -> nil;
    StudioWarn: (self: Debugger, ...any)  -> nil;
    Warn: (self: Debugger, ...any) -> nil;

    Debounce: (self: Debugger, string, number) -> boolean;
}

--MARK: GarbageHandler
export type GarbageHandler = {
    ClassName: string;
    Trash: {[any]:any};
    new: () -> GarbageHandler;

    Tag: (item: any) -> nil;
    Untag: (item: any) -> nil;
    Loop: (loopFunc: ((index: number, trash: any) -> boolean?) ) -> nil;
    Destruct: () -> nil;
}

--MARK: EventSignal
export type EventSignal = {
	Name: string?;
	Functions: {[number]: (...any)->(...any)};
} & {
    new: (name: string?) -> EventSignal;
    Fire: (self: EventSignal, ...any) -> nil;
    Wait: (self: EventSignal, timeOut: number?) -> ...any;
    Connect: (self: EventSignal, func: (...any) -> ...any) -> (() -> nil);
    Disconnect: (self: EventSignal, func: any) -> nil;
    Once: (self: EventSignal, func: (...any)-> ...any) -> (() -> nil);
    Destroy: (self: EventSignal) -> nil;
    DisconnectAll: (self: EventSignal) -> nil;
};

--MARK: Profiles
export type Profiles = {
    Get: (self: Profiles, player: Player) -> Profile;
    Find: (self: Profiles, playerName: string) -> Profile;
    [any]: any;
};

export type Profile = {
    Player: string;
    UserId: number;

    Garbage: GarbageHandler;

    GameSave: GameSave;
} & Profiles;


--MARK: GameSave
export type GameSave = {
    Inventory: Storage;
    Clothing: Storage;
};


--MARK: Storage
export type Storages = {
    GetPrivateStorages: (player: Player) -> {[string]: Storage};
    Get: (id: string, player: Player) -> Storage?;
    FindIdFromStorages: (siid: string, player: Player) -> (StorageItem?, Storage?);
    FindItemIdFromStorages: (itemId: string, player: Player) -> (StorageItem?, Storage?);
    ListItemIdFromStorages: (itemId: string, player: Player, storageIdSearchList: {string}) -> (
        {Item: StorageItem, Storage: Storage}, 
        number
    );
};

export type Storage = {
    Id: string;
    Name: string;
    Size: number;
    ViewOnly: boolean;

    Container: {[string]: StorageItem};

    Find: (id: string) -> StorageItem;
};

--MARK: StorageItem
export type StorageItem = {
    ID: string;
    ItemId: string;
    Player: Player;
    Library: {[string]: any};
    Values: {[string]: any};
}

--MARK: PlayerClass
export type PlayerClasses = {
    Get: (Player) -> PlayerClass;
};

export type PlayerClass = {
    Name: string;
    Character: Model;
    Humanoid: Humanoid;
    RootPart: BasePart;
    Head: BasePart;

    IsAlive: boolean;
    IsUnderWater: boolean;
    IsSwimming: boolean;

    Health: number;
    MaxHealth: number;

    MaxOxygen: number;

    CharacterModule: {[any]: any};
    Configurations: ConfigVariable;
    Properties: {[any]: any};

    LastDamageTaken: number;
    LastDamageDealt: number;
    LastArmorDamageTaken: number;
    LastHealed: number;

    LowestFps: number;
    AverageFps: number;

    IsTeleporting: boolean;
    TeleportPlaceId: number;

    Invisible: boolean;
    CurrentState: Enum.HumanoidStateType;

    OnDamageTaken: EventSignal;
    OnHealthChanged: EventSignal;
    OnIsAliveChanged: EventSignal;
    OnCharacterSpawn: EventSignal;
    Died: EventSignal;

    Spawn: (self: PlayerClass) -> nil;
    Kill: (self: PlayerClass, reason: string?) -> nil;
    GetInstance: (self: PlayerClass) -> Player;
    SetProperties: (self: PlayerClass, key: string, value: any) -> nil;
    SyncProperty: (self: PlayerClass, key: string) -> nil;
    GetCFrame: (self: PlayerClass) -> CFrame;

    GetStatus: (self: PlayerClass, statusId: string) -> StatusClass;
    SyncStatus: (self: PlayerClass, statusId: string) -> nil;
    ListStatus: (self: PlayerClass) -> {StatusClass};

    TakeDamagePackage: (self: PlayerClass, damageSource: DamageSource) -> nil;
    SetHealSource: (self: PlayerClass, srcId: string?, packet: ({[any]: any})?) -> nil;
    SetArmorSource: (self: PlayerClass, srcId: string?, packet: ({[any]: any})?) -> nil;
    RefreshHealRate: (self: PlayerClass) -> nil;

    GetEquippedTools: (self: PlayerClass) -> {ItemId: string};
    UnequipTools: (self: PlayerClass) -> nil;

    SyncIsAlive: (self: PlayerClass) -> nil;
    OnConfigurationsCalculate: (self: PlayerClass) -> nil;
    OnNotIsAlive: (self: PlayerClass, func: (character: Model)-> nil) -> nil;

    OnDeathServer: (self: PlayerClass)->nil;
    OnCharacterAdded: (character: Model)->nil;
    OnPlayerTeleport: ()->nil;
}


--MARK: StatusClass
export type StatusClass = {
    ClassName: string;
    Garbage: GarbageHandler;

    OnApply: ((self: StatusClass) -> nil);
    OnExpire: ((self: StatusClass) -> nil);
    OnTick: ((self: StatusClass) -> nil);
    OnRelay: ((self: StatusClass) -> nil);

    PlayerClass: PlayerClass?;
    NpcClass: NpcClass?;
};


--MARK: NpcClass
export type NpcClass = {
    Prefab: (Model & Actor);
};

--MARK: Interactables
export type Interactables = {
    new: (ModuleScript, Model?) -> (Interactable, InteractableMeta);
    [any]: any;
}

export type Interactable = {
    CanInteract: boolean;
    Type: string;
    [any]: any;
}

export type InteractableMeta = {
    Label: string,
    [any]: any
}

--MARK: InterfaceClass
export type InterfaceClass = {
    TouchControls: Frame;
    HintWarning: (self: InterfaceClass, label: string) -> nil;
    ToggleWindow: (self: InterfaceClass, windowName: string, visible: boolean) -> nil;
};

--MARK: CharacterClass
export type CharacterClass = {
    [any]: any;
}

--MARK: ToolHandler
export type ToolHandler = {
    ClassName: string;
    Handlers: {[string]: any};
    
    loadTypeHandler: (ModuleScript) -> any;
    getTypeHandler: (string) -> any?;
    new: () -> ToolHandler,
    Instance: (self: ToolHandler) -> any;
    Destroy: (self: ToolHandler) -> ();

    OnClientEquip: (self: ToolHandlerInstance) -> nil;
    OnClientUnequip: (self: ToolHandlerInstance) -> nil;

    OnActionEvent: (self: ToolHandlerInstance, packet: {[any]: any}) -> nil;
    OnInputEvent: (self: ToolHandlerInstance, inputData: {[any]: any}) -> nil;

    OnServerEquip: (self: ToolHandlerInstance) -> nil;
}

export type ToolHandlerInstance = {
    Binds: {[any]: any};
    Garbage: GarbageHandler;

    StorageItem: StorageItem;
    ToolPackage: {[any]: any};
    ToolAnimator: ToolAnimator;

    Prefabs: {[number]: Model};
    EquipmentClass: EquipmentClass;
}

export type ToolAnimator = {
    Play: (
        self: ToolAnimator, 
        animKey: string, 
        param: ({
            FadeTime: number?;
            PlaySpeed: number?;
            PlayLength: number?;
            PlayWeight: number?;
            [any]: any;
        })?
    ) -> AnimationTrack;
    Stop: (self: ToolAnimator,
        animKey: string,
        param: ({
            FadeTime: number?
        })?
    ) -> nil;
    GetPlaying: (self: ToolAnimator, animKey: string) -> AnimationTrack;
    GetKeysPlaying: (self: ToolAnimator, animKeys: {string}) -> {[string]: AnimationTrack};
    LoadToolAnimations: (self: ToolAnimator, animations: {[any]: any}, state: string, prefabs: {Model}) -> nil;
    GetTracks: (self: ToolAnimator, animKey: string) -> {AnimationTrack};
    ConnectMarkerSignal: (self: ToolAnimator, markerKey: string, func: ((animKey: string, track: AnimationTrack, value: any)->nil)) -> nil;
};


--MARK: ConfigVariable
export type ConfigVariable = {
    BaseValues: {[any]: any};
    FinalValues: {[any]: any};
    Modifiers: {ConfigModifier};
    GetKeyPairs: (self: ConfigVariable) -> {[any]: any};

    Calculate: (self: ConfigVariable, baseValues: {any}?, modifiers: {any}?, finalValues: {any}?) -> {any};

    GetModifier: (self: ConfigVariable, id: string) -> (number?, ConfigModifier?);
    AddModifier: (self: ConfigVariable, modifier: ConfigModifier, recalculate: boolean?) -> nil;
    RemoveModifier: (self: ConfigVariable, id: string, recalculate: boolean?) -> ConfigModifier?;

    newModifier: (id: string) -> ConfigModifier;

    [string]: any;
};

export type ConfigModifier = {
    Id: string;
    Priority: number;

    SetValues: {[any]: any};
    SumValues: {[any]: any};
    ProductValues: {[any]: any};
    MaxValues: {[any]: any};
    MinValues: {[any]: any};
};

--MARK: EquipmentClass
export type EquipmentClass = {
    Enabled: boolean;
    SetEnabled: (self: EquipmentClass, value: boolean) -> nil;

    Class: string;
    Configurations: ConfigVariable;
    Properties: {[any]: any};

    Update: (self: EquipmentClass, storageItem: StorageItem?) -> nil;
    [any]: any;
};


--MARK: CommandsLibrary
export type CommandsLibrary = {
    PermissionLevel: {
        All: number;
        ServerOwner: number;
        DevBranch: number;
        Moderator: number;
        Admin: number;
        GameTester: number;
        DevBranchFree: number;
    };

    HookChatCommand: (self: CommandsLibrary, cmd: string, cmdPacket: {
        Permission: number;
        Description: string;
        RequiredArgs: number?;
        UsageInfo: string?;
        Function: ((speaker: Player, args: {any}) -> boolean)?;
        ClientFunction: ((speaker: Player, args: {any}) -> boolean)?;
    }) -> nil;
};

--MARK: ItemModifier
export type ItemModsLibrary = {
    calculateLayer: (itemModifier: ItemModifier, upgradeKey: string) -> {[any]: any};
};

export type ItemModifier = {
    ClassName: string;
    Library: ItemModsLibrary;

    Update: (self: ItemModifierInstance) -> nil;
};

export type ItemModifierInstance = {
    Script: ModuleScript;

    Enabled: boolean;
    SetEnabled: (self: ItemModifierInstance, value: boolean) -> nil;
    
    IsAttached: boolean;

    Player: Player?;
    ModLibrary: ({any}?);
    EquipmentClass: EquipmentClass?;
    EquipmentStorageItem: StorageItem?;
    ItemModStorageItem: StorageItem?;
} & ConfigModifier;

--MARK: PlayerEquipment
export type PlayerEquipment = {
    getEquipmentClass: (siid: string, player: Player?) -> EquipmentClass;
    getToolHandler: (storageItem: StorageItem, toolModels: ({Model}?)) -> ToolHandlerInstance;

    getItemModifier: (siid: string, player: Player) -> ItemModifierInstance;
    setItemModifier: (modifierId: string, itemModifier: ItemModifierInstance, player: Player) -> nil;
};

--MARK: DamageSource
export type DamageSource = {
    Damage: number;
    TargetPart: BasePart;
    DamageType: string;
};