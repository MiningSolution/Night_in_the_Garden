-- UISound.lua (ReplicatedStorage, ModuleScript)
-- Single source for UI sound asset ids + one volume. Owner fills the ids later;
-- an empty string means that sound plays nothing (fails silently).
return {
    Press    = "",   -- rbxassetid://… for the button-press click; "" = silent
    Purchase = "",   -- rbxassetid://… for a confirmed purchase; "" = silent
    Volume   = 0.5,  -- one volume for all UI sounds (0..1)
}
