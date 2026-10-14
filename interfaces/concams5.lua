interface = load_interface("conc")

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

local lastx = 0
local lasty = 0

function interface.get_module()
	if machine.system.name == "concams5" then
		return "Conchess Plymate Amsterdam 5.5"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	machine.devices[':maincpu'].spaces['program']:write_u8(0x0dd9,0x00)
	interface.cur_level = "L1"
	interface.setlevel()
end

function interface.select_piece(x, y, event)
	local timeout = led_on("0.1") and led_on("0.7")
	if (timeout) then
		send_input(":IN.0", 0x80, 0.15) -- Continue
		emu.wait(1.5)
	end
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
			sb_move_piece(":board", lastx, lasty)
			emu.wait(1.5)
			sb_select_piece(":board", 1, lastx, lasty, "get")
		end
		sb_select_piece(":board", 1, x, y, event)
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "L1" },
	}
end

return interface
