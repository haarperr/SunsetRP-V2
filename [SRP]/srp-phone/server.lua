Citizen.CreateThread(function()
    Citizen.Wait(2000)
    print('[srp-phone]: AUTHORIZED')
end)

Citizen.CreateThread(function()
    TriggerEvent('deleteAllTweets')
    TriggerEvent('deleteAllYP')
end)
PlayerTable = {}
local callID = nil

--[[ Twitter Stuff ]]
RegisterNetEvent('GetTweets')
AddEventHandler('GetTweets', function(onePlayer)
    local source = source
    exports.ghmattimysql:execute('SELECT * FROM (SELECT * FROM tweets ORDER BY `time` DESC LIMIT 50) sub ORDER BY time ASC', {}, function(tweets) -- Get most recent 100 tweets
        if onePlayer then
            TriggerClientEvent('Client:UpdateTweets', source, tweets)
        else
            TriggerClientEvent('Client:UpdateTweets', source, tweets)
        end
    end)
end)

RegisterServerEvent('ReturnHouseKeys')
AddEventHandler('ReturnHouseKeys', function(cid)
    local src = source
    local houses = {}
    local shared = {}
    exports.ghmattimysql:execute("SELECT * FROM __housedata WHERE cid= ?", {cid}, function(chicken)
        for k, v in pairs(chicken) do
            if v ~= nil then
                if v.housename ~= nil then
                    local random = math.random(1111,9999)
                    houses[random] = {}
                    table.insert(houses[random], {["house_name"] = v.housename, ["house_model"] = v.house_model, ["house_id"] = v.house_id})
                    TriggerClientEvent('returnPlayerKeys', src, houses)
                end
            end
        end
    end)
    exports.ghmattimysql:execute('SELECT * FROM __housekeys WHERE `cid`= ?', {cid}, function(returnData)
        for k, v in pairs(returnData) do
            if v ~= nil then
                if v.housename ~= nil then
                    local random = math.random(1111,9999)
                    shared[random] = {}
                    table.insert(shared[random], {["house_name"] = v.housename, ["house_model"] = v.house_model, ["house_id"] = v.house_id})
                    TriggerClientEvent('returnPlayerKeys', src, {}, shared)
                end
            end
        end
    end)
end)

RegisterServerEvent('OnHold:Server')
AddEventHandler('OnHold:Server', function(srcPlayer,toggle)
    TriggerClientEvent('OnHold:Client', srcPlayer, toggle, srcPlayer)
end)

RegisterNetEvent('group:pullinformation')
AddEventHandler('group:pullinformation', function(gId)
    local groupId = tonumber(gId)
    local src = source

    local jobBankPromise = promise:new()
    local jobLogData = promise:new()

    exports.ghmattimysql:execute('SELECT `bank` FROM __job_accounts WHERE `id`= ?', {groupId}, function(data)
        jobBankPromise:resolve(data)
    end)

    exports.ghmattimysql:execute('SELECT `cid`, `giver`, `rank`, `name` FROM __employees WHERE `business_id`= ?', {groupId}, function(data)
        jobLogData:resolve(data)
    end)

    local jobBank = Citizen.Await(jobBankPromise)
    local jobLog = Citizen.Await(jobLogData)
    TriggerClientEvent('group:fullList', src, jobLog, jobBank[1].bank, groupId)

end)

