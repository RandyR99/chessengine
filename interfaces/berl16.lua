interface = load_interface("berlinp")
interface.info_every = 1 -- show_info only reads the display

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

function interface.show_pv_after_move_emu()
    send_input(":KEY", 0x08, 0.6) -- DOWN
    send_input(":KEY", 0x08, 0.6) -- DOWN
end

function interface.show_pv_after_move_player()
    send_input(":KEY", 0x08, 0.6) -- DOWN
    send_input(":KEY", 0x08, 0.6) -- DOWN
end

function interface.show_info(on)
    if not on then
        return nil
    end
    local info = nil
    do -- (was: only when interface.ticker == 1, a field nothing sets)
        local ddram = emu.item(
                          machine.devices[':display:hd44780'].items['0/m_ddram']):read_block(
                          0x00, 0x80)

        if (ddram:sub(66, 69)) == "THEO" then
            info = "info score cp book"
        else
            info = "info score cp " ..  ddram:sub(65, 69):gsub("%.", "")
        end
        info = info .. " depth " .. (ddram:sub(1, 2)) .. " seldepth " ..
                   (ddram:sub(4, 5))
        info = info .. " pv " .. string.lower(ddram:sub(70, 112))
        if (ddram:sub(65, 65)) ~= " " and (ddram:sub(65, 65)) ~= "-" then
            info = nil
        end
    end

    return info
end

return interface
