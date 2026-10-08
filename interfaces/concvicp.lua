interface = load_interface("concams5")

function interface.get_module()
	return "Conchess Plymate Victoria"
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	machine.devices[':maincpu'].spaces['program']:write_u8(0x0dd9,0x00)
	interface.cur_level = "P2"
	interface.setlevel()
end

function interface.select_piece(x, y, event)
	local timeout = output:get_value("0.1") ~= 0 and output:get_value("0.7") ~= 0
	if (event == "get") then
		lastx = x
		lasty = y
		sb_select_piece(":board", 1, x, y, event)
	elseif (event == "en_passant") then
		sb_remove_piece(":board", x, y)
	elseif (event == "get_castling" or event == "put_castling") then
		sb_move_piece(":board", x, y)
	else
		if (timeout) then
			emu.wait(1.5)
			sb_move_piece(":board", lastx, lasty)
			emu.wait(1.5)
			sb_select_piece(":board", 1, lastx, lasty, "get")
		end
		sb_select_piece(":board", 1, x, y, event)
	end
end

return interface
