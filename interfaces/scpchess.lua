interface = load_interface("scpchessa")

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "CXG Sensor Computachess v2"
end

function interface.count_level()
	-- level bar on the rank LEDs (1-8), continued on the file LEDs (9-16)
	local cur_level = 0
	for i = 0, 7 do
		if output_value("1." .. i) ~= 0 then
			cur_level = cur_level + 1
		end
		if output_value("0." .. i) ~= 0 then
			cur_level = cur_level + 1
		end
	end
	return cur_level
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
