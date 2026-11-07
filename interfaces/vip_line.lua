-- Novag VIP / Super VIP: the main line the program is working on is kept in RAM as from/to pairs, 0x88 squares from
-- rank 8 (file in bits 0-2, 8 - rank in bits 4-6; bit 7 marks castling). The list has no end mark and keeps moves of
-- earlier searches behind the current line, so only the first 3 moves count (what the machine itself shows when its
-- display rotates in SOLVE MATE); the plugin drops the line at the first move that isn't legal.
local vip = {}

function vip.reader(address)
	local mem = machine.devices[":maincpu"].spaces["program"]
	local stale = nil

	local function line()
		local t = ""
		for a = address, address + 5 do
			t = t .. string.char(mem:read_u8(a) & 0x77)
		end
		return t
	end

	return function(on)
		local l = line()
		if not on then
			stale = l
			return nil
		end
		if l == stale then
			return nil -- nothing from this search yet
		end
		stale = nil
		local pv = {}
		for i = 1, 5, 2 do
			local from, to = l:byte(i), l:byte(i + 1)
			if from == to then
				break
			end
			pv[#pv + 1] = string.char(97 + (from & 0x07), 56 - (from >> 4), 97 + (to & 0x07), 56 - (to >> 4))
		end
		if #pv == 0 then
			return nil
		end
		return { pv = pv }
	end
end

return vip
