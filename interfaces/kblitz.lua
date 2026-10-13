interface = {}

interface.level = "a3"
interface.cur_level = nil
local ram = emu.item(machine.devices[':maincpu'].items['0/:maincpu:internal_ram'])

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	ram:write(0x1ca, 16*(x-1)+y-1)
	ram:write(0x1cc, 16*(x-1)+y-1)
	machine:popmessage("Level " .. tostring(interface.level))
end
function interface.setup_machine()
	emu.wait(1)
	sb_reset_board(":board")
	emu.wait(6)

	interface.cur_level = "a3"
	interface.setlevel()
end

function interface.start_play()
	machine:popmessage("Set 'Options > Beg Search'!")
end

function interface.stop_play()
	machine:popmessage("Set 'Options > End Search'!")
end

function interface.is_selected(x, y)
	return output:get_value(tostring(y-1).."."..tostring(x-1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return {{"string", "Level", "a3"}}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if level:match("^[a-h][1-8]$") then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	if     output:get_value("s1.10") ~= 0 then return "q"
	elseif output:get_value("s2.10") ~= 0 then return "r"
	elseif output:get_value("s0.10") ~= 0 then return "b"
	elseif output:get_value("s3.10") ~= 0 then return "n"
	end
end

function interface.promote_special(piece)
	if piece == "q" then
		return
	end
	local throttled = machine.video.throttled
	machine.video.throttled = true
	local ok = false
	repeat
		machine:popmessage("Select promotion piece ...")
		emu.wait(1)
		if (piece == "r" and output:get_value("s2.10") ~= 0 and output:get_value("s1.10") == 0)
		or (piece == "b" and output:get_value("s0.10") ~= 0 and output:get_value("s2.10") == 0)
		or (piece == "n" and output:get_value("s3.10") ~= 0 and output:get_value("s2.10") == 0)
		then ok = true
		end
	until ok
	machine.video.throttled = throttled
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
end

return interface
