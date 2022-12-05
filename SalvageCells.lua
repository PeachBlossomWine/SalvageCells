_addon.name = 'SalvageCells'
_addon.author = 'PBW'
_addon.version = '1.8'
_addon.commands = {'salvage'}

require('functions')
require('logger')
require('tables')
require('coroutine')
res = require('resources')
local packets = require('packets')
texts = require('texts')
local bit = require('bit')

usedMeds = S{}
scheduled_function = nil
encumbrance_bitfield = 0

local flag_meds = T{
    [0]--[[main]]  =5365,
    [2]--[[range]] =5371,
    [4]--[[head]]  =5366,
    [5]--[[body]]  =5367,
    [6]--[[hands]] =5368,
    [7]--[[legs]]  =5369,
    [10]--[[waist]]=5370,
    [11]--[[lear]] =5372,
    [16]--[[STR]]  =5376,
    [17]--[[DEX]]  =5377,
    [18]--[[VIT]]  =5378,
    [19]--[[AGI]]  =5379,
    [20]--[[INT]]  =5380,
    [21]--[[MND]]  =5381,
    [22]--[[CHR]]  =5382,
    [23]--[[HP]]   =5383,
    [24]--[[MP]]   =5384,
}

local salvage_meds = T{
    [260]--[[Obliviscence]] =5373,
    [261]--[[impairment]]   =5374,
    [262]--[[Omerta]]       =5375,
}

function flagMeds()
    return flag_meds:keyset():filter(function(offset)
        return bit.band(encumbrance_bitfield, bit.lshift(1,offset)) > 0 end
    ):map(table.get+{flag_meds})
end

function buffMeds()
    local player = windower.ffxi.get_player()
    local buffs = player and player.buffs
    if not buffs then return end
    return (S(buffs)*salvage_meds:keyset()):map(table.get+{salvage_meds})
end

local salvage_area = S{73,74,75,76}

windower.register_event('add item', function(bag, index, id, count)
    if not scheduled_function then
        scheduled_function = useCells:schedule(2)
    end
end)
 
windower.register_event('incoming chunk', function(id, original)
    local zone_info = windower.ffxi.get_info()
	if salvage_area:contains(zone_info.zone) then
		if id == 0x01B then
			update_encumbrance(original)
			windower.add_to_chat(12,'Incoming Chunk bitfield: ' ..encumbrance_bitfield)
		elseif id == 0x028 then	
			local action = packets.parse('incoming', original)
			if action["Category"] == 5 and action.Actor == windower.ffxi.get_player().id then
				usedMeds:add(action.Param)
			end
		end
	end
end)

windower.register_event('load', function()
	windower.add_to_chat(262,'[Salvage] Welcome to Salvage Cells!')
end)

function initialize()
    update_encumbrance(windower.packets.last_incoming(0x01B))
    usedMeds = S{}
    scheduled_function = nil
end

function update_encumbrance(data)
    encumbrance_bitfield = not data and 0 or packets.parse('incoming', data)['Encumbrance Flags']
    windower.add_to_chat(12,'Update encumbrance_bitfield: '..encumbrance_bitfield)
end

function useCells()
    local meds_to_use = flagMeds()
	local buffs_to_use = buffMeds()
    
    items = windower.ffxi.get_items('inventory')
    for index, item in pairs(items) do
        if type(item) == 'table' and meds_to_use:contains(item.id) then
            while not(usedMeds:contains(item.id)) do 
                local cell_item = res.items[item.id].en
                windower.send_command('input /item "' .. cell_item ..'" <me>')
                coroutine.sleep(4.2)
            end
		elseif type(item) == 'table' and buffs_to_use:contains(item.id) then
			while not(usedMeds:contains(item.id)) do 
                local cell_item = res.items[item.id].en
                windower.send_command('input /item "' .. cell_item ..'" <me>')
                coroutine.sleep(4.2)
            end
        end
    end
    scheduled_function = nil
end

initialize()