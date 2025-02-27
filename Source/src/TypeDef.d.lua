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
    Character: Model;
    Humanoid: Humanoid;
    RootPart: BasePart;
    Head: BasePart;

    IsAlive: boolean;

    Configurations: ConfigVariable;
    Properties: {[any]: any};

    LastDamageTaken: number;
    LastDamageDealt: number;
    LastArmorDamageTaken: number;

    GetInstance: (self: PlayerClass) -> Player;
    SetProperties: (self: PlayerClass, key: string, value: any) -> nil;

    GetStatus: (self: PlayerClass, statusId: string) -> StatusClass;
    SyncStatus: (self: PlayerClass, statusId: string) -> nil;
    ListStatus: (self: PlayerClass) -> {StatusClass};

    SetHealSource: (self: PlayerClass, healId: string, packet: {[any]: any}) -> nil;
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
    Modifiers: {ItemModifierInstance};
    Calculate: (self: ConfigVariable, baseValues: {any}, modifiers: {any}, finalValues: {any}) -> {any};
};


--MARK: EquipmentClass
export type EquipmentClass = {
    Enabled: boolean;
    SetEnabled: (self: EquipmentClass, value: boolean) -> nil;

    Class: string;
    Configurations: ConfigVariable;
    Properties: {[any]: any};

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
        Function: (speaker: Player, args: {any}) -> boolean;
    }) -> nil;
};

--MARK: ItemModifier
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
};

--MARK: PlayerEquipment
export type PlayerEquipment = {
    getEquipmentClass: (siid: string, player: Player?) -> EquipmentClass;
    getToolHandler: (storageItem: StorageItem, toolModels: ({Model}?)) -> ToolHandlerInstance;

    getItemModifier: (siid: string, player: Player) -> ItemModifierInstance;
    setItemModifier: (modifierId: string, itemModifier: ItemModifierInstance, player: Player) -> nil;
};