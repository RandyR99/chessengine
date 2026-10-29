interface = load_interface("smondial")

interface.level = "a2"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.ticker = 0

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Mephisto Super Mondial II"
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setlevel()
 	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 6) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local y = interface.level:sub(2,2)
	send_input(":KEY.0", 0x08, 1) -- LEV
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY.1", 0x08, 1) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(1)
	send_input(":KEY.3", 0x08, 0.5) -- RES
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.2", 0x04, 0.5) -- POS
		send_input(":KEY.2", 0x08, 0.5) -- ENT
		send_input(":KEY.2", 0x08, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p < 0 then
							interface.setdigit(7) -- Black
						else
							interface.setdigit(8) -- White
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						interface.setdigit(7 - math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode == 1 then
			interface.setdigit(8) -- White
		else
			interface.setdigit(7) -- Black
		end
		send_input(":KEY.1", 0x08, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.3", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.1", 0x08, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.2", 0x08, 1) -- ENT
end

function interface.is_selected(x, y)
	-- no clock check here (unlike smondial): this program shows the clocks while its move waits on the board
	local xval = output_value((x - 1) .. ".5") ~= 0
	local yval = output_value((y - 1) .. ".3") ~= 0
	return xval and yval
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
end

function interface.promote(x, y, piece)
	-- player promotion: piece key; the machine's own promotion needs no key or square press (unlike smondial)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.0", 0x02, 1)
	elseif (piece == "r") then send_input(":KEY.3", 0x01, 1)
	elseif (piece == "b") then send_input(":KEY.2", 0x01, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x01, 1)
	end
end

function interface.game_over()
	-- the machine resigns a lost position: "rESG" on the lower display
	return output_value("digit4") & 0x7f == 0x50 and output_value("digit5") & 0x7f == 0x79 and
	       output_value("digit6") & 0x7f == 0x6d and output_value("digit7") & 0x7f == 0x3d
end

return interface