RegisterServerEvent('server:givepass')
AddEventHandler('server:givepass', function(gangid,newrank,cid)
    local src = source
    local groupId = tonumber(gangid)
    local p = promise:new()
    exports.ghmattimysql:execute('SELECT name from __job_accounts WHERE id = ?', {groupId}, function(data)
        p:resolve(data)
    end)
    local pCurrent = Citizen.Await(p)
    local steam = GetPlayerIdentifiers(src)[1]
    local userData = promise:new()

    exports.ghmattimysql:execute('SELECT uid FROM __users WHERE steam = ?', {steam}, function(data)
        userData:resolve(data)
    end)

    local uid = Citizen.Await(userData)
    local user = exports['srp-base']:getModule("Player")
    local char = user:getCurrentCharacter(uid[1].uid)
    local target, index = user:getCharacterFromCid(tonumber(cid))
    local name = char.first_name .. " " .. char.last_name
    local targetname = target.first_name .. " " .. target.last_name
    if tonumber(newrank) == 0 then
        exports.ghmattimysql:execute('UPDATE __characters SET `job`= ?, `rank`= ? WHERE `id`= ?', {"None", newrank, cid})
        TriggerClientEvent('srp-base:updateJob', target.playerSrc, "None", newrank)
        exports.ghmattimysql:execute('INSERT INTO __employees(`cid`, `giver`, `rank`, `name`, `business_id`) VALUES(?, ?, ?, ?, ?)', {cid, name, newrank, targetname, groupId})
    else
        exports.ghmattimysql:execute('UPDATE __characters SET `job`= ?, `rank`= ? WHERE `id`= ?', {pCurrent[1].name, newrank, cid})
        TriggerClientEvent('srp-base:updateJob', target.playerSrc, pCurrent[1].name, newrank)
        exports.ghmattimysql:execute('INSERT INTO __employees(`cid`, `giver`, `rank`, `name`, `business_id`) VALUES(?, ?, ?, ?, ?)', {cid, name, newrank, targetname, groupId})
    end
end)

RegisterNetEvent('server:gankGroup')
AddEventHandler('server:gankGroup', function(gangid, cashamount, pId)
    local src = source
    local groupId = tonumber(gangid)
    local cId = tonumber(pId)
    local depoAmount = tonumber(cashamount)

    local jobBankPromise = promise:new()
    local playerBankPromise = promise:new()

    exports.ghmattimysql:execute('SELECT bank from __job_accounts WHERE id = ?', {groupId}, function(data)
        jobBankPromise:resolve(data)
    end)

    exports.ghmattimysql:execute('SELECT bank, id from __characters WHERE id = ?', {cId}, function(data)
        playerBankPromise:resolve(data)
    end)

    local pCurrentBank = Citizen.Await(playerBankPromise)
    local jCurrentBank = Citizen.Await(jobBankPromise)

    local pCitizenId = pCurrentBank[1].id
    local pDepoAmount = pCurrentBank[1].bank - depoAmount
    local jDepoAmount = jCurrentBank[1].bank + depoAmount

    TriggerEvent('srp-base:updateCharacterBank', pDepoAmount, pCitizenId, false, depoAmount)

    exports.ghmattimysql:execute('UPDATE __job_accounts SET bank = ? WHERE id = ?', {jDepoAmount, groupId})
    exports.ghmattimysql:execute('UPDATE __characters SET bank = ? WHERE id = ?', {pDepoAmount, cId})
end)

RegisterNetEvent('server:givepayGroup')
AddEventHandler('server:givepayGroup', function(gangid, cashamount, cid)
    local src = source
    local groupId = tonumber(gangid)
    local cId = tonumber(cid)
    local depoAmount = tonumber(cashamount)

    local jobBankPromise = promise:new()
    local playerBankPromise = promise:new()

    exports.ghmattimysql:execute('SELECT bank from __job_accounts WHERE id = ?', {groupId}, function(data)
        jobBankPromise:resolve(data)
    end)

    exports.ghmattimysql:execute('SELECT bank from __characters WHERE id = ?', {cId}, function(data)
        playerBankPromise:resolve(data)
    end)

    
    local pCurrentBank = Citizen.Await(playerBankPromise)
    local jCurrentBank = Citizen.Await(jobBankPromise)

    local pDepoAmount = pCurrentBank[1].bank + depoAmount
    local jDepoAmount = jCurrentBank[1].bank - depoAmount

    TriggerEvent('srp-base:updateCharacterBank', pDepoAmount, cId, true, depoAmount)

    exports.ghmattimysql:execute('UPDATE __job_accounts SET bank = ? WHERE id = ?', {jDepoAmount, groupId})
    exports.ghmattimysql:execute('UPDATE __characters SET bank = ? WHERE id = ?', {pDepoAmount, cId})


end)

