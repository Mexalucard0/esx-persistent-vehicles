ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local PV = {
  vehicles = {},
  waiting = 0,
  debugging = Config.debug,
}

-- events
RegisterServerEvent('persistent-vehicles/register-vehicle')
AddEventHandler('persistent-vehicles/register-vehicle', function (plate)
  if not GetInvokingResource() then return end
  PV.RegisterVehicle(ESX.Math.Trim(plate))
end)

RegisterServerEvent('persistent-vehicles/forget-vehicle')
AddEventHandler('persistent-vehicles/forget-vehicle', function (plate)
  if not GetInvokingResource() then return end
  PV.ForgetVehicle(ESX.Math.Trim(plate))
end)

RegisterServerEvent('persistent-vehicles/done-spawning')
AddEventHandler('persistent-vehicles/done-spawning', function ()
  PV.waiting = PV.waiting - 1
  if PV.debugging then
    local _source = source
    print('Persistent Vehicles: Server received client spawn confirmation from:', _source)
  end
end)

RegisterServerEvent('persistent-vehicles/save-vehicles-to-file')
AddEventHandler('persistent-vehicles/save-vehicles-to-file', function ()
  PV.SavedPlayerVehiclesToFile()
  print('Persistent Vehicles: All vehicles saved to file')
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= GetCurrentResourceName() then return end
  if Config.populateOnReboot then
    PV.SavedPlayerVehiclesToFile()
  end
end)


-- commands
RegisterCommand('pv-cull', function (source, args, rawCommand)
  if tonumber(source) > 0 then return end
  PV.CullVehicles(args[1])
  print('Persistent Vehicles: Culled:', args[1] or 10)
end, true)

RegisterCommand('pv-forget-all', function (source, args, rawCommand)
  if tonumber(source) > 0 then return end
  PV.ForgetAllVehicles()
end, true)

RegisterCommand('pv-save-to-file', function (source, args, rawCommand)
  if tonumber(source) > 0 then return end
  PV.SavedPlayerVehiclesToFile()
end, true)

RegisterCommand('pv-toggle-debugging', function (source, args, rawCommand)
  if tonumber(source) > 0 then return end
  PV.debugging = not PV.debugging
end, true)

RegisterCommand('pv-shutdown', function (source, args, rawCommand)
  if tonumber(source) > 0 then return end
  for i = GetNumResources(), 1, -1 do
      local resource = GetResourceByFindIndex(i)
      StopResource(resource)
  end
end, true)

local total = 0
RegisterCommand('pv-spawn-test', function (source, args, rawCommand)
  local xPlayer = ESX.GetPlayerFromId(source)
  local group = xPlayer.getGroup()
  if group ~= 'admin' and group ~= 'superadmin' then return end
  local num = args[1] or 1
  for i = 1, tonumber(num) do
    Wait(0) 
    local plate = tostring(total)
      TriggerClientEvent('persistent-vehicles/test-spawn', source, plate)
      PV.RegisterVehicle(plate)
      total = total + 1
  end
end, true)

-- global functions
if Config.populateOnReboot then
  local SavedPlayerVehicles = LoadResourceFile(GetCurrentResourceName(), "vehicle-data.json")
  if SavedPlayerVehicles ~= '' then
      PV.vehicles = json.decode(SavedPlayerVehicles)
      if not PV.vehicles then
          PV.vehicles = {}
      end
      if PV.debugging then
          print('Persistent Vehicles: Loaded Vehicles from file: ', PV.TableLength(PV.vehicles))
      end
  end
end

