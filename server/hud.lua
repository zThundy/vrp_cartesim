vMySQL = module("vrp_mysql", "MySQL")

vMySQL.createCommand("vRP/delete_sim", "DELETE FROM vrp_sim WHERE numero = @numero AND user_id = @user_id")

local function getPhoneRandomNumber()
	return math.random(55500000,55599999)
end

vRP.defInventoryItem({"sim", "Sim", "Una sim utilizzabile.", function(args)
    local choices = {}
    local idname = args[1]

    choices["Usa"] = {function(source, choice)
        local user_id = vRP.getUserId({source})
        if user_id ~= nil then
            if vRP.tryGetInventoryItem({user_id, "sim", 1, true}) then
				local result = MySQL.Sync.fetchAll("SELECT * FROM vrp_sim WHERE user_id = @user_id", {['user_id'] = user_id})
				if result ~= nil then
					local newNumber = getPhoneRandomNumber()
					for k, v in ipairs(result) do
						local numero = result[k].numero
						if numero ~= nil and newNumber ~= numero then
							if k == #result then
								MySQL.Sync.fetchAll("INSERT IGNORE INTO vrp_sim(user_id, numero, label) VALUES(@user_id, @numero, @label)", {['user_id'] = user_id, ['numero'] = newNumber, ['label'] = newNumber})
								vRPclient.notify(source, {"~w~Nuova sim creata con numero ~g~"..newNumber})
								vRP.closeMenu({source})
								--vMySQL.query("vRP/create_sim", {user_id = user_id, numero = newNumber, label = newNumber})
							end
						end
					end
				end
            end
        end
    end}
    return choices
end, 0.10})

vRP.registerMenuBuilder({"main", function(add, data)
    local player = data.player
    local user_id = vRP.getUserId({player})
	local arrayNumeri = {}
	local label = nil
	
    if user_id ~= nil then
        local choices = {}

            -- build society menu
        choices["Lista Sim"] = {function(player, choice)
            vRP.buildMenu({"sim", {player = player}, function(menu)
                menu.name = "Lista Sim"
                menu.css = {top = "75px", header_color = "rgba(0,128,255,0.75)"}
                menu.onclose = function(player) vRP.openMainMenu({player}) end

               	vRP.getNumbers(user_id, function(result)
					for i=1, #result do
						local numero = result[i].numero
						local label = result[i].label
						table.insert(arrayNumeri, {['user_id'] = user_id, ['label'] = label})

						menu[label] = {ch_build_sim_menu, "Questa sim e' associata al numero "..numero}
					end
					vRP.openMenu({player, menu})
				end)
            end})
        end}
		
		function ch_build_sim_menu(player, choice)
			vRP.buildMenu({"sim_choices", {player = player}, function(scelta)
				local scelta = {}
				local numero = 0
				local user_id = vRP.getUserId({player})
				choice = tostring(choice)
				
				local result = MySQL.Sync.fetchAll("SELECT * FROM vrp_sim WHERE label = @label AND user_id = @user_id", {['label'] = choice, ['user_id'] = user_id})
				scelta.name = tostring(result[1].numero)
				scelta.css = {top = "75px", header_color = "rgba(128,128,255,0.75)"}
				scelta.onclose = function(player) vRP.openMainMenu({player}) end
		
				scelta["Rinomina"] = {function(player, choice)
					if user_id ~= nil and result[1].numero ~= nil then
						vRP.prompt({player, "Inserisci il nuovo nome da assegnare alla sim", "", function(player, newLabel)
							if #result == 1 then
								MySQL.Sync.execute("UPDATE vrp_sim SET label = @label WHERE numero = @numero AND user_id = @user_id", {['label'] = newLabel, ['numero'] = result[1].numero, ['user_id'] = user_id})
								vRPclient.notify(player, {"~g~Salvato con successo!"})
								vRP.closeMenu({player})
							else
								vRPclient.notify(player, {"~r~Sim non trovata!"})
							end
						end})
					end
				end}
				
				scelta["Usa"] = {function(player, choice)
					if user_id ~= nil and result[1].numero ~= nil then
						MySQL.Sync.execute("UPDATE vrp_user_identities SET phone = @phone WHERE user_id = @user_id", {['phone'] = result[1].numero, ['user_id'] = user_id})
						vRPclient.notify(player, {"~w~Numero aggiornato a ~g~"..tostring(result[1].numero)})
						SetTimeout(300)
						local messages = vRP.getMessagesFromId(user_id)
						TriggerClientEvent("gcPhone:myPhoneNumber", player, tonumber(result[1].numero))
						TriggerEvent("gcPhone:allUpdate", user_id)
						vRP.closeMenu({player})
					end
				end}
				
				scelta["Distruggi"] = {function(player, choice)
					if user_id ~= nil and result[1].numero ~= nil then
						local tempNum = result[1].numero
						local tempResult = MySQL.Sync.fetchAll("SELECT * FROM vrp_user_identities WHERE user_id = @user_id", {['user_id'] = user_id})
						--MySQL.Sync.fetchAll("DELETE FROM vrp_sim WHERE numero = @numero AND user_id = @user_id", {['numero'] = result[1].number, ['user_id'] = user_id})
						vMySQL.execute("vRP/delete_sim", {numero = tonumber(result[1].numero), user_id = user_id})
						if result[1].numero == tempResult[1].phone then
							MySQL.Sync.execute("UPDATE vrp_user_identities SET phone = @phone WHERE user_id = @user_id", {['phone'] = 1, ['user_id'] = user_id})
						end
						vRPclient.notify(player, {"~r~Sim "..tostring(tempNum).."~r~ distrutta!"})
						vRP.clearAllInfoSim(user_id, result[1].numero)
						tempNum = nil
						vRP.closeMenu({player})
					end
				end}
				vRP.openMenu({player, scelta})
			end})
		end
		
		add(choices)
    end
end})