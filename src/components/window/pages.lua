-- src/components/window/pages.lua
-- yeah, cool.

local Pages = {}

local NAMED_COLORS = {
	red = Color3.fromRGB(229, 57, 53),
	orange = Color3.fromRGB(245, 124, 0),
	yellow = Color3.fromRGB(250, 204, 21),
	green = Color3.fromRGB(34, 160, 80),
	teal = Color3.fromRGB(20, 160, 150),
	cyan = Color3.fromRGB(6, 182, 212),
	blue = Color3.fromRGB(59, 130, 246),
	indigo = Color3.fromRGB(99, 102, 241),
	purple = Color3.fromRGB(147, 51, 234),
	pink = Color3.fromRGB(236, 72, 153),
	grey = Color3.fromRGB(100, 100, 108),
	gray = Color3.fromRGB(100, 100, 108),
	white = Color3.fromRGB(245, 245, 245),
	black = Color3.fromRGB(16, 16, 16),
}

-- Accepts a Color3, a color name ("Red", "Blue", ...) or a hex string ("#RRGGBB").
-- Returns nil for anything else, which makes the Paragraph follow the theme.
local function parseColor(value)
	if value == nil or value == "" then
		return nil
	end
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "string" then
		local named = NAMED_COLORS[value:lower()]
		if named then
			return named
		end
		local hex = value:match("^#?(%x%x%x%x%x%x)$")
		if hex then
			return Color3.fromHex(hex)
		end
	end
	return nil
end