-- RegisterServerEvent('srp-phone:restart')
-- AddEventHandler('srp-phone:restart', function()
--     local sourcePlayer = tonumber(source)
--     local identifier = getPlayerID(source)
--     local xPlayer = SRPCore.GetPlayerFromId(source)
--     local cid = xPlayer 
--     getOrGeneratePhoneNumber(sourcePlayer, identifier, function (myPhoneNumber)
-- 		getContacts(cid, myPhoneNumber)
-- 		TriggerEvent("phone:getSMS")
--     end)
-- end)

RegisterNetEvent('Tweet')
AddEventHandler('Tweet', function(handle, data, time)
    local handle = handle
    local src = source

    exports.ghmattimysql:execute('INSERT INTO tweets (handle, message, time) VALUES (@handle, @message, @time)', {
        ['handle'] = handle,
        ['message'] = data,
        ['time'] = time
    }, function(result)
        TriggerClientEvent('Client:UpdateTweet', -1, data, handle)
        TriggerEvent('GetTweets', true, src)
    end)
end)

--[[ Set Duty Stuff]]

RegisterServerEvent('duty:onoff')
AddEventHandler("duty:onoff", function(id, name, rank)
    local source = source
    if name == "LSPD" then
        TriggerClientEvent('duty:police', source)
        TriggerClientEvent("DoLongHudText", source, "Placed Off-Duty")
    elseif name == "EMS" then
        TriggerClientEvent('duty:ambulance', source)
        TriggerClientEvent("DoLongHudText", source, "Placed Off-Duty")
    elseif name == "Off-Duty" then
        TriggerClientEvent("DoLongHudText", source, "You must clock back On-Duty at your place of work", 2)
    end
end)

--[[ Contacts stuff ]]

RegisterNetEvent('phone:addContact')
AddEventHandler('phone:addContact', function(cid, name, number)
    -- local handle = handle
    -- local src = source
    -- local xPlayer = SRPCore.GetPlayerFromId(source)

    local src = source
    if number >= 6289999999 then return end 
    saveContact(cid,name,number)
    TriggerClientEvent('phone:newContact', src,name,number)
end)

function saveContact(identifier,name,number)
    local src = source
    exports.ghmattimysql:execute('INSERT INTO phone_contacts (identifier, name, number) VALUES (@identifier, @name, @number)', {
            ['identifier'] = identifier,
            ['name'] = name,
            ['number'] = number
        }, function(result)
            TriggerClientEvent('refreshContacts', src)
        end)
end

RegisterNetEvent('getContacts')
AddEventHandler('getContacts', function(cid)
    local src = source
    if (cid == nil) then 
     TriggerClientEvent('phone:loadContacts', src, json.encode({}))
    else 
     local contacts = getContacts(cid, function(contacts)
         if (contacts) then 
             TriggerClientEvent('phone:loadContacts', src,contacts)
         else 
             TriggerClientEvent('phone:loadContacts', src, {})
         end
        end)
    end
end)

function getContacts(identifier, callback)
    local src = source
    exports.ghmattimysql:execute('SELECT * FROM phone_contacts WHERE identifier = @identifier', { ['identifier'] = identifier
    }, function(result) callback(result) end)
end 

RegisterNetEvent('deleteContact')
AddEventHandler('deleteContact', function(cid, name, number)
    local src = source 
     removeContact(cid,name,number)
     TriggerClientEvent('phone:deleteContact', src,name,number)
end)

--[[ Phone calling stuff ]]

