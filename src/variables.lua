return {
	-- Window Config
	Title = "Ophyn",
	Description = "Key System",
	Logo = "rbxassetid://111673746737789", -- rbxassetid
	Theme = "Plant-Dark",
	Folder = "Ophyn-KSY",

	-- Buttons Config
	getkey = true,

	-- Intro Config
	Intro = "true", -- "false": fade-in on open, fade-out on close
	startintro_size = 80, -- initial square size
	squareintro_time = 1.2,
	squarecontorn = "true", -- "false": removes the outline around the intro square

	-- Themes Config
	Changelogocolor = true,
	Changeiconscolor = true,
	ChangeTheme = "true", -- "false": disable moon icon to change Theme

	-- Section Config
	discord_link = "",
	website_link = "",

	-- Cards ("true" / "false")
	Discord = "true",
	Website = "false",
	Informations = "true",

	-- Keyless mode: no key needed. Status becomes "Keyless" and Submit runs the Callback directly.
	Keyless = {
		enabled = false, -- true: turns keyless mode on
		disabletextbox = true, -- dims the key box and blocks typing
		disablegetkey = true, -- dims "Get a key" and blocks clicks
		showcard = true, -- shows the "Keyless Mode" card
		autoconfirm = false, -- true: runs the Callback automatically when the UI opens
	},

	-- Notification style
	NotifStyle = "1",

	-- Tabs style: "1" = Tabs in a column on the left, "2" = Tabs in a row under the topbar
	TabsStyle = "1",

	-- Games
	SupportedGames = {},

	-- Script Execution
	Callback = function(key)
		-- your script here
	end,
}
