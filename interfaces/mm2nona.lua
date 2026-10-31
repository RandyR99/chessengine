interface = load_interface("rebel5")

function interface.get_module()
	return "Mephisto MM II Nona"
end

function interface.get_author()
	return "Frans Morsch"
end

-- show_info: the Nona program (Frans Morsch) keeps its search result in RAM: the evaluation for the machine at 0x07c3
-- (sign, 0x0f = '-', then pawns, tenths and hundredths as digits) followed by the main line at 0x07cb as from/to
-- square pairs (10x12 board, a1 = 21; 0 ends it). Found by RAM dumps during the search; no depth found. Read without
-- key presses (rebel5's reader uses other addresses and a display-digit format).
local stale = nil
local first = true

function interface.show_info(on)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local raw = ""
	for a = 0x07c3, 0x07d8 do
		raw = raw .. string.char(sp:read_u8(a))
	end
	if not on or first then
		first = false -- battery RAM still holds the last search before this session's first player turn
		stale = raw
		return nil
	end
	if raw == stale then
		return nil -- nothing from this search yet
	end
	stale = nil
	local info = {}
	local function square(v)
		v = v - 21
		if v >= 0 and v < 80 and v % 10 < 8 then
			return string.char(0x61 + v % 10) .. (v // 10 + 1)
		end
	end
	local pv = {}
	for k = 9, 21, 2 do
		local from, to = square(raw:byte(k)), square(raw:byte(k + 1))
		if not from or not to or from == to then
			break
		end
		pv[#pv + 1] = from .. to
	end
	if #pv > 0 then
		info.pv = pv
	end
	local sign, pawns, tenths, hundredths = raw:byte(1, 4)
	if pawns <= 9 and tenths <= 9 and hundredths <= 9 then
		local cp = pawns * 100 + tenths * 10 + hundredths
		info.score = sign == 0x0f and -cp or cp
	end
	if not info.pv then
		return nil
	end
	return info
end

interface.info_every = 1 -- show_info only reads RAM

return interface
