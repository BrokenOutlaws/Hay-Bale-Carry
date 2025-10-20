-- ========= Broken Outlaws: Fun Haybale Carry =========

local carrying = false
local carriedEntity, carriedNetId = nil, nil

local CONTROL_GROUP  = 0
local CONTROL_PICKUP = 0x760A9C6F -- G
local CONTROL_DROP   = 0x4CC0E2FE -- B

local CONTROL_SPRINT = 0x8FFC75D6 -- Shift
local CONTROL_JUMP   = 0xD9D0E1C0 -- Space

local FLAG_NORMAL = 0

local function notify(msg)
  if not msg or msg == "" then return end
  local ok = pcall(function()
    TriggerEvent('chat:addMessage', { color={255,255,255}, multiline=false, args={"Broken Outlaws", msg} })
  end)
  if not ok then print(("[broken_outlaws_fun] %s"):format(msg)) end
end

local function getNetIdSafe(ent, timeoutMs)
  if not ent or ent == 0 then return nil end
  if NetworkGetEntityIsNetworked(ent) then
    local netId = NetworkGetNetworkIdFromEntity(ent)
    if netId and netId ~= 0 then return netId end
    return nil
  end
  NetworkRegisterEntityAsNetworked(ent)
  local deadline = GetGameTimer() + (timeoutMs or 600)
  while not NetworkGetEntityIsNetworked(ent) and GetGameTimer() < deadline do Wait(0) end
  if NetworkGetEntityIsNetworked(ent) then
    local netId = NetworkGetNetworkIdFromEntity(ent)
    if netId and netId ~= 0 then return netId end
  end
  return nil
end

local function ensureAnimDict(dict)
  if not dict or dict == "" then return false end
  if not HasAnimDictLoaded(dict) then
    RequestAnimDict(dict)
    local t = GetGameTimer() + 2500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(0) end
  end
  return HasAnimDictLoaded(dict)
end

local function playFirstValidAnim(ped, candidates, flags, dur)
  if not candidates or #candidates == 0 then return false end
  for _, c in ipairs(candidates) do
    if ensureAnimDict(c.dict) then
      TaskPlayAnim(ped, c.dict, c.name, 2.0, 2.0, dur or -1, flags or 0, 0.0, false, 0, false, 0, false)
      return true, c.dict, c.name
    end
  end
  return false
end

local function isPlaying(ped, dict, name)
  if not dict or not name then return false end
  return IsEntityPlayingAnim(ped, dict, name, 3)
end

local function stopAnim(ped) ClearPedTasks(ped) end

local function drawHelp3D(coords, text)
  local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
  if onScreen then
    SetTextScale(0.35, 0.35)
    SetTextColor(255, 255, 255, 230)
    SetTextCentre(true)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), x, y)
    local w = (string.len(text) / 220.0)
    DrawRect(x, y + 0.012, w, 0.03, 0, 0, 0, 140)
  end
end

local function isAllowedModel(model)
  for _, allowed in ipairs(Config.CarriableModels) do
    if model == allowed then return true end
  end
  return false
end

local function findNearestProp()
  local ped = PlayerPedId()
  local pCoords = GetEntityCoords(ped)
  local handle, obj = FindFirstObject()
  local success
  local nearest, nearestDist = nil, 9999.0
  local radius = (Config.DetectRadius or 2.0)
  repeat
    if DoesEntityExist(obj) then
      local model = GetEntityModel(obj)
      if isAllowedModel(model) and not IsEntityAttached(obj) then
        local oCoords = GetEntityCoords(obj)
        local dist = #(pCoords - oCoords)
        if dist < radius and dist < nearestDist then
          nearest, nearestDist = obj, dist
        end
      end
    end
    success, obj = FindNextObject(handle)
  until not success
  EndFindObject(handle)
  return nearest
end

local HAND_OFFSETS = {

  [1786194379]   = { pos = vector3(0.300, -0.128, 0.051), rot = vector3(15.0, 165.0, 115.0) },

  [540874704]    = { pos = vector3(0.200, -0.078, 0.001), rot = vector3(15.0, 161.0, 90.0) },

  [-1520034100]  = { pos = vector3(0.200, -0.028, 0.001), rot = vector3(15.0, 165.0, 104.0) },
}