RegisterServerEvent('garages:CheckGarageForVeh')
AddEventHandler('garages:CheckGarageForVeh', function(cid)
	local source = source
    local vehicules = {}

    exports.ghmattimysql:execute("SELECT * FROM __vehicles WHERE cid=@identifier",{['identifier'] = cid}, function(data) 
        for _,v in pairs(data) do
            local vehicle = json.decode(v.vehicle)
			table.insert(vehicules, {vehicle = vehicle, plate = v.plate, garage = v.garage, finance = v.finance, amount_due = v.amount_due, last_payment = v.last_payment})
		end
		TriggerClientEvent('phone:Garage', source, vehicules)
	end)
end)

function removeContact(identifier,name,number)
    local src = source 
    exports.ghmattimysql:execute('DELETE FROM phone_contacts WHERE identifier = @identifier AND name = @name AND number = @number LIMIT 1', {
            ['identifier'] = identifier,
            ['name'] = name,
            ['number'] = number
        }, function (result)
        end)
end

function getNumberPhone(identifier)
    local p = promise:new()
    exports.ghmattimysql:execute("SELECT phone_number FROM __characters WHERE id = @identifier", {['identifier'] = identifier}, function(result)
        local fuck = result[1].phone_number
        p:resolve(fuck)
    end)
    local penis = Citizen.Await(p)
    return penis
end
function getIdentifierByPhoneNumber(phone_number)
    local p = promise:new() 
    exports.ghmattimysql:execute("SELECT uid FROM __characters WHERE phone_number = @phone_number", {['phone_number'] = phone_number}, function(result)
        if result[1] ~= nil then
            exports.ghmattimysql:execute('SELECT steam FROM __users WHERE uid= ?', {result[1].uid}, function(data)
                if data[1] ~= nil then
                    p:resolve(data[1].steam)
                end
            end)
        end
    end)
    local penis = Citizen.Await(p)
    return penis
end

RegisterNetEvent('phone:callContact')
AddEventHandler('phone:callContact', function(cid, targetnumber, toggle)
    local src = source
    local playerID = nil
    local targetIdentifier = getIdentifierByPhoneNumber(targetnumber)
    local xPlayers = GetPlayers()
    local p = promise:new()
    exports.ghmattimysql:execute("SELECT phone_number FROM __characters WHERE id = @identifier", {['identifier'] = cid}, function(result)
        local srcPhone = result[1].phone_number
        p:resolve(srcPhone)
    end)
    local sourcePhone = Citizen.Await(p)

    TriggerClientEvent('phone:initiateCall', src, src)
        
    for _, playerId in ipairs(xPlayers) do
        if playerId ~= src then
            local xTarget = GetPlayerIdentifiers(playerId)[1]
            if xTarget then
                if xTarget == targetIdentifier then
                    playerID = playerId
                    break
                else
                    
                end
            end
        end
    end
    if playerID == nil then

    else
        TriggerClientEvent('phone:receiveCall', playerID, targetnumber, src, sourcePhone)
    end
end)

RegisterNetEvent('phone:getSMS')
AddEventHandler('phone:getSMS', function(cid)
    local src = source
    exports.ghmattimysql:execute("SELECT phone_number FROM __characters WHERE id = @identifier", {['identifier'] = cid}, function(result)
        local mynumber = result[1].phone_number
        
        exports.ghmattimysql:execute("SELECT * FROM phone_messages WHERE receiver = @mynumber OR sender = @mynumber ORDER BY id DESC", {['mynumber'] = mynumber}, function(result)

            local numbers ={}
            local convos = {}
            local valid
            
            for k, v in pairs(result) do
                valid = true
                if v.sender == mynumber then
                    for i=1, #numbers, 1 do
                        if v.receiver == numbers[i] then
                            valid = false
                        end
                    end
                    if valid then
                        table.insert(numbers, v.receiver)
                    end
                elseif v.receiver == mynumber then
                    for i=1, #numbers, 1 do
                        if v.sender == numbers[i] then
                            valid = false
                        end
                    end
                    if valid then
                        table.insert(numbers, v.sender)
                    end
                end
            end
            
            for i, j in pairs(numbers) do
                for g, f in pairs(result) do
                    if j == f.sender or j == f.receiver then
                        table.insert(convos, {
                            id = f.id,
                            sender = f.sender,
                            receiver = f.receiver,
                            message = f.message,
                            date = f.date
                        })
                        break
                    end
                end
            end
        
            local data = ReverseTable(convos)
            TriggerClientEvent('phone:loadSMS', src, data, mynumber)
        end)
    end)
end)

