-- ========= Broken Outlaws: Fun Haybale Carry =========

Config = {}

-- Carriable models
Config.CarriableModels = {
  `p_haybale01x`,
  `p_haybale03x`,
  `p_haybale04x`
}

-- Detect radius (meters)
Config.DetectRadius = 2.0

-- Movement feel while carrying (0.0–1.0; lower = slower)
Config.MovementMultiplier = 0.75

-- Freeze while carried (reduces wobble)
Config.FreezeWhileCarried = true

-- Cleanup on disconnect/resource stop
-- Keep false if these are mapper-placed props you don’t want deleted automatically
Config.DeleteOnCleanup = false

-- Pickup / drop timing cap (you asked max ~0.5s)
Config.PickupDelayMs = 500
Config.DropDelayMs   = 500

-- Auto-delete dropped bales after X seconds (0 = disable)
Config.AutoDeleteAfterDropSeconds = 600

-- Smooth pickup / drop anims (unchanged)
Config.AnimCandidates = {
  pickup = {
    {dict="mech_carry_box",   name="pickup"},
    {dict="mech_carry_sack",  name="pickup"},
    {dict="mech_carry_crate", name="pickup"},
  },
  drop = {
    {dict="mech_carry_box",   name="putdown"},
    {dict="mech_carry_sack",  name="putdown"},
    {dict="mech_carry_crate", name="putdown"},
  }
}