local HAND_DEFAULT = {
  pos = vector3(0.20, -0.028, 0.001),
  rot = vector3(15.0, 175.0, 0.0),
}

local function getHandAttach(model)
  return (HAND_OFFSETS[model] or HAND_DEFAULT).pos, (HAND_OFFSETS[model] or HAND_DEFAULT).rot
end


local function attachEntityToPed(entity)
  local ped = PlayerPedId()
  local boneName = "SKEL_R_Finger12"
  local boneIndex = GetEntityBoneIndexByName(ped, boneName)
  if boneIndex == -1 then boneIndex = 60309 end

  local model = GetEntityModel(entity)
  local pos, rot = getHandAttach(model)

  if Config.FreezeWhileCarried then FreezeEntityPosition(entity, true) end
  SetEntityCollision(entity, false, false)

  AttachEntityToEntity(
    entity, ped, boneIndex,
    pos.x, pos.y, pos.z,
    rot.x, rot.y, rot.z,
    true,
    true,
    false,
    true,
    1,
    true
  )
end

local function detachToGround(entity)
  if not DoesEntityExist(entity) then return end
  DetachEntity(entity, true, true)

  local ped = PlayerPedId()
  local pCoords = GetEntityCoords(ped)
  local forward = GetEntityForwardVector(ped)
  local dropPos = pCoords + (forward * 0.9)

  local found, groundZ = GetGroundZAndNormalFor_3dCoord(dropPos.x, dropPos.y, dropPos.z + 3.0)
  if found then
    SetEntityCoords(entity, dropPos.x, dropPos.y, groundZ, false, false, false, false)
  else
    SetEntityCoords(entity, dropPos.x, dropPos.y, dropPos.z, false, false, false, false)
  end

  SetEntityCollision(entity, true, true)
  if Config.FreezeWhileCarried then FreezeEntityPosition(entity, false) end
  PlaceObjectOnGroundProperly(entity)
end

local carryDict, carryName = "mech_carry_box", "idle"
local function startCarryLoop()
  if not ensureAnimDict(carryDict) then return end
  local ped = PlayerPedId()

  Citizen.InvokeNative(0xEA47FE3719165B94, ped, carryDict, carryName, 1.0, 8.0, -1, 31, 0, 0, 0, 0)
end

CreateThread(function()
  while true do
    if carrying then
      local ped = PlayerPedId()
      if not isPlaying(ped, carryDict, carryName) then
        startCarryLoop()
      end
    end
    Wait(200)
  end
end)

CreateThread(function()
  while true do
    if carrying then
      DisableControlAction(0, CONTROL_SPRINT, true)
      DisableControlAction(0, CONTROL_JUMP,   true)
    end
    Wait(0)
  end
end)

local function tryPickup()
  if carrying then return end
  local target = findNearestProp()
  if not target then notify("No hay bale nearby."); return end

  if not NetworkGetEntityIsNetworked(target) then NetworkRegisterEntityAsNetworked(target) end
  NetworkRequestControlOfEntity(target)
  local deadline = GetGameTimer() + 1000
  while not NetworkHasControlOfEntity(target) and GetGameTimer() < deadline do Wait(0) end

  playFirstValidAnim(PlayerPedId(), Config.AnimCandidates.pickup, FLAG_NORMAL, 600)
  Wait(math.min(Config.PickupDelayMs or 500, 500))

  attachEntityToPed(target)
  carriedEntity = target
  carrying = true

  startCarryLoop()

  carriedNetId = getNetIdSafe(target, 800)
  if carriedNetId then
    TriggerServerEvent('bo_fun:setCarriedEntity', carriedNetId)
  end

  notify("Picked up hay bale.")
end