function ReverseTable(t)
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

RegisterNetEvent('phone:sendSMS')
AddEventHandler('phone:sendSMS', function(cid, receiver, message)
    local src = source
    
    local target = getIdentifierByPhoneNumber(receiver)
    exports.ghmattimysql:execute("SELECT phone_number FROM __characters WHERE id = @identifier", {['identifier'] = cid}, function(result)
        if result[1] ~= nil then
            exports.ghmattimysql:execute('INSERT INTO phone_messages (sender, receiver, message) VALUES(?, ?, ?)', {result[1].phone_number, receiver, message})
        end
    end)
    local mynumber = getNumberPhone(cid)
    local xPlayers = GetPlayers()
    --if receiver ~= mynumber then
    for _,playerId in ipairs(xPlayers) do
        local xPlayer = GetPlayerIdentifiers(playerId)[1]
        if xPlayer then
            if xPlayer == target then
                local receiverID = playerId
                -- TriggerClientEvent('phone:newSMS', receiverID, 1, tonumber(mynumber), message, os.time())
                TriggerClientEvent('phone:newSMS', receiverID, 1, mynumber,  message, os.time())
            end
        end
    end

end)

RegisterNetEvent('phone:serverGetMessagesBetweenParties')
AddEventHandler('phone:serverGetMessagesBetweenParties', function(cid, sender, receiver, displayName)
    local src = source
    exports.ghmattimysql:execute("SELECT phone_number FROM __characters WHERE id = @identifier", {['identifier'] = cid}, function(result)
        local mynumber = result[1].phone_number
        exports.ghmattimysql:execute("SELECT * FROM phone_messages WHERE (sender = @sender AND receiver = @receiver) OR (sender = @receiver AND receiver = @sender) ORDER BY id ASC", {['sender'] = sender, ['receiver'] = receiver}, function(data)
            TriggerClientEvent('phone:clientGetMessagesBetweenParties', src, data, displayName, mynumber)
        end)
    end)
end)

RegisterNetEvent('phone:StartCallConfirmed')
AddEventHandler('phone:StartCallConfirmed', function(mySourceID)
    local channel = math.random(10000, 99999)
    local src = source

    TriggerClientEvent('phone:callFullyInitiated', mySourceID, mySourceID, src)
    TriggerClientEvent('phone:callFullyInitiated', src, src, mySourceID)

    -- After add them to the same channel or do it from server.
    TriggerClientEvent('phone:addToCall', source, channel)
    TriggerClientEvent('phone:addToCall', mySourceID, channel)

    TriggerClientEvent('phone:id', src, channel)
    TriggerClientEvent('phone:id', mySourceID, channel)
end)

RegisterNetEvent('phone:EndCall')
AddEventHandler('phone:EndCall', function(mySourceID, stupidcallnumberidk, somethingextra)
    local src = source
    TriggerClientEvent('phone:removefromToko', source, stupidcallnumberidk)
    if mySourceID == 0 or mySourceID == nil then
    else
        if stupidcallnumberidk ~= nil or stupidcallnumberidk ~= 0 then
            TriggerClientEvent('phone:removefromToko', mySourceID, stupidcallnumberidk)
        end
        TriggerClientEvent('phone:otherClientEndCall', mySourceID)
    end

    if somethingextra then
        TriggerClientEvent('phone:otherClientEndCall', src)
    end
end)

RegisterCommand("answer", function(source, args, rawCommand)
    local src = source
    TriggerClientEvent('phone:answercall', src)
end, false)

RegisterCommand("a", function(source, args, rawCommand)
    local src = source
    TriggerClientEvent('phone:answercall', src)
end, false)

