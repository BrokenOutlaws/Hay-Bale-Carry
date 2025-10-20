-- ========= Broken Outlaws: Fun Haybale Carry =========

local carriedByPlayer = {}
local expiryByNetId   = {}

local function askClientsToCleanup(netId, deleteFlag)
  if not netId then return end
  TriggerClientEvent('bo_fun:cleanupNetId', -1, netId, deleteFlag and true or false)
end

RegisterNetEvent('bo_fun:setCarriedEntity', function(netId)
  local src = source
  if netId then
    carriedByPlayer[src] = netId

    expiryByNetId[netId] = nil
  else
    carriedByPlayer[src] = nil
  end
end)

RegisterNetEvent('bo_fun:markDroppedForExpiry', function(netId)
  if not netId or netId == 0 then return end
  local seconds = 0
  if type(Config) == 'table' and type(Config.AutoDeleteAfterDropSeconds) == 'number' then
    seconds = Config.AutoDeleteAfterDropSeconds
  end
  if seconds <= 0 then return end
  expiryByNetId[netId] = os.time() + seconds
end)

AddEventHandler('playerDropped', function(_reason)
  local src = source
  local netId = carriedByPlayer[src]
  if netId then
    carriedByPlayer[src] = nil
    local deleteFlag = (type(Config) == 'table' and Config.DeleteOnCleanup == true)
    askClientsToCleanup(netId, deleteFlag)

    expiryByNetId[netId] = nil
  end
end)

AddEventHandler('onResourceStop', function(resName)
  if resName ~= GetCurrentResourceName() then return end
  local deleteFlag = (type(Config) == 'table' and Config.DeleteOnCleanup == true)

  for _, netId in pairs(carriedByPlayer) do
    askClientsToCleanup(netId, deleteFlag)
  end
  carriedByPlayer = {}

  for netId, _ in pairs(expiryByNetId) do
    askClientsToCleanup(netId, true)
  end
  expiryByNetId = {}
end)

CreateThread(function()
  while true do
    local now = os.time()
    for netId, t in pairs(expiryByNetId) do
      if now >= t then

        askClientsToCleanup(netId, true)
        expiryByNetId[netId] = nil
      end
    end
    Wait(30000)
  end
end)