local function tryDrop(opts)
  if not carrying or not carriedEntity then return end

  local droppedNetId = nil
  if (Config.AutoDeleteAfterDropSeconds or 0) > 0 and DoesEntityExist(carriedEntity) then
    droppedNetId = getNetIdSafe(carriedEntity, 600)
  end

  playFirstValidAnim(PlayerPedId(), Config.AnimCandidates.drop, FLAG_NORMAL, 600)
  Wait(math.min(Config.DropDelayMs or 500, 500))

  stopAnim(PlayerPedId())
  detachToGround(carriedEntity)

  TriggerServerEvent('bo_fun:setCarriedEntity', nil)

  if droppedNetId then
    TriggerServerEvent('bo_fun:markDroppedForExpiry', droppedNetId)
  end

  carriedEntity, carriedNetId, carrying = nil, nil, false
  if not (opts and opts.silent) then notify("Dropped hay bale.") end
end

CreateThread(function()
  while true do
    local sleep = 200
    local ped = PlayerPedId()

    if not carrying then
      local target = findNearestProp()
      if target then
        sleep = 0
        local tCoords = GetEntityCoords(target)
        drawHelp3D(tCoords + vector3(0.0,0.0,1.0), 'Press [G] to pick up hay bale')
        if IsControlJustPressed(CONTROL_GROUP, CONTROL_PICKUP) then
          tryPickup()
          Wait(80)
        end
      end
    else
      sleep = 0
      local pCoords = GetEntityCoords(ped)
      drawHelp3D(pCoords + vector3(0.0,0.0,1.0), 'Press [B] to drop hay bale')
      if IsControlJustPressed(CONTROL_GROUP, CONTROL_DROP) then
        tryDrop()
        Wait(80)
      end

      if not DoesEntityExist(carriedEntity) then
        stopAnim(ped)
        TriggerServerEvent('bo_fun:setCarriedEntity', nil)
        carriedEntity, carriedNetId, carrying = nil, nil, false
      end

      if (Config.MovementMultiplier or 0.0) > 0.0 then
        SetPedMoveRateOverride(ped, Config.MovementMultiplier or 0.75)
      end
    end

    Wait(sleep)
  end
end)

RegisterCommand('dhaybale', function()
  local ped = PlayerPedId()
  stopAnim(ped)

  if carrying and carriedEntity and DoesEntityExist(carriedEntity) then
    if Config.DeleteOnCleanup then
      if NetworkRequestControlOfEntity(carriedEntity) then DeleteObject(carriedEntity) end
    else
      detachToGround(carriedEntity)
    end
  end

  TriggerServerEvent('bo_fun:setCarriedEntity', nil)
  carriedEntity, carriedNetId, carrying = nil, nil, false
  notify("Safety reset: animations cleared and bale released.")
end, false)

AddEventHandler('onResourceStop', function(resName)
  if resName ~= GetCurrentResourceName() then return end
  local ped = PlayerPedId()
  stopAnim(ped)

  if carrying and carriedEntity and DoesEntityExist(carriedEntity) then
    if Config.DeleteOnCleanup then
      if NetworkRequestControlOfEntity(carriedEntity) then DeleteObject(carriedEntity) end
    else
      detachToGround(carriedEntity)
    end
  end

  TriggerServerEvent('bo_fun:setCarriedEntity', nil)
  carriedEntity, carriedNetId, carrying = nil, nil, false
end)

CreateThread(function()
  while true do
    if carrying then
      local ped = PlayerPedId()
      if IsPedDeadOrDying(ped, true) or IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        tryDrop({silent=true})
      end
    end
    Wait(250)
  end
end)

RegisterNetEvent('bo_fun:cleanupNetId', function(netId, deleteFlag)
  if not netId then return end
  local ent = NetworkGetEntityFromNetworkId(netId)
  if not ent or ent == 0 then return end

  if carriedEntity and ent == carriedEntity then
    stopAnim(PlayerPedId())
    carriedEntity, carriedNetId, carrying = nil, nil, false
  end

  NetworkRequestControlOfEntity(ent)
  local deadline = GetGameTimer() + 1200
  while not NetworkHasControlOfEntity(ent) and GetGameTimer() < deadline do Wait(0) end

  if deleteFlag then
    DeleteObject(ent)
  else
    FreezeEntityPosition(ent, false)
    SetEntityCollision(ent, true, true)
    PlaceObjectOnGroundProperly(ent)
  end
end)