RegisterCommand("h", function(source, args, rawCommand)
    local src = source
    TriggerClientEvent('phone:endCalloncommand', src)
end, false)


RegisterCommand("hangup", function(source, args, rawCommand)
    local src = source
    TriggerClientEvent('phone:endCalloncommand', src)
end, false)

--[[RegisterCommand("lawyer", function(source, args, rawCommand)
    local src = source
    TriggerClientEvent('yellowPages:retrieveLawyersOnline', src, true)
end, false)]]--
RegisterServerEvent('phone:pn')
AddEventHandler('phone:pn', function(cid)
    local src = source
    exports.ghmattimysql:execute("SELECT phone_number FROM __characters WHERE id = @identifier", {['identifier'] = cid}, function(result)
        if result[1] ~= nil then
            TriggerClientEvent('sendMessagePhoneN', src, result[1].phone_number)
        end
    end)
  end)

RegisterServerEvent('phone:number')
AddEventHandler('phone:number', function(cid)
    local src = source
    local myPed = GetPlayerPed(src)
    local sourcePlayer = tonumber(source)
    local players = GetPlayers()
    local num = getNumberPhone(cid)
    local myPos = GetEntityCoords(myPed)
    if num == '0' or num == nil then
        repeat
            num = getPhoneRandomNumber()
            local id = getIdentifierByPhoneNumber(num)
        until (id == nil)
    end
    for k, v in ipairs(players) do
        if v ~= src then
            local xTarget = GetPlayerPed(v)
            local tPos = GetEntityCoords(xTarget)
            local dist = #(vector3(tPos.x, tPos.y, tPos.z) - myPos)
            if dist < 2 then 
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div style="padding: 0.6vw; font-weight: bold; margin: 0.1vw; background-color: rgba(190, 97, 18, 0.85); border-radius: 10px;"><b>{0}</b> | {1}</div>',
                    args = {'SERVICE', "My Phone Number " .. num }
                })
                TriggerClientEvent('chat:addMessage', v, {
                    template = '<div style="padding: 0.6vw; font-weight: bold; margin: 0.1vw; background-color: rgba(190, 97, 18, 0.85); border-radius: 10px;"><b>{0}</b> | {1}</div>',
                    args = {'SERVICE', 'Shown Phone Number ' .. num}
                })
            end
        end
    end
end)

function getPlayerID(source)
    local identifiers = GetPlayerIdentifiers(source)
    local player = getIdentifiant(identifiers)
    return player
end
function getIdentifiant(id)
    for _, v in ipairs(id) do
        return v
    end
end

function getPhoneRandomNumber()
    local numBase0 = 4
    local numBase1 = math.random(10,99)
    local numBase2 = math.random(100,999)
    local numBase3 = math.random(1000,9999)
    local num = string.format(numBase0 .. "" .. numBase1 .. "" .. numBase2 .. "" .. numBase3)
    return num
end

RegisterNetEvent('message:inDistanceZone')
AddEventHandler('message:inDistanceZone', function(somethingsomething, messagehueifh)
    local src = source		
    local first = messagehueifh:sub(1, 3)
    local second = messagehueifh:sub(4, 6)
    local third = messagehueifh:sub(7, 11)

    local msg = first .. "-" .. second .. "-" .. third
	TriggerClientEvent('chat:addMessage', somethingsomething, {
		template = '<div style = "display: inline-block !important;padding: 0.6vw;padding-top: 0.6vw;padding-bottom: 0.7vw;margin: 0.1vw;margin-left: 0.4vw;border-radius: 10px;background-color: #be6112d9;width: fit-content;max-width: 100%;overflow: hidden;word-break: break-word;"><b>Phone</b>: #{1}</div>',
		args = { fal, msg }
	})
end)

