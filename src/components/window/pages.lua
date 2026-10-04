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

	local SECTION_TEXT_SIZE = 15
	local SECTION_TEXT_TRANSPARENCY = 0.35

	local TAB_SLIDE = 10
	local TAB_IN_TIME = 0.32
	local TAB_STAGGER = 0.045
	local TAB_STAGGER_MAX = 0.4

	local NEXT_ARROW_ROTATION = 90

	local tintIcons = type(iconRole("muted")) == "string"

	local function chevron(parent, down, role, scale)
		scale = scale or 1
		local cw, ch = 16 * scale, 10 * scale
		local holder = make("Frame", {
			Size = UDim2.new(0, cw, 0, ch),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, parent)

		local arm = 7.5 * scale
		local dx = arm / 2 * math.cos(math.rad(40))
		local dy = arm / 2 * math.sin(math.rad(40))
		local tipX = cw / 2
		local tipY = down and (ch - 2 * scale) or (2 * scale)
		local lift = down and -dy or dy

		local bars = {}
		for _, side in ipairs({ -1, 1 }) do
			local bar = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, tipX + side * dx, 0, tipY + lift),
				Size = UDim2.new(0, arm + 1, 0, math.max(2, 2 * scale)),
				Rotation = (down and -side or side) * 40,
				BackgroundColor3 = role,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
			}, holder)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
			bars[#bars + 1] = bar
		end
		return holder, bars
	end

	local function tintBars(bars, color)
		for _, bar in ipairs(bars) do
			tween(bar, 0.15, { BackgroundColor3 = color })
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

	local page = make("Frame", {
		Name = "Page2",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, H),
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	}, canvas)

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
	local backChevron, backBars = chevron(backBtn, false, "muted", 0.9)
	backChevron.AnchorPoint = Vector2.new(0.5, 0.5)
	backChevron.Position = UDim2.new(0.5, 0, 0.5, 0)

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
		tintBars(backBars, C.text)
	end)
	backBtn.MouseLeave:Connect(function()
		tween(backBtn, 0.15, { BackgroundTransparency = 1 })
		tintBars(backBars, C.muted)
	end)

	line(page, 14, TOPBAR_H, W - 28, 1)

	local sidebar = make("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.new(0, 0, 0, TOPBAR_H + 1),
		Size = UDim2.new(0, SIDE_W, 0, H - TOPBAR_H - 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollBarThickness = 0,
	}, page)
	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, sidebar)

	line(page, SIDE_W, TOPBAR_H + 10, 1, H - TOPBAR_H - 20)

	local holder = make("Frame", {
		Name = "TabContent",
		Position = UDim2.new(0, SIDE_W + 1, 0, TOPBAR_H + 1),
		Size = UDim2.new(0, W - SIDE_W - 1, 0, H - TOPBAR_H - 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, page)

	local opened, moving = false, false
	local current = nil

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

	local function fadeOut(time)
		if not page.Visible then
			return
		end
		fade(prep(page), 0, time)
		task.delay(time, function()
			page.Visible = false
		end)
	end

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

	local nextIcon = icon(nextBtn, 0, 0, "muted", Images.SUBMIT)
	nextIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	nextIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	nextIcon.Rotation = NEXT_ARROW_ROTATION
	local nextIconImage = nextIcon:FindFirstChild("iconimage")

	local function tintNext(color)
		if tintIcons and nextIconImage then
			tween(nextIconImage, 0.15, { ImageColor3 = color })
		end
	end

	nextBtn.MouseEnter:Connect(function()
		tintNext(C.text)
	end)
	nextBtn.MouseLeave:Connect(function()
		tintNext(C.muted)
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

	local tabs = {}

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
			fade(items, 0)
			lists[i] = items
		end

		tab.scroll.Position = UDim2.new(0, 0, 0, TAB_SLIDE)
		tween(tab.scroll, TAB_IN_TIME + 0.08, { Position = UDim2.new(0, 0, 0, 0) }, Quint)

		local step = math.min(TAB_STAGGER, TAB_STAGGER_MAX / #children)
		for i, items in ipairs(lists) do
			task.delay((i - 1) * step, function()
				if tab.animId ~= id then
					return
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

	local function createTab(props)
		if type(props) ~= "table" then
			props = { Title = props }
		end
		local title = props.Title ~= nil and tostring(props.Title) or "Tab"
		local image = assetId(props.Icon)

		local tab = {}

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

		local textX = 12
		if image then
			local iconHolder = icon(tab.btn, 12, 7, "muted", image)
			tab.iconImage = iconHolder:FindFirstChild("iconimage")
			textX = 34
		end

		tab.label = make("TextLabel", {
			Position = UDim2.new(0, textX, 0, 0),
			Size = UDim2.new(1, -(textX + 8), 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = title,
			TextSize = 12,
			TextColor3 = "muted",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = FONT,
		}, tab.btn)

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
		nextBtn.Visible = true
		if not current then
			selectTab(tab, false)
		end

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

		function obj:Paragraph(p)
			p = type(p) == "table" and p or {}
			local color = parseColor(p.Color)
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
