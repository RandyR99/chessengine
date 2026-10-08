interface = load_interface("arb_gms4")

function interface.get_module()
	return "ARB Sargon 4.0"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.get_options()
	return {
		{ "spin", "Level", "0", "0", "8" },
		{ "check", "Clear announcements", "1" },
	}
end

return interface
