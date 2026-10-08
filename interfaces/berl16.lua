interface = load_interface("berlinp")

-- Redefined helper locally to prevent environment scope lookup errors
local function read_lcd_range(start_idx, end_idx)
    local dev = machine.devices[':display:hd44780']
    if not dev then return "" end
    
    local state_item = dev.items["0/m_ddram"]
    if not state_item then return "" end
    
    local wrapped_mem = emu.item(state_item)
    local str = ""
    for i = start_idx, end_idx do
        str = str .. string.char(wrapped_mem:read(i))
    end
    return str
end

function interface.get_module()
	if machine.system.name == "berl16" then
		return "Mephisto Berlin (16 Bit)"
	elseif machine.system.name == "berl16a" then
		return "Mephisto Berlin (16 Bit) v2"
	elseif machine.system.name == "berl16l" then
		return "Mephisto Berlin (London)"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Richard Lang"
end

-- Disabled background menu shifting to prevent layout corruption
function interface.show_pv_after_move_emu()
    -- Intentional No-Op to block background DOWN inputs
end

function interface.show_pv_after_move_player()
    -- Intentional No-Op to block background DOWN inputs
end

return interface