function PV.SavedPlayerVehiclesToFile()
  SaveResourceFile(GetCurrentResourceName(), "vehicle-data.json", json.encode(PV.vehicles), -1)
  if PV.debugging then
    print('Persistent Vehicles: Saved Vehicles to file: ', #PV.vehicles)
  end
end

function PV.GetVehicleIfExists(plate)
  local vehicles = GetAllVehicles()
  for i = 1, #vehicles do
    if ESX.Math.Trim(GetVehicleNumberPlateText(vehicles[i])) == plate then
      return vehicles[i]
    end
  end
  return false
end

function PV.DistanceFrom(x1, y1, z1, x2, y2, z2) 
  return  math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

function PV.GetClosestPlayerToCoords(coords)

  local players = ESX.GetPlayers()

  if #players == 0 then return end

  local closestDist, closestPlayerId

  for i = 1, #players do

    local playerCoords = GetEntityCoords(GetPlayerPed(players[i]))

    local dist = PV.DistanceFrom(coords.x, coords.y, coords.z, playerCoords.x, playerCoords.y, playerCoords.z)
    
    if not closestDist or dist <= closestDist then
        closestDist = dist
        closestPlayerId = players[i]
    end
  end
  return closestPlayerId, closestDist
end

function PV.RegisterVehicle(plate)
  if PV.vehicles[plate] ~= nil then return end

  if PV.Tablelength(PV.vehicles) > 90 then
    PV.CullVehicles(1)
  end

  -- don't register the vehicle immediately incase it is deleted straight away
  Citizen.SetTimeout(3000, function ()
    local vehicle = PV.GetVehicleIfExists(plate)
    if not vehicle then return end
    local color1, color2 = GetVehicleColours(vehicle)
    PV.vehicles[plate] = {vehicle = vehicle, props = json.encode({  color1 = color1, color2 = color2, plate = plate, model = GetEntityModel(vehicle)})}
    if PV.debugging then
      print('Persistent Vehicles: Registered Vehicle', plate, vehicle)
    end
  end)
end

function PV.Tablelength(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

function PV.ForgetVehicle(plate)
  plate = ESX.Math.Trim(tostring(plate))
  if not plate then return end
  PV.vehicles[plate] = nil
  if PV.debugging then
    print('Persistent Vehicles: Forgotten Vehicle', plate)
  end
end

function PV.CullVehicles(amount)
  local num = amount or 10
  for key, value in pairs(PV.vehicles) do
    PV.ForgetVehicle(key)
    num = num - 1
    if num == 0 then
      break
    end
  end
  if PV.debugging then
    print('Persistent Vehicles: Culled vehicles', num)
  end
end

function PV.ForgetAllVehicles()
  PV.vehicles = {}
  PV.SavedPlayerVehiclesToFile()
  if PV.debugging then
    print('Persistent Vehicles: Forgot all vehicles. No vehicles are now persistent.')
  end
end

-- main thread
Citizen.CreateThread(function ()

  -- main loop
  while true do

    local players
    local requests = {}

    -- sleep this thread if there are no players online
    repeat
      Citizen.Wait(Config.runEvery * 1000)
      players = ESX.GetPlayers()
    until #players > 0 and DoesEntityExist(GetPlayerPed(players[1])) and Config.enabled
    
    for plate, data in pairs(PV.vehicles) do

      if (not data.entity or not DoesEntityExist(data.entity)) and not data.nextTick then
        Citizen.Wait(0)
        data.entity = PV.GetVehicleIfExists(plate) -- we gate this call as it's expensive
      end

      -- data.entity is an invlaid entity id, create respawn request for this vehicle
      if not data.entity then

        -- we need props and coords to be able to respawn the vehicle. If for whatever reason we don't then we'll have to forget this vehicle
        if not data.props or not data.pos then
          PV.ForgetVehicle(plate)
        else

          -- get the client which is currently closest to this vehicle
          local closestPlayerId, closestDistance = PV.GetClosestPlayerToCoords(data.pos)

          -- only spawn the vehicle if a client is close enough
          if closestPlayerId ~= nil and closestDistance < 500 then
            
            data.nextTick = nil
            
            table.insert(requests, function (cb)
              MySQL.Async.fetchAll('SELECT '..Config.db.col..' FROM '..Config.db.table..' WHERE `plate` = @plate', {
                ['@plate'] = plate,
              }, function (props)
                -- we'll set the current vehicle props if it's a player owned vehicle, otherwise the props we already have will suffice.
                if props[1] ~= nil then
                  data.props = props[1].vehicle -- note: this is/should be a json string, but we'll decode it on the client as we don't need to use it server side.
                end
                data.closestPlayer = closestPlayerId -- send along the closest player so we know which client to spawn it on
                return cb(data)
              end)
            end)

          else -- if all clients are out of range try again next loop, but with this bool we'll cheapen the next loop by not attempting to see if this vehicle exists
            data.nextTick = true
          end

        end

      else -- data.entity is a valid entity id so update its postion and condition
        
        local coords =  GetEntityCoords(data.entity)
        local rot = GetEntityRotation(data.entity)
        
        data.pos = {
          x = coords.x,
          y = coords.y,
          z = coords.z,
          h = GetEntityHeading(data.entity),
          r = { x = rot.x, y = rot.y, z = rot.z }
        }
        data.cond = {
          locked = GetVehicleDoorLockStatus(data.entity),
          --engineHealth = GetVehicleEngineHealth(data.entity), -- not working properly atm
          bodyHealth = GetVehicleBodyHealth(data.entity), 
          tankHealth = tonumber(GetVehiclePetrolTankHealth(data.entity)),
          --dirtLevel = GetVehicleDirtLevel(data.entity), -- not working properly atm
          fuelLevel = 25 -- maybe GetVehicleFuelLevel() will be implemented server side one day?
        }
      end

    end -- /for

    -- consume any respawn requests we have
    if #requests > 0 then
      -- run the mysql requests in parallel and await the result, blocking the thread.
      local mysqlTime = os.clock()
      local p, results = promise.new(), {}
      Async.parallel(requests, function (res)
        results = res
        p:resolve()
      end)
      Citizen.Await(p)

      if PV.debugging then
        print('Persistent Vehicles: MySQL Query time taken: ', os.clock() - mysqlTime, 'seconds')
      end
      
      if #results > 0 then
          
        local payloads = {}
        for i = 1, #results do
          local item = results[i]
          if payloads[item.closestPlayer] == nil then
            payloads[item.closestPlayer] = {}
          end
          table.insert(payloads[item.closestPlayer], item)
          item.closestPlayer = nil
        end
        
        for id, payload in pairs(payloads) do
          if DoesEntityExist(GetPlayerPed(id)) then
            TriggerClientEvent('persistent-vehicles/spawn-vehicles', id, payload)
            PV.waiting = PV.waiting + 1
            if PV.debugging then
              print('Persistent Vehicles: Sent', #payload, ' vehicles to client', id, 'for spawning.')
            end
          end
        end

        -- wait for the clients to report that they've finished spawning
        local waited = 0
        repeat
          Citizen.Wait(100)
          waited = waited + 1

          if PV.debugging and waited == 50 then
            print('Persistent Vehicles: Waited too long for the clients to respawn vehicles')
          end

        until PV.waiting == 0 or waited == 50
      
      end

    end

  end
end)



