# 🧑‍🌾 Broken Outlaws – Fun Hay Bale Carry (RedM / VORP) 👩‍🌾

A tiny, fun **RedM** script that lets players **pick up, carry, and drop** hay bales in the world.
Smooth pickup/drop animations, proper carry pose, sprint lock while carrying, and built-in safeties so nobody gets stuck. Optional auto-delete cleans up dropped bales after a while.

## ✨ Features

* Pick up/place down world hay bales:

  * `p_haybale01x`
  * `p_haybale03x`
  * `p_haybale04x`
* Smooth pickup & drop anims (box carry set), **mech_carry_box:idle** loop while walking
* Carry pose with per-model **hand-carry offsets** (pre-tuned)
* Blocks sprint & jump while carrying (walk only)
* Clear 3D prompts: **[G] Pick up**, **[B] Drop**
* Safety & cleanup:

  * **/dhaybale** emergency reset (drops/deletes your bale and clears anims)
  * Auto drop if you die / mount up / enter a vehicle
  * Optional **auto-delete** of dropped bales after X seconds
  * Server-side cleanup on disconnect / resource stop

## 🎮 Controls

* **G** — Pick up hay bale (nearby)
* **B** — Drop hay bale
* **/dhaybale** — Emergency: release bale + clear animations

> These use control hashes directly (no key mapping menus).
> If you remap in your framework, adjust the control checks in `client.lua`.

## ⚙️ Config (config.lua)

```lua
-- broken_outlaws_fun/config.lua

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
```

> The actual **carry offsets** (position/rotation when attached) are baked into `client.lua` for the three hay bale models (see “Tuned Offsets” below).

## 🧩 Tuned Offsets (built into client.lua)

These are hard-coded in `client.lua` under `HAND_OFFSETS`:

* **p_haybale01x** (`540874704`):
  `pos(0.200, -0.078, 0.001)` / `rot(15.0, 161.0, 90.0)`
* **p_haybale03x** (`1786194379`):
  `pos(0.300, -0.128, 0.051)` / `rot(15.0, 165.0, 115.0)`
* **p_haybale04x** (`-1520034100`):
  `pos(0.200, -0.028, 0.001)` / `rot(15.0, 165.0, 104.0)`

If you add new bale models later, extend the `HAND_OFFSETS` table.

## 📦 Installation

1. Drop the folder into your server resources as `broken_outlaws_fun/`.

2. Ensure your `fxmanifest.lua` looks like:

   ```lua
   fx_version 'cerulean'
   game 'rdr3'
   rdr3_warning 'I acknowledge this is a prerelease build of RedM.'

   name 'broken_outlaws_fun'
   author 'Broken Outlaws'
   version '1.2.0'

   shared_scripts { 'config.lua' }
   client_scripts  { 'client.lua' }
   server_scripts  { 'server.lua' }
   ```

3. Add to your server start order (e.g. `server.cfg`):

   ```
   ensure broken_outlaws_fun
   ```

## ✅ Requirements & Compatibility

* **RedM** (Cfx.re) with OneSync enabled (for networking entities)
* Works with map-placed or script-spawned props.
  ⚠️ If your hay bales are **mapper-placed and persistent**, keep `DeleteOnCleanup = false` to avoid removing map assets.
  If your bales are **script-spawned / temporary**, you can set `DeleteOnCleanup = true`.

## 🛠️ Troubleshooting

* **F8 warns: “no net object for entity”**
  Fixed already — we only request net IDs after ensuring the entity is networked.
* **Can’t move after pickup**
  The carry loop uses `mech_carry_box:idle` via native flags **31**, which allows movement. If a framework overrides movement, check other resources.
* **Prompt doesn’t show**
  Ensure the model is one of `Config.CarriableModels` and you’re within `DetectRadius`.
* **Players stuck holding a bale**
  Use **/dhaybale**. The script also auto-drops if you die, mount a horse, or enter a vehicle.

## 🔐 Commands

* `/dhaybale` — Emergency reset: release bale (delete/place per config) and clear animations.

## 📄 License

MIT — do whatever you like, just keep the original credit.

## 🙌 Credits

* Concept & tuning: **Broken Outlaws**
* Anim/pose: `mech_carry_box` set (carry loop), tuned offsets per model
* Thanks to the RedM community for natives & examples

**Description:**
Pick up, carry, and drop hay bales with smooth animations and tuned hand-carry offsets. Walk-only while carrying, clear [G]/[B] prompts, emergency `/dhaybale` reset, auto-drop/cleanup safeties, and optional timed auto-delete of dropped bales. Clean, network-safe, and mapper-friendly.
