interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 0
interface.cur_level = nil
interface.count = 0
interface.score = "0.00"
interface.pv = ""
interface.depth = "0"

function interface.get_module()
	return "VEB Chess-Master Diamond"
end

function interface.get_author()
	return "Dieter Schultze & Rüdiger Worbs"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x02, 1) -- View
	emu.wait(1)
	send_input(":IN.1", 0x01, 1) -- Monitor
	emu.wait(1)
	local lcd_num = { 0x00ff, 0x400c, 0x377, 0x023f, 0x38c, 0x03bb, 0x03fb, 0x020f, 0x3ff, 0x03bf }
	if interface.cur_level >= 10 then
		send_input(":IN.1", 0x02, 0.5) -- Vieww
		emu.wait(1)
		send_input(":IN.0", 0x20, 0.5) -- Selection/Dialogue
		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Move Fore
		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Move Fore
		emu.wait(1)
		send_input(":IN.0", 0x01, 0.5) -- Move Fore
		emu.wait(1)
		send_input(":IN.0", 0x80, 0.5) -- Enter
		emu.wait(1)
		send_input(":IN.1", 0x01, 0.5) -- Monitor
		emu.wait(1)
	end
	if interface.level >= 10 then
		send_input(":IN.0", 0x08, 0.5) -- Match/Time
		emu.wait(1)
		local level = interface.level - 10
		if level >= 1 then
			repeat
				send_input(":IN.0", 0x01, 1) -- Move Fore
				emu.wait(1)
				level = level - 1
			until level == 0
		end
		send_input(":IN.0", 0x80, 0.5) -- Enter
		emu.wait(1)
	else
		send_input(":IN.0", 0x10, 0.5) -- Parameter / Information
		emu.wait(1)
		send_input(":IN.0", 0x80, 0.5) -- Enter
		emu.wait(1)
		while output_value("digit0") ~= lcd_num[interface.level + 1] do
			send_input(":IN.0", 0x01, 0.5) -- Move Fore
			emu.wait(1)
		end
		send_input(":IN.1", 0x01, 0.5) -- Monitor
		emu.wait(1)
	end
	interface.cur_level = interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 0
	interface.setlevel()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	emu.wait(1)
	-- Score einschalten
	send_input(":IN.1", 0x02, 1) -- View
	emu.wait(0.5)
	send_input(":IN.1", 0x01, 1) -- Monitor
	emu.wait(0.5)
	send_input(":IN.1", 0x02, 1) -- View
	emu.wait(0.5)
	send_input(":IN.0", 0x20, 1) -- Selection/Dialogue
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x01, 1) -- Monitor (leave the score display)
		send_input(":IN.0", 0x04, 1) -- Board
		sb_clear_board(":board")
		send_input(":IN.0", 0x80, 1) -- Enter
		machine.video.throttled = throttled_state
		return (":board")
	else
		local ram = machine.devices[":maincpu"].spaces["program"]
		local fig = {0x81,0x82,0x83,0x84,0x85,0x86,0x00,0x06,0x05,0x04,0x03,0x02,0x01}
		local adr = 0x8315
		local brd = {{  3, 5, 4, 2, 1, 4, 5, 3 },
			         {  6, 6, 6, 6, 6, 6, 6, 6 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         {  0, 0, 0, 0, 0, 0, 0, 0 },
			         { -6,-6,-6,-6,-6,-6,-6,-6 },
			         { -3,-5,-4,-2,-1,-4,-5,-3 }}
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				local z = fig[p + 7]
				if p ~= 0 and p ~= brd[y][x] then
					z = z | 0x40
				end
				ram:write_u8(adr + 10 * (y - 1) + x - 1, z)
			end
		end
		if mode == 1 then
			ram:write_u8(0x83a1,0x00)
			ram:write_u8(0x83a2,0x80)
		else
			ram:write_u8(0x83a1,0x80)
			ram:write_u8(0x83a2,0x00)
		end
		send_input(":IN.1", 0x01, 0.5) -- Monitor
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x01, 0.5) -- Monitor (leave the score display, the manual starts from "Y")
	send_input(":IN.0", 0x20, 0.5) -- Selection
	send_input(":IN.0", 0x80, 0.5) -- Enter: referee mode on/off
	send_input(":IN.1", 0x01, 0.5) -- Monitor
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x80, 1) -- Enter
end

function interface.stop_play()
	send_input(":IN.0", 0x80, 1) -- Enter
end

