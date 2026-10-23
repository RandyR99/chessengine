interface = load_interface("amsterd")

interface.level = "02"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "roma16" then
		return "Mephisto Roma (16 Bit)"
	elseif machine.system.name == "roma32" then
		return "Mephisto Roma (32 Bit)"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	send_input(":KEY.0", 0x04, 0.25) -- LEV
	for i = 1, level:len() do
		local n = level:sub(i,i)
		if (n == " " or n == ":" or n == "/") then
			send_input(":KEY.0", 0x20, 0.5) -- ENT
			if (n == " " and (output_value("digit3") & 0x7f) == 0x54) then
				send_input(":KEY.0", 0x20, 0.5) -- ENT
			end
		else
			interface.setdigit(tonumber(n))
		end
	end
	send_input(":KEY.0", 0x20, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = "02"
	interface.setlevel()
end

function interface.get_options()
	return {
		{ "string", "Level", "02" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^%d$")) then
			level = "0" .. level
		end
		local lev = tonumber(level:sub(1,2))
		if (level:match("^%d%d$")) then
			if (lev <= 37 or (lev >= 40 and lev <= 49) or lev >= 61) then
				interface.level = level
				interface.setlevel()
			end
		elseif (level:match("^%d%d%s") and (level:match("00/") == nil)) then
			local hm  = "%s%d%d:[0-5]%d"
			local hms = "%s%d%d:[0-5]%d:[0-5]%d"
			local nhm = "%s%d%d/%d%d:[0-5]%d"
			if (((lev == 38 or lev == 50 or lev == 58) and (level:len() == 11) and level:match(hms))
			or  ((lev == 39 or lev == 51) and (level:len() == 20) and level:match(hms .. hms))
			or  ((lev == 52) and (level:len() == 11) and level:match(nhm))
			or  ((lev == 53 or lev == 54 or lev == 59) and (level:len() == 20) and level:match(nhm .. nhm))
			or  ((lev == 55) and (level:len() == 38) and level:match(nhm .. nhm .. nhm .. nhm))
			or  ((lev == 56) and (level:len() == 17) and level:match(nhm .. hm))
			or  ((lev == 57) and (level:len() == 32) and level:match(nhm .. hm .. nhm .. hm))
			or  ((lev == 60) and (level:len() == 4) and level:match("%s%d"))) then
				interface.level = level
				interface.setlevel()
			end
		end
	end
end

return interface