RegisterNetEvent('message:tome')
AddEventHandler('message:tome', function(messagehueifh)
    local src = source		
    local first = messagehueifh:sub(1, 3)
    local second = messagehueifh:sub(4, 6)
    local third = messagehueifh:sub(7, 11)

    local msg = first .. "-" .. second .. "-" .. third
	TriggerClientEvent('chat:addMessage', src, {
		template = '<div style = "display: inline-block !important;padding: 0.6vw;padding-top: 0.6vw;padding-bottom: 0.7vw;margin: 0.1vw;margin-left: 0.4vw;border-radius: 10px;background-color: #be6112d9;width: fit-content;max-width: 100%;overflow: hidden;word-break: break-word;"><b>Phone</b>: #{1}</div>',
		args = { fal, msg }
	})
end)


RegisterNetEvent('phone:getServerTime')
AddEventHandler('phone:getServerTime', function()
    local hours, minutes, seconds = Citizen.InvokeNative(0x50C7A99057A69748, Citizen.PointerValueInt(), Citizen.PointerValueInt(), Citizen.PointerValueInt())
    TriggerClientEvent('timeheader', -1, hours, minutes)
end)

--[[ Others ]]

RegisterNetEvent('getAccountInfo')
AddEventHandler('getAccountInfo', function(money, inbank)
    local src = source

    TriggerClientEvent('getAccountInfo', src, tonumber(money), tonumber(inbank))
end)


RegisterNetEvent('getYP')
AddEventHandler('getYP', function()
    local source = source
    exports.ghmattimysql:execute('SELECT * FROM phone_yp LIMIT 30', {}, function(yp)
        local deorencoded = json.encode(yp)
        TriggerClientEvent('YellowPageArray', source, yp)
    end)
end)

RegisterNetEvent('phone:updatePhoneJob')
AddEventHandler('phone:updatePhoneJob', function(cid, firstname, lastname, advert)
    local src = source
    local mynumber = getNumberPhone(cid)

    fal = firstname .. " " .. lastname

    exports.ghmattimysql:execute('INSERT INTO phone_yp (name, advert, phoneNumber) VALUES (@name, @advert, @phoneNumber)', {
        ['name'] = fal,
        ['advert'] = advert,
        ['phoneNumber'] = mynumber
    }, function(result)
        TriggerClientEvent('refreshYP', src)
    end)
end)

RegisterNetEvent('phone:RemovePhoneJob')
AddEventHandler('phone:RemovePhoneJob', function(cid, firstname, lastname, advert)
    local src = source
    local mynumber = getNumberPhone(cid)

    fal = firstname .. " " .. lastname

    exports.ghmattimysql:execute('DELETE FROM phone_yp WHERE name = @name AND advert = @advert AND phoneNumber = @phoneNumber LIMIT 1', {
        ['name'] = fal,
        ['advert'] = advert,
        ['phoneNumber'] = mynumber
    }, function(result)
        TriggerClientEvent('refreshYP', src)
    end)
end)


RegisterNetEvent('phone:foundLawyer')
AddEventHandler('phone:foundLawyer', function(name, phoneNumber)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style = "display: inline-block !important;padding: 0.6vw;padding-top: 0.6vw;padding-bottom: 0.7vw;margin: 0.1vw;margin-left: 0.4vw;border-radius: 10px;background-color: #1e2dff9c;width: fit-content;max-width: 100%;overflow: hidden;word-break: break-word;"><b>YP</b>: ⚖️ {0} ☎️ {1}</div>',
        args = { name, phoneNumber }
    })
end)

RegisterNetEvent('phone:foundLawyerC')
AddEventHandler('phone:foundLawyerC', function(name, phoneNumber)
    local src = source
    TriggerClientEvent('chat:addMessage', src, {
        template = '<div style = "display: inline-block !important;padding: 0.6vw;padding-top: 0.6vw;padding-bottom: 0.7vw;margin: 0.1vw;margin-left: 0.4vw;border-radius: 10px;background-color: #1e2dff9c;width: fit-content;max-width: 100%;overflow: hidden;word-break: break-word;"><b>YP</b>: ⚖️ {0} ☎️ {1}</div>',
        args = { name, phoneNumber }
    })
end)

