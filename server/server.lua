local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP_cartesim")

local function createNewNumber()
	local phone = vRP.generateStringNumber("555DDDDD")
	if phone ~= nil then
		return phone
	end
	return 0
end

function vRP.updateLabel(user_id, label)
	if user_id ~= nil and label ~= nil then
		MySQL.Async.execute("UPDATE vrp_sim SET label = @label WHERE user_id = @user_id", {['label'] = label, ['user_id'] = user_id}, function(result) end)
	end
end

function vRP.createNewSim(user_id)
	if user_id ~= nil then
		local numero = createNewNumber()
		if numero ~= nil then
			MySQL.Async.fetchAll("INSERT INTO vrp_sim(user_id, numero, label) VALUES(@user_id, @numero, @label)", {["@user_id"] = user_id, ["@numero"] = numero, ["@label"] = numero}, function(result) end)
		end
	end
end

function vRP.getNumbers(user_id, cb)
	if user_id ~= nil then
		local result = MySQL.Sync.fetchAll("SELECT * FROM vrp_sim WHERE user_id = @user_id", {['user_id'] = user_id})
		cb(result)
	end
end


function vRP.clearAllInfoSim(user_id, numero)
	if user_id ~= nil and numero ~= nil then
		local result = MySQL.Sync.fetchAll("SELECT * FROM phone_messages WHERE reciver = @reciver", {['reciver'] = numero})
		if #result > 0 and result ~= nil then
			MySQL.Sync.fetchAll("DELETE FROM phone_messages WHERE reciver = @reciver", {['reciver'] = numero})
		end
	end
end

function vRP.getMessagesFromId(user_id)
    local result = MySQL.Sync.fetchAll("SELECT phone_messages.* FROM phone_messages LEFT JOIN vrp_user_identities ON vrp_user_identities.user_id = @identifier WHERE phone_messages.receiver = vrp_user_identities.phone", {['@identifier'] = user_id})
	if result ~= nil and result > 0 then
		return result
	end
	return nil
end




-------- SPAWN FUNCTIONS -----------

function vRP.getDefaultSim(user_id)
	local numero = nil
	local result = MySQL.Sync.fetchAll("SELECT * FROM vrp_user_identities WHERE user_id = @user_id", {['user_id'] = user_id})
	if result[1] ~= nil then
		numero = result[1].phone
		return numero
	end
	return 0
end

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	if user_id ~= nil then
		local numero = vRP.getDefaultSim(user_id)
		local result = MySQL.Sync.fetchAll("SELECT * FROM vrp_sim WHERE user_id = @user_id", {['@user_id'] = user_id})
		if result[1] == nil then
			MySQL.Sync.fetchAll("INSERT INTO vrp_sim(user_id, numero, label) VALUES(@user_id, @numero, @label)",
				{["@user_id"] = user_id, ["@numero"] = numero, ["@label"] = numero}, function(result)
			end)
		end
	end
end)