function interface.is_selected(x, y)
	return output_value(tostring(x - 1) .. "." .. tostring(y - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "0", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
	-- Score einschalten
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x02, 0.5) -- View
	emu.wait(1)
	send_input(":IN.0", 0x20, 0.5) -- Selection/Dialogue
	emu.wait(1)
	machine.video.throttled = throttled_state
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit0") & 0xffff
	if     (d0 == 0xf730) then return "q"
	elseif (d0 == 0x93b4) then return "r"
	elseif (d0 == 0xd432) then return "b"
	elseif (d0 == 0x91bf) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board", x, y, piece)
	local right = -1
	if     (piece == "q") then right = 0
	elseif (piece == "r") then right = 1
	elseif (piece == "b") then right = 2
	elseif (piece == "n") then right = 3
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		interface.select_piece(x, y, "")
		send_input(":IN.0", 0x80, 1)
		interface.select_piece(x, y, "")
	end
	if (right ~= -1) then
		for i = 1, right do
			send_input(":IN.0", 0x01, 1)
		end
		send_input(":IN.0", 0x80, 1)
	end
	machine.video.throttled = throttled_state
end

function interface.show_info(on)
	if on then
		local d1 = output_value("digit3") + 1
		local d2 = output_value("digit2") + 1
		local d3 = output_value("digit1") + 1
		local d4 = output_value("digit0") + 1
		if interface.count == 0 then
			if d1 ~= 1 then
				interface.score = (digit(d1) .. digit(d2) .. digit(d3) .. digit(d4)):gsub(" ", ""):gsub("%.", "") .. "0"
			else
				return
			end
			send_input(":IN.0", 0x01, 0.3) -- Move Fore
			interface.count = interface.count + 1
			interface.pv = ""
		elseif (digit(d1) .. digit(d2) .. digit(d3) .. digit(d4)) ~= "    " then
			interface.pv = digit(d1) .. digit(d2) .. digit(d3) .. digit(d4)
			send_input(":IN.0", 0x01, 0.3) -- Move Fore
			interface.count = interface.count + 1
		else
			interface.depth = interface.count - 1
			interface.pv = string.lower(interface.pv)
			send_input(":IN.1", 0x02, 0.3) -- View
			send_input(":IN.0", 0x20, 0.3) -- Selection/Dialogue
			interface.count = 0
			return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
		end
	end
end

function digit(value)
	local digit_asc = {
		[1] = " ",
		[2568] = "?",
		[3841] = "+",
		[769] = "-",
		[20577] = "<-",
		[40985] = "->",
		[49177] = "->",
		[41090] = "<-",
		[976] = "A",
		[3648] = "B",
		[244] = "C",
		[3136] = "D",
		[500] = "E",
		[452] = "F",
		[764] = "G",
		[973] = "H",
		[13] = "I",
		[49601] = "K",
		[241] = "L",
		[24781] = "M",
		[41165] = "N",
		[968] = "P",
		[33736] = "R",
		[3076] = "T",
		[20673] = "V",
		[37069] = "W",
		[26625] = "Y",
		[976 + 65536] = "A.",
		[3648 + 65536] = "B.",
		[244 + 65536] = "C.",
		[3136 + 65536] = "D.",
		[500 + 65536] = "E.",
		[452 + 65536] = "F.",
		[764 + 65536] = "G.",
		[973 + 65536] = "H.",
		[13 + 65536] = "I.",
		[49601 + 65536] = "K.",
		[241 + 65536] = "L.",
		[24781 + 65536] = "M.",
		[41165 + 65536] = "N.",
		[968 + 65536] = "P.",
		[33736 + 65536] = "R.",
		[3076 + 65536] = "T.",
		[20673 + 65536] = "V.",
		[37069 + 65536] = "W.",
		[26625 + 65536] = "Y.",
		[256] = "0",
		[65792] = "0.",
		[16397] = "1",
		[888] = "2",
		[576] = "3",
		[909] = "4",
		[956] = "5",
		[1020] = "6",
		[528] = "7",
		[1024] = "8",
		[960] = "9",
		[16397 + 65536] = "1.",
		[888 + 65536] = "2.",
		[576 + 65536] = "3.",
		[909 + 65536] = "4.",
		[956 + 65536] = "5.",
		[1020 + 65536] = "6.",
		[528 + 65536] = "7.",
		[1024 + 65536] = "8.",
		[960 + 65536] = "9."
	}
	return (digit_asc[value])
end

return interface
