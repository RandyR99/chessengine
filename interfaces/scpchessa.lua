interface = load_interface("scpchess")

function interface.get_module()
	return "CXG Sensor Computachess"
end

function interface.get_author()
	return "David Levy & Mark Taylor"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	repeat
		send_input(":IN.0", 0x80, 0.6) -- Level
		local cur_level = 0
		for y = 0, 7 do
			if output:get_indexed_value(y .. ".", 1) ~= 0 then
				cur_level = cur_level + 1
			end
		end
		for x = 0, 7 do
			if output:get_indexed_value(7 - x .. ".", 0) ~= 0 then
				cur_level = cur_level + 1
			end
		end
	until cur_level == interface.level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "16" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 16) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

return interface