function Pages.new(ctx)
	local C, make, round = ctx.C, ctx.make, ctx.round
	local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
	local setRole, icon, assetId = ctx.setRole, ctx.icon, ctx.assetId
	local contrastOn, iconRole, logoRole = ctx.contrastOn, ctx.iconRole, ctx.logoRole
	local FONT, FONT_BOLD, Images = ctx.FONT, ctx.FONT_BOLD, ctx.images
	local state, content, canvas = ctx.state, ctx.content, ctx.canvas
	local W, H = ctx.width, ctx.height

	local TOPBAR_H = 38
	local SIDE_W = 124
	local SLIDE_TIME = 0.55
	local Quint = Enum.EasingStyle.Quint

	-- Section title look: a bit bigger than before and slightly see-through
	local SECTION_TEXT_SIZE = 15
	local SECTION_TEXT_TRANSPARENCY = 0.35

	-- Switching Tabs: the content rises a few pixels while its elements fade in one after
	-- the other (the stagger is capped so a Tab with many elements doesn't feel slow)
	local TAB_SLIDE = 10
	local TAB_IN_TIME = 0.32
	local TAB_STAGGER = 0.045
	local TAB_STAGGER_MAX = 0.4

	-- Both arrows (down: show the Tabs / up: back to the Key System) reuse the Submit
	-- button's icon. If that icon points right, 90 turns it to point down and -90 up;
	-- change this if the arrows end up facing the wrong way.
	local NEXT_ARROW_ROTATION = 90
	local BACK_ARROW_ROTATION = -NEXT_ARROW_ROTATION

	-- Tabs style 2 (a row under the topbar)
	local TABS_BAR_H = 34
	local TAB_H_STYLE2 = 26

	-- false when "Change icons color" is off: icons stay white and are never recolored
	local tintIcons = type(iconRole("muted")) == "string"

	-- The arrows: the Submit button's icon in one single ImageLabel, rotated on the label
	-- itself (not on a parent frame) and placed with plain offsets, so it renders right
	-- from the first frame. `drop` pushes it down a few pixels inside its button.
	local function arrowIcon(parent, rotation, drop)
		local img = make("ImageLabel", {
			Name = "ArrowIcon",
			Position = UDim2.new(0.5, -8, 0.5, -8 + (drop or 0)),
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			Image = Images.SUBMIT,
			ImageColor3 = iconRole("muted"),
			Rotation = rotation,
			ZIndex = 6,
		}, parent)
		task.spawn(function()
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({ img })
			end)
		end)
		return img
	end

	local function tintArrow(img, color)
		if tintIcons then
			tween(img, 0.15, { ImageColor3 = color })
		end
	end

	local function line(parent, x, y, w, h)
		return make("Frame", {
			Position = UDim2.new(0, x, 0, y),
			Size = UDim2.new(0, w, 0, h),
			BackgroundColor3 = "stroke",
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}, parent)
	end

	---------------------------------------------------------------------------
	-- The page itself: starts one window-height below, hidden
	---------------------------------------------------------------------------
	local page = make("Frame", {
		Name = "Page2",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, H),
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	}, canvas)

	-- Topbar: logo + title on the left, back arrow + close on the right
	local topbar = make("Frame", {
		Name = "Topbar",
		Size = UDim2.new(0, W, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, page)

	make("ImageLabel", {
		Position = UDim2.new(0, 14, 0, 9),
		Size = UDim2.new(0, 24, 0, 20),
		BackgroundTransparency = 1,
		Image = ctx.logo,
		ImageColor3 = logoRole("accent"),
		ScaleType = Enum.ScaleType.Fit,
	}, topbar)

	local pageTitle = make("TextLabel", {
		Position = UDim2.new(0, 46, 0, 0),
		Size = UDim2.new(0, W - 46 - 84, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = ctx.title,
		TextSize = 14,
		TextColor3 = "text",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = FONT_BOLD,
	}, topbar)
	ctx.markTitleFont(pageTitle)

	local function topButton(rightOffset)
		local btn = make("TextButton", {
			Name = "TopButton",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -rightOffset, 0, 6),
			Size = UDim2.new(0, 26, 0, 26),
			BackgroundColor3 = "card",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 5,
		}, topbar)
		make("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)
		return btn
	end

	local closeBtn = topButton(12)
	local closeIcon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Image = Images.CLOSE_ICON,
		ImageColor3 = iconRole("muted"),
		ZIndex = 6,
	}, closeBtn)

	local backBtn = topButton(40)
	local backIcon = arrowIcon(backBtn, BACK_ARROW_ROTATION, 0)

	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.15, { BackgroundTransparency = 0 })
		if tintIcons then
			tween(closeIcon, 0.15, { ImageColor3 = C.text })
		end
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.15, { BackgroundTransparency = 1 })
		if tintIcons then
			tween(closeIcon, 0.15, { ImageColor3 = C.muted })
		end
	end)
	backBtn.MouseEnter:Connect(function()
		tween(backBtn, 0.15, { BackgroundTransparency = 0 })
		tintArrow(backIcon, C.text)
	end)
	backBtn.MouseLeave:Connect(function()
		tween(backBtn, 0.15, { BackgroundTransparency = 1 })
		tintArrow(backIcon, C.muted)
	end)

	-- Tabs style: "1" = column on the left, "2" = row right under the topbar
	local tabsStyle = "1"
	local function normalizeStyle(value)
		value = tostring(value or "1"):lower()
		if value == "2" or value == "horizontal" or value == "row" then
			return "2"
		end
		return "1"
	end
	if ctx.getTabsStyle then
		tabsStyle = normalizeStyle(ctx.getTabsStyle())
	end

	-- Style 1 draws the line under the topbar; style 2 draws it under the row of Tabs
	local topLine = line(page, 14, TOPBAR_H, W - 28, 1)
	local tabsLine = line(page, 14, TOPBAR_H + TABS_BAR_H, W - 28, 1)
	local sideLine = line(page, SIDE_W, TOPBAR_H + 10, 1, H - TOPBAR_H - 20)

	-- Tabs (a column in style 1, a row in style 2)
	local sidebar = make("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollBarThickness = 0,
	}, page)
	local sideLayout = make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	local sidePadding = make("UIPadding", {}, sidebar)

	-- Where the selected Tab's content shows up
	local holder = make("Frame", {
		Name = "TabContent",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, page)

	-- mouse wheel scrolls the row sideways in style 2
	sidebar.InputChanged:Connect(function(input)
		if tabsStyle == "2" and input.UserInputType == Enum.UserInputType.MouseWheel then
			local maxX = math.max(0, sidebar.AbsoluteCanvasSize.X - sidebar.AbsoluteWindowSize.X)
			local x = sidebar.CanvasPosition.X - input.Position.Z * 30
			sidebar.CanvasPosition = Vector2.new(math.clamp(x, 0, maxX), 0)
		end
	end)

	local tabs = {}
	local current = nil

	local function applyTabsStyle()
		local row = tabsStyle == "2"

		topLine.Visible = not row
		sideLine.Visible = not row
		tabsLine.Visible = row

		sidebar.CanvasPosition = Vector2.new(0, 0)
		sidebar.AutomaticCanvasSize = Enum.AutomaticSize.None
		sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
		if row then
			sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_H)
			sidebar.Size = UDim2.new(0, W, 0, TABS_BAR_H)
			sidebar.ScrollingDirection = Enum.ScrollingDirection.X
			sidebar.AutomaticCanvasSize = Enum.AutomaticSize.X
			sideLayout.FillDirection = Enum.FillDirection.Horizontal
			sideLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			sidePadding.PaddingTop = UDim.new(0, 0)
			sidePadding.PaddingBottom = UDim.new(0, 0)
			sidePadding.PaddingLeft = UDim.new(0, 12)
			sidePadding.PaddingRight = UDim.new(0, 12)

			holder.Position = UDim2.new(0, 0, 0, TOPBAR_H + TABS_BAR_H + 1)
			holder.Size = UDim2.new(0, W, 0, H - TOPBAR_H - TABS_BAR_H - 1)
		else
			sidebar.Position = UDim2.new(0, 0, 0, TOPBAR_H + 1)
			sidebar.Size = UDim2.new(0, SIDE_W, 0, H - TOPBAR_H - 1)
			sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
			sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
			sideLayout.FillDirection = Enum.FillDirection.Vertical
			sideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			sidePadding.PaddingTop = UDim.new(0, 10)
			sidePadding.PaddingBottom = UDim.new(0, 10)
			sidePadding.PaddingLeft = UDim.new(0, 10)
			sidePadding.PaddingRight = UDim.new(0, 10)

			holder.Position = UDim2.new(0, SIDE_W + 1, 0, TOPBAR_H + 1)
			holder.Size = UDim2.new(0, W - SIDE_W - 1, 0, H - TOPBAR_H - 1)
		end

		for _, tab in ipairs(tabs) do
			tab.applyStyle()
		end
		if current then
			current.refresh()
		end
	end

	---------------------------------------------------------------------------
	-- Sliding between the Key System and this page
	---------------------------------------------------------------------------
	local opened, moving = false, false

	local function open()
		if opened or moving then
			return
		end
		opened, moving = true, true
		if ctx.onOpen then
			ctx.onOpen()
		end
		if current then
			current.refresh()
		end
		page.Visible = true
		tween(page, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Quint)
		tween(content, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, -H) }, Quint)
		task.delay(SLIDE_TIME + 0.05, function()
			moving = false
		end)
	end

	local function back()
		if not opened or moving then
			return
		end
		opened, moving = false, true
		tween(page, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, H) }, Quint)
		tween(content, SLIDE_TIME, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Quint)
		task.delay(SLIDE_TIME + 0.05, function()
			if not opened then
				page.Visible = false
			end
			moving = false
		end)
	end

	-- Used when the whole UI closes while this page is showing
	local function fadeOut(time)
		if not page.Visible then
			return
		end
		fade(prep(page), 0, time)
		task.delay(time, function()
			page.Visible = false
		end)
	end

	-- The down arrow, in the middle of the bottom of the Key System. It only shows up
	-- once there is at least one Tab, so a script that never creates one doesn't end up
	-- with an arrow that leads to an empty page.
	local nextBtn = make("TextButton", {
		Name = "NextPage",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0, W / 2, 0, H - 2),
		Size = UDim2.new(0, 40, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 5,
	}, content)
	-- Same icon as the Submit button (Images.SUBMIT), turned to point down
	local nextIcon = arrowIcon(nextBtn, NEXT_ARROW_ROTATION, 2)

	nextBtn.MouseEnter:Connect(function()
		tintArrow(nextIcon, C.text)
	end)
	nextBtn.MouseLeave:Connect(function()
		tintArrow(nextIcon, C.muted)
	end)
	nextBtn.MouseButton1Click:Connect(function()
		if not state.ready or state.closing then
			return
		end
		open()
	end)

	backBtn.MouseButton1Click:Connect(function()
		if not state.ready or state.closing then
			return
		end
		back()
	end)
	closeBtn.MouseButton1Click:Connect(function()
		ctx.requestClose()
	end)

	---------------------------------------------------------------------------
	-- Tabs
	---------------------------------------------------------------------------
	local function styleTab(tab, on)
		tween(tab.btn, 0.15, { BackgroundTransparency = on and 0 or 1 })
		tween(tab.bar, 0.15, { BackgroundTransparency = on and 0 or 1 })
		setRole(tab.label, "TextColor3", on and "text" or "muted")
		if tab.iconImage then
			local role = iconRole(on and "accent" or "muted")
			if type(role) == "string" then
				setRole(tab.iconImage, "ImageColor3", role)
			end
		end
		tab.scroll.Visible = on
	end

	-- originals[inst][prop] = the resting transparency of that property, captured only once.
	-- Switching Tabs quickly (while an animation is still running) then never records a
	-- half-faded value as the "normal" one.
	local originals = setmetatable({}, { __mode = "k" })

	local function snapshot(child)
		local items = prep(child)
		for _, it in ipairs(items) do
			local saved = originals[it[1]]
			if not saved then
				saved = {}
				originals[it[1]] = saved
			end
			if saved[it[2]] == nil then
				saved[it[2]] = it[3]
			else
				it[3] = saved[it[2]]
			end
		end
		return items
	end

	-- Plays when a Tab becomes the selected one: the whole content rises a little and
	-- every element (Section / Paragraph) fades in, one after the other.
	local function animateIn(tab)
		tab.animId = (tab.animId or 0) + 1
		local id = tab.animId

		local children = {}
		for _, child in ipairs(tab.scroll:GetChildren()) do
			if child:IsA("GuiObject") then
				children[#children + 1] = child
			end
		end
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		if #children == 0 then
			return
		end

		local lists = {}
		for i, child in ipairs(children) do
			local items = snapshot(child)
			fade(items, 0) -- start fully transparent
			lists[i] = items
		end

		tab.scroll.Position = UDim2.new(0, 0, 0, TAB_SLIDE)
		tween(tab.scroll, TAB_IN_TIME + 0.08, { Position = UDim2.new(0, 0, 0, 0) }, Quint)

		local step = math.min(TAB_STAGGER, TAB_STAGGER_MAX / #children)
		for i, items in ipairs(lists) do
			task.delay((i - 1) * step, function()
				if tab.animId ~= id then
					return -- a newer animation took over this Tab
				end
				fade(items, 1, TAB_IN_TIME)
			end)
		end
	end

	local function selectTab(tab, animate)
		if current == tab then
			return
		end
		if current then
			styleTab(current, false)
		end
		current = tab
		styleTab(tab, true)
		tab.refresh()
		if animate ~= false and (opened or page.Visible) then
			animateIn(tab)
		end
	end

	-- OphynWindow({ Title = "...", Icon = "..." }) -> Tab
	local function createTab(props)
		if type(props) ~= "table" then
			props = { Title = props }
		end
		local title = props.Title ~= nil and tostring(props.Title) or "Tab"
		local image = assetId(props.Icon)

		local tab = {}

		-- Tab button: the icon comes first, then the text. The icon + text live in `inner`
		-- (it holds the layout and the side padding, so the button can size itself to the
		-- text in style 2); the active-tab bar sits on the button itself.
		tab.btn = make("TextButton", {
			Name = "Tab",
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = "card",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = #tabs + 1,
		}, sidebar)
		round(tab.btn, 7)

		tab.bar = make("Frame", {
			Position = UDim2.new(0, 2, 0.5, -8),
			Size = UDim2.new(0, 3, 0, 16),
			BackgroundColor3 = "accent",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, tab.btn)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, tab.bar)

		tab.inner = make("Frame", {
			Name = "Inner",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, tab.btn)
		tab.pad = make("UIPadding", {}, tab.inner)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, tab.inner)

		if image then
			local iconHolder = icon(tab.inner, 0, 0, "muted", image)
			iconHolder.LayoutOrder = 1
			tab.iconImage = iconHolder:FindFirstChild("iconimage")
		end

		tab.label = make("TextLabel", {
			Size = UDim2.new(1, image and -22 or 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = title,
			TextSize = 12,
			TextColor3 = "muted",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = FONT,
			LayoutOrder = 2,
		}, tab.inner)

		-- Lays the button out for the current Tabs style (also runs when the style changes)
		tab.applyStyle = function()
			if tabsStyle == "2" then
				tab.btn.Size = UDim2.new(0, 0, 0, TAB_H_STYLE2)
				tab.btn.AutomaticSize = Enum.AutomaticSize.X
				tab.inner.Size = UDim2.new(0, 0, 1, 0)
				tab.inner.AutomaticSize = Enum.AutomaticSize.X
				tab.pad.PaddingLeft = UDim.new(0, 10)
				tab.pad.PaddingRight = UDim.new(0, 12)
				tab.label.Size = UDim2.new(0, 0, 1, 0)
				tab.label.AutomaticSize = Enum.AutomaticSize.X
				tab.bar.AnchorPoint = Vector2.new(0.5, 1)
				tab.bar.Position = UDim2.new(0.5, 0, 1, -2)
				tab.bar.Size = UDim2.new(1, -16, 0, 2)
			else
				tab.btn.AutomaticSize = Enum.AutomaticSize.None
				tab.btn.Size = UDim2.new(1, 0, 0, 30)
				tab.inner.AutomaticSize = Enum.AutomaticSize.None
				tab.inner.Size = UDim2.new(1, 0, 1, 0)
				tab.pad.PaddingLeft = UDim.new(0, 12)
				tab.pad.PaddingRight = UDim.new(0, 8)
				tab.label.AutomaticSize = Enum.AutomaticSize.None
				tab.label.Size = UDim2.new(1, image and -22 or 0, 1, 0)
				tab.bar.AnchorPoint = Vector2.new(0, 0)
				tab.bar.Position = UDim2.new(0, 2, 0.5, -8)
				tab.bar.Size = UDim2.new(0, 3, 0, 16)
			end
		end
		tab.applyStyle()

		-- The content of this Tab
		tab.scroll = make("ScrollingFrame", {
			Name = "TabContent",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			VerticalScrollBarInset = Enum.ScrollBarInset.None,
			ScrollBarThickness = 2,
			ScrollBarImageTransparency = 0.45,
			Visible = false,
		}, holder)
		setRole(tab.scroll, "ScrollBarImageColor3", "muted")

		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, tab.scroll)
		make("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 14),
		}, tab.scroll)

		tab.refresh = function()
			tab.scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(tab.refresh)

		tab.btn.MouseEnter:Connect(function()
			if current ~= tab then
				tween(tab.btn, 0.12, { BackgroundTransparency = 0.5 })
			end
		end)
		tab.btn.MouseLeave:Connect(function()
			if current ~= tab then
				tween(tab.btn, 0.12, { BackgroundTransparency = 1 })
			end
		end)
		tab.btn.MouseButton1Click:Connect(function()
			if state.closing then
				return
			end
			selectTab(tab)
		end)

		tabs[#tabs + 1] = tab
		if not nextBtn.Visible then
			nextBtn.Visible = true
			-- first time the arrow shows up: make the engine request/draw its image again
			task.defer(function()
				nextIcon.Image = ""
				nextIcon.Image = Images.SUBMIT
			end)
		end
		if not current then
			selectTab(tab, false)
		end

		-- Tab:Section / Tab:Paragraph
		local order = 0
		local function nextOrder()
			order = order + 1
			return order
		end

		local obj = {}

		function obj:Select()
			selectTab(tab)
			return self
		end

		-- Tab:Section({ Title = "...", Icon = "..." }): the icon comes first, then the text
		function obj:Section(p)
			p = type(p) == "table" and p or {}
			local sectionImage = assetId(p.Icon)

			local row = make("Frame", {
				Name = "Section",
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, tab.scroll)
			make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 7),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, row)

			if sectionImage then
				local iconHolder = icon(row, 0, 0, "accent", sectionImage)
				iconHolder.LayoutOrder = 1
			end

			local label = make("TextLabel", {
				Size = UDim2.new(1, sectionImage and -23 or 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = p.Title ~= nil and tostring(p.Title) or "Section",
				TextSize = SECTION_TEXT_SIZE,
				TextColor3 = "text",
				TextTransparency = SECTION_TEXT_TRANSPARENCY,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				FontFace = FONT_BOLD,
				LayoutOrder = 2,
			}, row)

			local section = { Frame = row }
			function section:SetTitle(str)
				label.Text = tostring(str)
				return self
			end
			function section:Destroy()
				row:Destroy()
			end
			return section
		end

		-- Tab:Paragraph({ Title, Desc, Color, Buttons = { { Icon, Title, Callback } } })
		function obj:Paragraph(p)
			p = type(p) == "table" and p or {}
			local color = parseColor(p.Color) -- nil: follows the theme
			local onColor = color and contrastOn(color) or nil

			local box = make("Frame", {
				Name = "Paragraph",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = color or "card",
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, tab.scroll)
			round(box, 8, (not color) and "stroke" or nil)
			make("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}, box)
			make("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, box)

			local function paragraphLabel(layoutOrder, size, font, textColor, str, transparency)
				return make("TextLabel", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = str,
					TextSize = size,
					TextColor3 = textColor,
					TextTransparency = transparency,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					FontFace = font,
					LayoutOrder = layoutOrder,
					Visible = str ~= "",
				}, box)
			end

			local titleText = p.Title ~= nil and tostring(p.Title) or ""
			local descText = p.Desc ~= nil and tostring(p.Desc) or ""
			local titleLabel = paragraphLabel(1, 13, FONT_BOLD, onColor or "text", titleText, 0)
			local descLabel = paragraphLabel(2, 12, FONT, onColor or "muted", descText, onColor and 0.2 or 0)

			local buttons = type(p.Buttons) == "table" and p.Buttons or {}
			if #buttons > 0 then
				local row = make("Frame", {
					Name = "Buttons",
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 3,
				}, box)
				make("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Wraps = true,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, row)

				for i, b in ipairs(buttons) do
					if type(b) == "table" then
						local btn = make("TextButton", {
							Name = "Button",
							Size = UDim2.new(0, 0, 0, 26),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundColor3 = color and onColor or "btn2",
							BackgroundTransparency = color and 0.86 or 0,
							BorderSizePixel = 0,
							AutoButtonColor = false,
							Text = "",
							LayoutOrder = i,
						}, row)
						round(btn, 7, (not color) and "stroke" or nil)
						make("UIPadding", {
							PaddingLeft = UDim.new(0, 9),
							PaddingRight = UDim.new(0, 10),
						}, btn)
						make("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, 6),
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}, btn)

						-- icon first, then the text
						local buttonImage = assetId(b.Icon)
						if buttonImage then
							local iconHolder = icon(btn, 0, 0, onColor or "text", buttonImage)
							iconHolder.LayoutOrder = 1
						end
						make("TextLabel", {
							Size = UDim2.new(0, 0, 1, 0),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = b.Title ~= nil and tostring(b.Title) or "Button",
							TextSize = 12,
							TextColor3 = onColor or "text",
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							FontFace = FONT,
							LayoutOrder = 2,
						}, btn)

						btn.MouseEnter:Connect(function()
							if color then
								tween(btn, 0.12, { BackgroundTransparency = 0.72 })
							else
								tween(btn, 0.12, { BackgroundColor3 = C.btn2Hover })
							end
						end)
						btn.MouseLeave:Connect(function()
							if color then
								tween(btn, 0.12, { BackgroundTransparency = 0.86 })
							else
								tween(btn, 0.12, { BackgroundColor3 = C.btn2 })
							end
						end)
						btn.MouseButton1Click:Connect(function()
							if state.closing or type(b.Callback) ~= "function" then
								return
							end
							task.spawn(function()
								local ok, err = pcall(b.Callback)
								if not ok then
									warn("[Ophyn] Button callback error: " .. tostring(err))
								end
							end)
						end)
					end
				end
			end

			local paragraph = { Frame = box }
			function paragraph:SetTitle(str)
				titleLabel.Text = tostring(str)
				titleLabel.Visible = titleLabel.Text ~= ""
				return self
			end
			function paragraph:SetDesc(str)
				descLabel.Text = tostring(str)
				descLabel.Visible = descLabel.Text ~= ""
				return self
			end
			function paragraph:Destroy()
				box:Destroy()
			end
			return paragraph
		end

		return obj
	end

	applyTabsStyle()

	-- KeySystem:SetTabsStyle("1" / "2") works before or after the window exists: ui.lua
	-- calls this applier whenever the style changes. It returns false once the window is gone.
	if ctx.registerTabsStyle then
		ctx.registerTabsStyle(function()
			if not page.Parent then
				return false
			end
			local style = normalizeStyle(ctx.getTabsStyle and ctx.getTabsStyle())
			if style ~= tabsStyle then
				tabsStyle = style
				applyTabsStyle()
			end
			return true
		end)
	end

	return {
		createTab = createTab,
		open = open,
		back = back,
		fadeOut = fadeOut,
		isOpen = function()
			return opened
		end,
	}
end

return Pages
