interface = {}

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

interface.level = 1
interface.cur_level = nil

function interface.get_module()
	return "Sargon 2.5 GMS"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	send_input(":IN.0", 0x40, 1) -- Change Level
	send_input(":IN.0", 1 << (7 - interface.level), 1)
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":IN.0", 0x80, 1)  -- New Game
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		-- MAME's 6522 reset doesn't release an IRQ that is asserted at that moment, and the
		-- program then hangs in its IRQ handler. Disable the VIA interrupts (IER) first.
		machine.devices[":maincpu"].spaces["program"]:write_u8(0x800e, 0x7f)
		ioport.ports[":IN.1"]:field(0x01):set_value(1) -- RESET
		ioport.ports[":IN.1"]:field(0x02):set_value(1) -- HALT
		emu.wait(0.1)
		ioport.ports[":IN.1"]:field(0x02):set_value(0)
		ioport.ports[":IN.1"]:field(0x01):set_value(0)
		sb_clear_board(":board")
		return (":board")
	else
		send_input(":IN.0", 0x10, 1) -- Change Board
		for x = 1, 8 do
			for y = 1, 8 do
				local p=get_piece_id(9 - x, y)
				if p ~= 0 then
					if p > 0 then
						send_input(":IN.0", 0x02, 0.5) -- White
					else
						send_input(":IN.0", 0x01, 0.5) -- Black
					end
					send_input(":IN.0", 0x01 << (math.abs(p) + 1), 0.5)
				end
			end
		end
		if mode == -1 then
			send_input(":IN.0", 0x20, 1) -- Change Color
			send_input(":IN.0", 0x20, 1) -- Change Color
		end
		send_input(":IN.0", 0x10, 1) -- Change Board
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.0", 0x04, 1) -- Monitor
	elseif led_on("9.10") then
		interface.start_play()
	end
end

function interface.start_play(init)
	send_input(":IN.0", 0x20, 1) -- Change Color
	if led_on("8.1") then
		send_input(":IN.0", 0x01, 1) -- Black
	else
		send_input(":IN.0", 0x02, 1) -- White
	end
end

function interface.stop_play()
	send_input(":IN.1", 0x02, 0.5) -- HALT
end

function interface.is_selected(x, y)
	return led_on((x - 1) .. "." .. (y - 1))
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "0", "6" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = tonumber(value)
		if (level < 0 or level > 6) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.test_promotion(x, y)
	local piece = "Q"
	sb_select_piece(":board", 0.5, x, y, "")
	if     led_on("8.3") then piece = "Q"
	elseif led_on("8.4") then piece = "R"
	elseif led_on("8.5") then piece = "B"
	elseif led_on("8.6") then piece = "N"
	end
	sb_select_piece(":board", 0.5, x, y, "")
	return piece
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	if piece == piece:lower() then
		promotion_error(piece)
		sb_promote(":board", x, y, "q")	-- TODO
	else
		sb_promote(":board", x, y, piece)
 	end
end

return interface
