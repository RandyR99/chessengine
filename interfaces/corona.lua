interface = load_interface("stratos")

interface.invert = false
interface.level = "a3"
interface.cur_level = nil

function interface.get_module()
	if machine.system.name == "corona" then
		return "Saitek Kasparov Corona"
	elseif machine.system.name == "coronaa" then
		return "Saitek Kasparov Corona v2"
	elseif machine.system.name == "coronab" then
		return "Saitek Kasparov Corona v3"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Julio Kaplan"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	send_input(":IN.0", 0x02, 1) -- Level
	emu.wait(0.5)
	local invert = interface.invert
	interface.invert = false
	local clevx = 0
	local clevy = 0
	for cx = 1, 8 do
		for cy = 1, 8 do
			if (interface.is_selected(cx, cy)) then
				clevx = cx
				clevy = cy
				cx = 8
				cy = 8
			end
		end
	end
	if (clevx > 0 and clevy > 0) and (clevx ~= x or clevy ~= y) then
		local dlev = (x * 8 + y) - (clevx * 8 + clevy)
		local dx = (x - clevx + 8) % 8
		local dy = y - clevy
		if (dlev >= -7 and dlev <= 4) then
			dx = 0
			dy = dlev
		end
		for i = 1, dx do
			send_input(":IN.4", 0x02, 1) -- Tab
		end
		for i = 1, math.abs(dy) do
			if (dy > 0) then
				send_input(":IN.5", 0x01, 1) -- +
			else
				send_input(":IN.4", 0x04, 1) -- -
			end
		end
	end
	interface.invert = invert
	emu.wait(0.5)
	send_input(":IN.7", 0x04, 1) -- Normal
	emu.wait(1)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
    local throttled_state = machine.video.throttled
    machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(10)
	repeat
		send_input(":IN.5", 0x04, 0.3) -- LCD Scroll
		info = interface.read_digit(1)
	until info == " info"
	emu.wait(1)
	send_input(":IN.7", 0x04, 1) -- Normal
	emu.wait(1)
	interface.invert = false
	send_input(":IN.1", 0x04, 1) -- New Game
	emu.wait(1)
	interface.cur_level = "a3"
    machine.video.throttled = throttled_state
	interface.setlevel()
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	return output:get_indexed_value(tostring(2 + x) .. ".", y - 1) ~= 0
end

function interface.get_options()
	return {
		{ "string", "Level", "a3" },
	}
end

function interface.read_7_7_segment()
	local digit = {
		[39] = "+",
		[29] = "1",
		[30] = "2",
		[31] = "3",
		[32] = "4",
		[33] = "5",
		[34] = "6",
		[35] = "7",
		[36] = "8",
		[37] = "9",
		[40] = "-"
	}
	local ddram = emu.item(machine.devices[':maincpu'].items['0/:nvram']):read_block(0x0a40, 0x2)
	return digit[ddram:byte(1)]
end

function interface.read_digit(line)
	local digit = {
		[1] = " ",
		[7] = "1",
		[8] = "7",
		[9] = "_",
		[18] = "i",
		[17] = "i",
		[21] = ":",
		[29] = "u",
		[57] = "l",
		[58] = "C",
		[62] = "g",
		[64] = "0",
		[65] = "-",
		[80] = "3",
		[81] = "r",
		[85] = "n",
		[89] = "c",
		[92] = "2",
		[93] = "o",
		[95] = "d",
		[103] = "4",
		[110] = "5",
		[111] = "y",
		[114] = "f",
		[116] = "P",
		[117] = "h",
		[120] = "a",
		[121] = "t",
		[122] = "e",
		[125] = "b",
		[126] = "6",
		[128] = "8",
		[112] = "9",
		[129] = " ",
		[135] = "1",
		[220] = "2",
		[208] = "3",
		[231] = "4",
		[238] = "5",
		[254] = "6",
		[136] = "7",
		[256] = "8",
		[240] = "9"
	}
	local info = ""
	local info2 = ""
	local ddram = emu.item(machine.devices[':maincpu'].items['0/:nvram']):read_block(0x0a3a, 0x10)
	if digit[ddram:byte(1) + 1] ~= nil and digit[ddram:byte(2) + 1] ~= nil and digit[ddram:byte(3) + 1] ~= nil and digit[ddram:byte(5) + 1] ~= nil and digit[ddram:byte(6) + 1] ~= nil then
		info = digit[ddram:byte(1) + 1] .. digit[ddram:byte(2) + 1] .. digit[ddram:byte(3) + 1] .. digit[ddram:byte(5) + 1] .. digit[ddram:byte(6) + 1]
	end
	ddram = emu.item(machine.devices[':maincpu'].items['0/:nvram']):read_block(0x0a40, 0x10)
	if digit[ddram:byte(2) + 1] ~= nil and digit[ddram:byte(3) + 1] ~= nil and digit[ddram:byte(5) + 1] ~= nil and digit[ddram:byte(6) + 1] ~= nil then
		info2 = digit[ddram:byte(2) + 1] .. digit[ddram:byte(3) + 1] .. digit[ddram:byte(5) + 1] .. digit[ddram:byte(6) + 1]
	end
	if line == 1 then
		return info
	elseif line == 2 then
		return info2
	end
	return info
end

return interface