RegisterNetEvent('deleteAllYP')
AddEventHandler('deleteAllYP', function()
    local src = source
    exports.ghmattimysql:execute('DELETE FROM phone_yp', {}, function (result) end)
end)

--Testing
RegisterNetEvent('deleteAllTweets')
AddEventHandler('deleteAllTweets', function()
    local src = source
    exports.ghmattimysql:execute('DELETE FROM tweets', {}, function (result) end)
end)

RegisterServerEvent('phone:RemoveFromRepoList')
AddEventHandler('phone:RemoveFromRepoList', function(plate)
    exports.ghmattimysql:execute('UPDATE __vehicles SET `amount_due`= ?, `last_payment`= ? WHERE `plate`= ?', {0, 0, plate})
end)

AddEventHandler("playerConnecting", function()
	local src = source
	local identifiers, steamIdentifier = GetPlayerIdentifiers(source)
    for _, v in pairs(identifiers) do
        if string.find(v, "steam") then
            steamIdentifier = v
            break
        end
    end
    table.insert(PlayerTable, {sourceID = steamIdentifier, timeJoined = GetGameTimer()})
    print("Player Table : " .. json.encode(PlayerTable))
end)

AddEventHandler('playerDropped', function()
	local identifiers, steamIdentifier = GetPlayerIdentifiers(source)
    for _, v in pairs(identifiers) do
        if string.find(v, "steam") then
            steamIdentifier = v
            break
        end
    end
	local timeJoined, ky
	for k,v in pairs(PlayerTable) do 
		if v.sourceID == steamIdentifier then timeJoined = v.timeJoined; ky = k; end
	end
    if not timeJoined then return; end

    local userData = promise:new()

    exports.ghmattimysql:execute('SELECT uid FROM __users WHERE steam = ?', {steamIdentifier}, function(data)
        userData:resolve(data)
    end)

    local uid = Citizen.Await(userData)
    local user = exports['srp-base']:getModule("Player")
    local char = user:getCurrentCharacter(uid[1].uid)
    print(json.encode(char))
    local cid = char.id
    print(cid)

	local identifier = steamIdentifier
    exports.ghmattimysql:execute("SELECT * FROM __vehicles WHERE cid=@identifier",{['identifier'] = cid}, function(data)
        if not data then return; end
        for k,v in pairs(data) do
            if (v.amount_due and v.amount_due > 0) and (v.last_payment and (v.last_payment > -1 or v.last_payment < -1)) then
                local newTime = math.floor(v.last_payment - (((GetGameTimer() - timeJoined) / 1000) / 60))
                if newTime < -1 then newTime = -1; end
                exports.ghmattimysql:execute('UPDATE __vehicles SET last_payment=@last_payment WHERE plate=@plate', {['last_payment'] = newTime, ['plate'] = v.plate} )
            end
        end
        table.remove(PlayerTable, ky)
    end)
end)


--STOCKS TEST

RegisterServerEvent('phone:stockTradeAttempt')
AddEventHandler('phone:stockTradeAttempt', function(index, playerid, sending)
    TriggerClientEvent('stocks:newstocks', playerid, sending, index)
end)

RegisterServerEvent('stocks:clientvalueupdate')
AddEventHandler('stocks:clientvalueupdate', function(cid, isupdate, data)
    local src = source
    if isupdate == false then
        exports.ghmattimysql:execute('UPDATE __characters SET `stocks`= ? WHERE `id`= ?', {json.encode(data), cid})
        TriggerClientEvent('stocks:clientvalueupdate', src, data)
    else
        TriggerClientEvent('stocks:retrieve', src, cid)
    end
end)

RegisterServerEvent('stocks:retrieve')
AddEventHandler('stocks:retrieve', function(cid)
    local src = source
    exports.ghmattimysql:execute('SELECT `stocks` FROM __characters WHERE `id`= ?', {cid}, function(data)
        if data[1].stocks ~= nil then
            TriggerClientEvent('stocks:clientvalueupdate', src, json.decode(data[1].stocks))
        end
    end)
end)

