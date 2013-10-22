--------------------------------------------------------------
-- SETUP -----------------------------------------------------

local globals  = require( "libs.globals" )
local widget   = require( "widget" )

--------------------------------------------------------------
-- GRAPHICS LIBRARY ------------------------------------------

-- Set up 
local class = {}
local mMax  = math.max

--------------------------------------------------------------
-- FUNCTIONS -------------------------------------------------

function class.newWindow( params )

	params = params or {}
	if params.area then
		params.x      = params.area.x
		params.y      = params.area.y
		params.width  = params.area.width
		params.height = params.area.height
	end
	
	local group = display.newGroup()

	-- Convert from spacing to tiles
	local corner    = 16
	local center    = 32
	local sheetData =
	{
		sheetContentWidth  = 64,
		sheetContentHeight = 64,
		frames             =
		{
			{ x = 0,               y = 0,               width = corner, height = corner },
			{ x = corner,          y = 0,               width = center, height = corner },
			{ x = corner + center, y = 0,               width = corner, height = corner },
			{ x = 0,               y = corner,          width = corner, height = center },
			{ x = corner,          y = corner,          width = center, height = center },
			{ x = corner + center, y = corner,          width = corner, height = center },
			{ x = 0,               y = corner + center, width = corner, height = corner },
			{ x = corner,          y = corner + center, width = center, height = corner },
			{ x = corner + center, y = corner + center, width = corner, height = corner },
		},
	}
	
	-- Create the image sheet
	local imageSheet = graphics.newImageSheet( params.image or globals.themePath .. "gfx/frameborder-1.png", sheetData )

	-- Window size
	local windowX            = params.x or 0
	local windowY            = params.y or 0
	local windowWidth        = params.width or 100
	local windowHeight       = params.height or 100
	local windowCenterWidth  = windowWidth - corner * 2
	local windowCenterHeight = windowHeight - corner * 2

	group.x, group.y = windowX, windowY

	-- Create the window, using 9 piece
	local tileTL       = display.newImageRect( group, imageSheet, 1, corner, corner )
	tileTL:setReferencePoint( display.TopLeftReferencePoint )
	tileTL.x, tileTL.y = 0, 0
	local tileT        = display.newImageRect( group, imageSheet, 2, windowCenterWidth, corner )
	tileT:setReferencePoint( display.TopLeftReferencePoint )
	tileT.x, tileT.y   = corner, 0
	local tileTR       = display.newImageRect( group, imageSheet, 3, corner, corner )
	tileTR:setReferencePoint( display.TopLeftReferencePoint )
	tileTR.x, tileTR.y = corner + windowCenterWidth, 0

	local tileL        = display.newImageRect( group, imageSheet, 4, corner, windowCenterHeight )
	tileL:setReferencePoint( display.TopLeftReferencePoint )
	tileL.x, tileL.y   = 0, corner
	local tileC        = display.newImageRect( group, imageSheet, 5, windowCenterWidth, windowCenterHeight )
	tileC:setReferencePoint( display.TopLeftReferencePoint )
	tileC.x, tileC.y   = corner, corner
	local tileR        = display.newImageRect( group, imageSheet, 6, corner, windowCenterHeight )
	tileR:setReferencePoint( display.TopLeftReferencePoint )
	tileR.x, tileR.y   = corner + windowCenterWidth, corner

	local tileBL       = display.newImageRect( group, imageSheet, 7, corner, corner )
	tileBL:setReferencePoint( display.TopLeftReferencePoint )
	tileBL.x, tileBL.y = 0, windowCenterHeight + corner
	local tileB        = display.newImageRect( group, imageSheet, 8, windowCenterWidth, corner )
	tileB:setReferencePoint( display.TopLeftReferencePoint )
	tileB.x, tileB.y   = corner, windowCenterHeight + corner
	local tileBR       = display.newImageRect( group, imageSheet, 9, corner, corner )
	tileBR:setReferencePoint( display.TopLeftReferencePoint )
	tileBR.x, tileBR.y = corner + windowCenterWidth, windowCenterHeight + corner
	
	-- Store data in group
	group.window = { tileTL, tileT, tileTR, tileL, tileC, tileR, tileBL, tileB, tileBR }

	-- Set various paramaters if supplied
	for i = 1, 9 do
		if params.tint then  group.window[ i ]:setFillColor( params.tint[ 1 ], params.tint[ 2 ], params.tint[ 3 ] ) ; end
		if params.alpha then group.window[ i ].alpha = params.alpha ; end
	end
	
	-- Create title editing function
	function group:setTitle( title )
		if self.titleText then self.titleText.text = title ; end
	end
	
	-- Create title if passed
	if params.title then
		local title = display.newText( group, params.title, 0, 0, params.font, 12 )
		title.x     = windowWidth / 2
		title.y     = 14
		title:setTextColor( 255, 255, 255 )

		local titleLine = display.newLine( group, 6, 24, windowWidth - 6, 24 )
		titleLine:setColor( 0, 0, 0, 127 )
		titleLine:toBack()

		local titleBG = display.newRect( group, 6, 6, windowWidth - 12, 18 )
		titleBG:setFillColor( 0, 0, 0, 127 )
		titleBG:toBack()
		
		-- Store title
		group.titleText = title
	end
	
	-- Insert group if group is passed
	if params.group then params.group:insert( group ) ; end
		
	-- Return the container group
	return group

end

function class.newSegmentedControl( params )
	
	-- Used later on
	local imageSheet, frame, frameSize

	-- Create the control
	local self      = display.newGroup()
	self.onPress    = params.onPress or false
	self.labelColor = params.labelColor
	self.id         = params.id or "better_segmentedControl"
	self.enabled    = true
	local height    = params.height
	local width     = params.width or false
	
	-- Create the press function
	function self.onPressListener( event )

		-- Ignore if not enabled
		if self.enabled == false then return false ; end
		
		-- Only process 'began' events
		if event.phase ~= "began" then return false ; end
		
		-- Select the segment
		self:setSegmentActive( event.target.segmentNumber )

		-- Call the onPress
		if type( self.onPress ) == "function" then self.onPress( event ) ; end
		
		-- Stop processing
		return true
	end
	
	-- Need to know how many segments are asked for
	local totalSegments
	if params.segments then
		if params.segmentImages then totalSegments = math.min( #params.segments, #params.segmentImages )
		else                         totalSegments = #params.segments ; end
	else
		totalSegments = #params.segmentImages
	end
	imageSheet, frame, size = class.getThemeImage( "segmentedControl_left" )
	local leftSize          = size.width
	imageSheet, frame, size = class.getThemeImage( "segmentedControl_right" )
	local rightSize         = size.width

	-- Create the contents (done before segment creation in case size is relative to contents)
	local segments = {}
	self.segments  = segments
	local segmentX = 0
	local width    = 0
	local spacing  = params.segmentSpacing or 5
	for i = 1, totalSegments do
		local x            = 0
		local segment      = { default = {}, over = {}, label = false, x = 0, width = 0 }
		segments[ i ]      = segment
		local segmentGroup = display.newGroup()
		segment.group      = segmentGroup
		self:insert( segmentGroup )

		-- Create icon if it exists
		if params.segmentImages and params.segmentImages[ i ] then

			-- What type of image data is being passed?
			local images    = params.segmentImages[ i ]
			local image
			if type( images ) == "string" then images = { images } ; end
			local imageRect = true
			if images.default == nil  then imageRect = false ; end
			if imageRect == true then
				for k, v in pairs( images ) do
					image                             = display.newImageRect( unpack( v ) )		
					image:setReferencePoint( display.CenterLeftReferencePoint )
					segmentGroup:insert( image )
					image.x                           = x
					segment[ k ][ #segment[ k ] + 1 ] = image
				end
			else
				image            = display.newImage( unpack( images ) )
				segmentGroup:insert( image )
				if params.imagesHeight then
					image.width  = math.floor( image.width * params.imagesHeight / image.height )
					image.height = params.imagesHeight
				end
				image:setReferencePoint( display.CenterLeftReferencePoint ) -- Must be after setting width and height
				image.x, image.y = x, 0
			end
			x = x + image.width + spacing
		end

		-- Create text if it exists
		if params.segments and params.segments[ i ] then
			local label   = display.newText( segmentGroup, params.segments[ i ], 0, 0, params.labelFont or native.systemFont, params.labelSize or 12 )
			label:setReferencePoint( display.CenterLeftReferencePoint )
			label.x       = x
			label.y       = ( params.labelYOffset or 0 )
			segment.label = label
			if self.labelColor then label:setTextColor( unpack( self.labelColor.default ) ) ; end
		end

		-- Store the items
		segment.x     = segmentX
		segment.width = params.segmentWidth or ( segmentGroup.contentWidth + spacing * 2 )
		segmentX      = segmentX + segment.width
	end

	-- If a width for the control is supplied, rejigger the widths of the segments to make it fit
	if params.width then
		
		-- Find average segment width
		local segmentWidth = math.floor( params.width / totalSegments )
		local segmentFixes = width - ( segmentWidth * totalSegments )

		-- Calculate new X and width parameters for the segments
		local x = 0
		for i = 1, totalSegments do
			local width         = segmentWidth
			if i <= segmentFixes then width = width + 1 ; end
			segments[ i ].x     = x
			segments[ i ].width = width
			x                   = x + width
		end
	end

	-- Display the various controls
	local dividerGroup = display.newGroup()
	self:insert( dividerGroup )
	local widthOffset  = math.floor( ( segments[ #segments ].x + segments[ #segments ].width ) / -2 )
	for i = 1, totalSegments do
		local segment      = segments[ i ]
		local x            = segment.x + widthOffset --+ offsetX
		local segmentWidth = segment.width

		-- Create on and off versions
		for k, v in pairs( { default = "", over = "On" } ) do

			-- Create left or right if needed
			local centerOffset = 0
			local centerWidth  = segmentWidth
			if i == 1 then
				imageSheet, frame, size           = class.getThemeImage( "segmentedControl_left" .. v )	
				local image                       = display.newImageRect( self, imageSheet, frame, leftSize, height or size.height )
				image:setReferencePoint( display.CenterLeftReferencePoint )
				image.x                           = x
				segment[ k ][ #segment[ k ] + 1 ] = image
				centerOffset                      = leftSize
				centerWidth                       = segmentWidth - leftSize

			end
			if i == totalSegments then
				imageSheet, frame, size           = class.getThemeImage( "segmentedControl_right" .. v )	
				local image                       = display.newImageRect( self, imageSheet, frame, rightSize, height or size.height )
				image:setReferencePoint( display.CenterRightReferencePoint )
				image.x                           = x + segmentWidth
				segment[ k ][ #segment[ k ] + 1 ] = image
				centerWidth                       = segmentWidth - rightSize
			end

			-- Create center
			imageSheet, frame, size           = class.getThemeImage( "segmentedControl_middle" .. v )	
			local image                       = display.newImageRect( self, imageSheet, frame, centerWidth, height or size.height )
			image:setReferencePoint( display.CenterLeftReferencePoint )
			image.x                           = x + centerOffset
			segment[ k ][ #segment[ k ] + 1 ] = image

		end

		-- Create the divider
		if i > 1 then
			imageSheet, frame, size = class.getThemeImage( "segmentedControl_divider" )	
			local image             = display.newImageRect( dividerGroup, imageSheet, frame, size.width, height or size.height )
			image:setReferencePoint( display.CenterLeftReferencePoint )
			image.x                 = x - math.floor( size.width / 2 )
		end

		-- Position the content group correctly
		segment.group:toFront()
		segment.group.x = segment.x + widthOffset + math.floor( ( segment.width - segment.group.contentWidth ) / 2 )

		-- Add in the event listener
		for j = 1, #segment.default do
			segment.default[ j ].segmentNumber = i
			segment.default[ j ]:addEventListener( "touch", self.onPressListener )
		end
	end
	dividerGroup:toFront()

	-- Create some feature functions
	function self:setEnabled( state )
		if state == nil then state = true ; end
		self.enabled = state
	end

	-- Return the current segment
	function self:getSegmentActive()
	
		return self.currentItem
	
	end

	-- Deselect the segment
	function self:setSegmentInactive( item )
		item          = item or self.currentItem
		local segment = segments[ item ]
		for i = 1, #segment.default do
			segment.over[ i ].isVisible    = false
			segment.default[ i ].isVisible = true
		end
		if segment.label ~= false and self.labelColor then segment.label:setTextColor( unpack( self.labelColor.default ) ) ; end
	end

	function self:setSegmentActive( item )

		-- Deselect the current selection
		self:setSegmentInactive()

		-- Set and then select the current one
		self.currentItem = item
		local segment    = segments[ item ]
		for i = 1, #segment.default do
			segment.over[ i ].isVisible   = true
			segment.default[ i ].isVisible = false
		end
		if segment.label ~= false and self.labelColor then segment.label:setTextColor( unpack( self.labelColor.over ) ) ; end
	end

	-- Set up (hide all deselected, then select the required)
	self.currentItem = 1
	for i = 1, totalSegments do
		self:setSegmentInactive( i )
	end
	self:setSegmentActive( params.defaultSegment or 1 )

	-- Position the group
	self.x = params.left or 0
	self.y = params.top or 0
	if params.group then params.group:insert( self ) ; end

	-- Return the object
	return self

end
function class.newTabBar( params )

	-- Used later on
	local imageSheet, frame, frameSize

	-- Create the control
	local self   = display.newGroup()
	if params.parent then params.parent:insert( self ) ; end
	self.x             = params.left or 0
	self.y             = params.top or 0
	local width        = params.width or display.contentWidth
	local height       = params.height or 50	
	local totalButtons = #params.buttons

	-- Handle presses
	function self._touch( event )
		if event.phase == "began" then

			-- Select this
			local index = event.target.index

			-- If this is already selected, only continue if multiple presses are allowed
			local sameSelected = ( self._selected == index )
			if sameSelected == false then self:setSelected( index ) ; end

			-- Pass the event on if different or if multipress is enabled
			if sameSelected == false or ( sameSelected == true and self.buttons[ index ].multiPress == true ) then
				if type( self.buttons[ index ].onPress ) == "function" then self.buttons[ index ].onPress( event ) ; end
			end
		end
		
		-- Stop any further propogation
		return true	
	end

	-- Function to find the index from a title
	function self:findIndex( title )
		if type( title ) == "string" then
			local index
			for i = 1, totalButtons do
				if self.buttons[ i ].id == title then
					index = i
					break
				end
			end		
			return index
		else
			return title or 1
		end
	end

	-- Select a tab
	function self:setSelected( index, triggerPress )
		self._selected = index
		index          = self:findIndex( index ) or 1
		triggerPress   = triggerPress or false

		-- Deselect everything
		for i = 1, totalButtons do
			local button = self.buttons[ i ]
			if i == index then
				if button.groups.default then button.groups.default.isVisible = false ; end
				if button.groups.over then    button.groups.over.isVisible = true ; end
				if button.label and button.labelColors then button.label:setTextColor( unpack( button.labelColors.over ) ) ; end
			else
				if button.groups.default then button.groups.default.isVisible = true ; end
				if button.groups.over then    button.groups.over.isVisible = false ; end
				if button.label and button.labelColors then button.label:setTextColor( unpack( button.labelColors.default ) ) ; end
			end			
		end
	end

	-- Set up background
	imageSheet, frame, size = class.getThemeImage( "tabBar_background" )
	local image             = display.newImageRect( self, imageSheet, frame, width, height )
	image:setReferencePoint( display.TopLeftReferencePoint )
	image.x, image.y        = 0, 0
	image:addEventListener( "tap", function() return true ; end )
	image:addEventListener( "touch", function() return true ; end )

	-- Set up the buttons
	-- They will be evenly spaced across the width
	-- And will run off of invisible rectangles for touch detection
	local buttons     = {}
	self.buttons      = buttons
	local buttonWidth = math.floor( width / totalButtons )
	for i = 1, totalButtons do
		local button = params.buttons[ i ]

		-- Create group for the button
		local group = display.newGroup()
		self:insert( group )
		group.x     = math.floor( ( i - 0.5 ) * width / totalButtons )

		-- Create the actual touch zone
		local rect = display.newRect( group, 0, 0, buttonWidth - 2, height - 2 )
		rect:setReferencePoint( display.TopLeftReferencePoint )
		rect:setFillColor( 0, 0, 0, 0 )
		rect.x     = 1 - buttonWidth / 2
		rect.y     = 1
		rect:addEventListener( "touch", self._touch )
		rect.index = i

		-- Create icons
		local defaultGroup
		if button.defaultFile then
			defaultGroup = display.newGroup()
			group:insert( defaultGroup )
			local icon = display.newImageRect( defaultGroup, button.defaultFile, button.baseDir or system.ResourceDirectory, button.width or buttonWidth, button.height or height )
			icon.x     = button.iconXOffset or 0
			icon.y     = math.floor( height / 2 ) + ( button.iconYOffset or 0 ) - 5
		end

		local overGroup
		if button.overFile then
			overGroup = display.newGroup()
			group:insert( overGroup )
			local icon = display.newImageRect( overGroup, button.overFile, button.baseDir or system.ResourceDirectory, button.width or buttonWidth, button.height or height )
			icon.x     = button.iconXOffset or 0
			icon.y     = math.floor( height / 2 ) + ( button.iconYOffset or 0 ) - 5
		end

		-- Create label
		local text
		if button.label then
			text   = display.newText( group, button.label, 0, 0, button.font, button.fontSize or 12 )
			text:setReferencePoint( display.BottomCenterReferencePoint )
			text.x = -( button.labelXOffset or 0 )
			text.y = height - ( button.labelYOffset or 0 ) - 1
			if button.labelColor then text:setTextColor( unpack( button.labelColor.over ) ) ; end
		end

		-- Store values
		buttons[ i ] = {
			id          = button.id,
			labelColors = button.labelColor or false,			
			label       = text,
			selected    = button.selected or false,
			multiPress  = button.multiPress or false,
			onPress     = button.onPress,
			groups      = {
				 all     = group,
				 over    = overGroup,
				 default = defaultGroup,
			},
		}
	end	

	-- Find first specified if using .selected
	local selectedTab = 1
	for i = 1, totalButtons do
		if self.buttons[ i ].selected == true then
			selectedTab = i
			break
		end
	end
	if params.startTab then selectedTab = self:findIndexFromID( params.startTab ) ; end

	-- Select a single option
	self:setSelected( selectedTab )

	-- Return the object
	return self

end
function class.newButton( params )

	-- Used later on
	local imageSheet, frame, frameSize

    -- Set up values
    local self       = display.newGroup( params.group )
	self._label      = params.label or false
	self._labelColor = params.labelColor
	self._state      = false
	self._isEnabled  = true
	self._isFocus    = false
	self._within     = false
	self._onPress    = params.onPress
	self._onRelease  = params.onRelease
	self._onEvent    = params.onEvent

	-- Set up groups to hold all images
	self._default      = display.newGroup()
	self:insert( self._default )
	self._over         = display.newGroup()
	self:insert( self._over )
	self._defaultIcons = display.newGroup()
	self:insert( self._defaultIcons )
	self._overIcons    = display.newGroup()
	self:insert( self._overIcons )
	self._useOver      = false
	self._useOverIcon  = false

	-- How are the images specified?
	if params.defaultFile then
		local image = display.newImage( self._default, params.defaultFile, params.baseDir )
		image.x     = 0
		image.y     = 0
		if params.overFile then		
			local image     = display.newImage( self._over, params.overFile, params.baseDir )
			image.x         = 0
			image.y         = 0
			self._useOver   = true			
		end

		-- Frames from sprite sheet (if sheet not supplied then from theme)
	elseif params.sheet then

		-- Use 9 slice or 2 frames?
		if params.defaultFrame then
		else
		end

		-- Frames from the theme sprite sheet
	elseif params.defaultFrame then
		local imageSheet, frame, size = class.getThemeImage( params.defaultFrame )
		image                         = display.newImageRect( self._default, imageSheet, frame, params.width or size.width, params.height or size.height )
		image.x     = 0
		image.y     = 0
		if params.overFrame then	
			local imageSheet, frame, size = class.getThemeImage( params.overFrame )
			image                         = display.newImageRect( self._over, imageSheet, frame, params.width or size.width, params.height or size.height )
			image.x       = 0
			image.y       = 0
			self._useOver = true			
		end

		-- Create some crappy rectangles
	elseif params.useRects == true then
		local rect = display.newRect( 0, 0, params.width or 200, params.height or 50 )
		if params.rectColors then rect:setFillColor( unpack( params.rectColors.default ) )
		else                      rect:setFillColor( 0.5, 0.5, 0.5, 0.75 ) ; end
		self._default:insert( rect )

		local rect     = display.newRect( 0, 0, params.width or 200, params.height or 50 )
		if params.rectColors then rect:setFillColor( unpack( params.rectColors.over ) )
		else                      rect:setFillColor( 0, 0, 0, 0.75 ) ; end
		self._over:insert( rect )
		rect.x         = 0
		rect.y         = 0
		self._useOver   = true			

		-- Use the standard widget slice theme
	else
		self._useOver = true

		-- Get the slice values
		local sheet
		local slices     = {}
		local sliceNames = {
			"topLeft",
			"topMiddle",
			"topRight",
			"bottomLeft",
			"bottomMiddle",
			"bottomRight",
			"middleLeft",
			"middle",
			"middleRight",

			"topLeftOver",
			"topMiddleOver",
			"topRightOver",
			"bottomLeftOver",
			"bottomMiddleOver",
			"bottomRightOver",
			"middleLeftOver",
			"middleOver",
			"middleRightOver",
		}
		for i = 1, #sliceNames do
			local frame, size
			local sliceName     = sliceNames[ i ]
			sheet, frame, size  = class.getThemeImage( "button_" .. sliceName )
			local width, height = size.width, size.height
			slices[ sliceName ] = { frame = frame, size = size }
		end

		-- Get sizes
		local width  = params.width
		local height = params.height
		local left   = -math.floor( width / 2 )
		local top    = -math.floor( height / 2 )
		
		local leftWidth    = slices.middleLeft.size.width
		local rightWidth   = slices.middleRight.size.width
		local topHeight    = slices.topMiddle.size.height
		local bottomHeight = slices.bottomMiddle.size.height
		local middleWidth  = width - leftWidth - rightWidth
		local middleHeight = height - topHeight - bottomHeight

		local xMid   = left + leftWidth
		local right  = left + leftWidth + middleWidth
		local yMid   = top + topHeight
		local bottom = top + topHeight + middleHeight

		-- Create the actual image slices
		local slicesLayout = {
			topLeft          = { self._default, left,  top,    leftWidth,   topHeight }, 
			topMiddle        = { self._default, xMid,  top,    middleWidth, topHeight }, 
			topRight         = { self._default, right, top,    rightWidth,  topHeight }, 
			bottomLeft       = { self._default, left,  bottom, leftWidth,   bottomHeight }, 
			bottomMiddle     = { self._default, xMid,  bottom, middleWidth, bottomHeight }, 
			bottomRight      = { self._default, right, bottom, rightWidth,  bottomHeight }, 
			middleLeft       = { self._default, left,  yMid,   leftWidth,   middleHeight }, 
			middle           = { self._default, xMid,  yMid,   middleWidth, middleHeight }, 
			middleRight      = { self._default, right, yMid,   rightWidth,  middleHeight }, 

			topLeftOver      = { self._over, left,  top,    leftWidth,   topHeight }, 
			topMiddleOver    = { self._over, xMid,  top,    middleWidth, topHeight }, 
			topRightOver     = { self._over, right, top,    rightWidth,  topHeight }, 
			bottomLeftOver   = { self._over, left,  bottom, leftWidth,   bottomHeight }, 
			bottomMiddleOver = { self._over, xMid,  bottom, middleWidth, bottomHeight }, 
			bottomRightOver  = { self._over, right, bottom, rightWidth,  bottomHeight }, 
			middleLeftOver   = { self._over, left,  yMid,   leftWidth,   middleHeight }, 
			middleOver       = { self._over, xMid,  yMid,   middleWidth, middleHeight }, 
			middleRightOver  = { self._over, right, yMid,   rightWidth,  middleHeight }, 
		}
		for k, v in pairs( slicesLayout ) do
			local sliceData = slices[ k ]
			local image     = display.newImageRect( sheet, sliceData.frame, v[ 4 ], v[ 5 ] )
			image:setReferencePoint( display.TopLeftReferencePoint )
			v[ 1 ]:insert( image )
			image.x         = v[ 2 ]
			image.y         = v[ 3 ]
		end
	end

	-- Icons
	if params.icons then
		self._useOverIcons = true
		for k, v in pairs( params.icons ) do
			local image, group
			if k == "defaultFile" or k == "overFile" then
				if type( v ) == "table" then
					if #v == 3 then image = display.newImageRect( unpack( v ) )
					else            image = display.newImage( unpack( v ) ) ; end
				else
					image = display.newImage( v )
				end
				if k == "defaultFile" then group = self._defaultIcons
				else                       group = self._overIcons ; end
			else
				local imageSheet, frame, size = class.getThemeImage( v )
				image                         = display.newImageRect( imageSheet, frame, size.width, size.height )
				if k == "defaultFrame" then group = self._defaultIcons
				else                        group = self._overIcons ; end
			end
						
			group:insert( image )
			image.x = params.iconXOffset or 0
			image.y = params.iconYOffset or 0
		end
	end
	if params.iconFile then
		local image
		if type( params.iconFile ) == "table" then
			if #params.iconFile == 3 then image = display.newImageRect( unpack( params.iconFile ) )
			else                          image = display.newImage( unpack( params.iconFile ) ) ; end
		else
			image = display.newImage( params.iconFile )
		end
		self:insert( image )
		image.x = params.iconXOffset or 0
		image.y = params.iconYOffset or 0
	elseif params.iconFrame then
		local imageSheet, frame, size = class.getThemeImage( params.iconFrame )
		local image                   = display.newImageRect( imageSheet, frame, size.width, size.height )
		self:insert( image )
		image.x = params.iconXOffset or 0
		image.y = params.iconYOffset or 0
	end

	-- Create the label
	if self._label ~= false then
		local label
		if params.embossedLabel then label = display.newEmbossedText( self, params.label, 0, 0, params.labelFont or native.systemFont, params.fontSize or 12 )
		else                         label = display.newText( self, params.label, 0, 0, params.labelFont or native.systemFont, params.labelSize or 12 ) ; end
		label.x     = params.labelXOffset or 0
		label.y     = params.labelYOffset or 0
		self._label = label
		if self._labelColor then label:setTextColor( unpack( self._labelColor.default ) ) ; end
	end

	-- Ability to enable and disable button
	function self:setEnabled( state )
	
		self._isEnabled = state
		if state == false then self:setState( "default" ) ; end

	end
	
	-- Create the state function
	function self:setState( state )
		if state == self._state then return ; end
		self._state = state

		-- Text
		if self._label and self._labelColor then self._label:setTextColor( unpack( self._labelColor[ state ] ) ) ; end

		-- Buttons
		if self._useOver then
			self._default.isVisible = ( state == "default" )
			self._over.isVisible    = not self._default.isVisible
		end
		
		-- Icons
		if self._useOverIcons then
			self._defaultIcons.isVisible = ( state == "default" )
			self._overIcons.isVisible    = not self._defaultIcons.isVisible
		end
	end

	-- Is an event within the button
	function self:_isWithin( x, y )
		local bounds = self.contentBounds
		if "table" == type( bounds ) then
			if "number" == type( x ) and "number" == type( y ) then
				return bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
			end
		end
		return false
	end

	-- Create the press function
	function self:touch( event )
		if not self._isEnabled then return ; end

		local phase = event.phase
		if "began" == phase then
			self:setState( "over" )
			if self._onPress and not self._onEvent then self._onPress( event ) ; end

			-- If the parent group still exists carry on processing
			if "table" == type( self.parent ) then
				self._isFocus  = true
				self._within   = true
				display.getCurrentStage():setFocus( self, event.id )
			end

		elseif self._isFocus then
			if "moved" == phase then
				local within = self:_isWithin( event.x, event.y )
				if within ~= self._within then
					self._within = within
					if within then self:setState( "over" )
					else           self:setState( "default" ) ; end
				end

			elseif "ended" == phase or "cancelled" == phase then
				local within = self:_isWithin( event.x, event.y )
				if within and self._onRelease and not self._onEvent then self._onRelease( event ) ; end

				self:setState( "default" )				

				-- Remove focus from the button
				self._isFocus = false
				display.getCurrentStage():setFocus( nil )
			end
		end

		-- If there is a onEvent method ( and not a onPress or onRelease method ) call it
		if self._onEvent and not self._onPress and not self._onRelease then
			if not self._isWithin( event.x, event.y ) and "ended" == phase then event.phase = "cancelled" ; end
			self._onEvent( event )
		end
		
		-- This button always sucks up events!
		return true
	end

	-- Set state
	self:setState( "default" )

	-- Set the event listeners
	self:addEventListener( "touch" )

	-- Make the button a child if parent was supplied
	if params.group then params.group:insert( self ) ; end
	self.x = params.left or 0
	self.y = params.top or 0
	
    -- Return display group that contains the entire button structure
    return self

end
function class.newScrollBar( params )

	params           = params or {}
	params.direction = params.direction or "vertical"
	params.size      = params.size or 50

    local self      = display.newGroup( params.group )
	self._isVisible = false
	self.alpha      = 0

	-- Create scroll bar routines
	function self:show( immediate )
		if self._isVisible == true then return ; end
		self._isVisible = true
		if immediate then self.alpha = 1
		else              transition.to( self, { alpha = 1, time = 200 } ) ; end
	end
	function self:hide( immediate )
		if self._isVisible == false then return ; end
		self._isVisible = false
		if immediate then self.alpha = 0
		else              transition.to( self, { alpha = 0, time = 200 } ) ; end
	end
	
	-- Top, middle and bottom of scroll bar from theme
	if params.direction == "vertical" then	
		local imageSheet, frame, topSize = class.getThemeImage( "scrollBar_top" )
		local topImage                   = display.newImageRect( self, imageSheet, frame, topSize.width, topSize.height )
		topImage:setReferencePoint( display.TopLeftReferencePoint )
		topImage.x, topImage.y           = 0, 0
		topImage.alpha                   = params.alpha or 1

		local imageSheet, frame, bottomSize = class.getThemeImage( "scrollBar_bottom" )
		local bottomImage                   = display.newImageRect( self, imageSheet, frame, bottomSize.width, bottomSize.height )
		bottomImage:setReferencePoint( display.TopLeftReferencePoint )
		bottomImage.x, bottomImage.y        = 0, params.size - bottomSize.height
		bottomImage.alpha                   = params.alpha or 1

		local imageSheet, frame, size = class.getThemeImage( "scrollBar_middle" )
		local middleImage             = display.newImageRect( self, imageSheet, frame, size.width, params.size - topSize.height - bottomSize.height )
		middleImage:setReferencePoint( display.TopLeftReferencePoint )
		middleImage.x, middleImage.y  = 0, topSize.height
		middleImage.alpha             = params.alpha or 1
	else
		local imageSheet, frame, leftSize = class.getThemeImage( "scrollBar_top" )
		local leftImage                   = display.newImageRect( self, imageSheet, frame, leftSize.width, leftSize.height )
		leftImage:setReferencePoint( display.TopLeftReferencePoint )
		leftImage.rotation                = -90
		leftImage.x, leftImage.y          = 0, leftSize.height
		leftImage.alpha                   = params.alpha or 1

		local imageSheet, frame, rightSize = class.getThemeImage( "scrollBar_bottom" )
		local rightImage                   = display.newImageRect( self, imageSheet, frame, rightSize.width, rightSize.height )
		rightImage:setReferencePoint( display.TopLeftReferencePoint )
		rightImage.rotation                = -90
		rightImage.x, rightImage.y         = params.size - rightImage.width, leftSize.height
		rightImage.alpha                   = params.alpha or 1

		local imageSheet, frame, size = class.getThemeImage( "scrollBar_middle" )
		local middleImage             = display.newImageRect( self, imageSheet, frame, size.width, params.size - leftSize.height - rightSize.height )
		middleImage:setReferencePoint( display.TopLeftReferencePoint )
		middleImage.rotation          = -90
		middleImage.x, middleImage.y  = leftSize.width, leftSize.height
		middleImage.alpha             = params.alpha or 1
	end
	
	-- Set values
	if params.parent then params.parent:insert( self ) ; end
	self.x = params.x or 0
	self.y = params.y or 0
	
	return self
	
end
function class.newItemBar( params )

	-- Used later on
	local imageSheet, frame, frameSize

	-- Create the control
	local self          = display.newGroup()
	self.id             = params.id or "itemBar"
	local width         = math.max( params.width or 300, 100 )
	self.sections       = params.sections or {}
	local sectionsTotal = #params.sections
	self._onTap         = params.onTap

	-- Create the press function
	function self.onTapListener( event )
		if event.target.data.enabled ~= false then self._onTap( event ) ; end
	end

	-- Set up basic sizes	
	local leftWidth, midWidth, rightWidth, sectionHeight
	imageSheet, frame, size = class.getThemeImage( "gfx_optTopLeft" )
	leftWidth               = size.width
	imageSheet, frame, size = class.getThemeImage( "gfx_optTopRight" )
	rightWidth               = size.width
	midWidth                 = width - leftWidth - rightWidth
	sectionHeight            = params.height or size.height

	-- Create the segments - first and last being 'special', but all being same sizes
	-- Special case if there is just 1 section
	local y        = 0
	local sections = self.sections
	local sectionRoot
	if sectionsTotal == 1 then

		-- Create section group
		local group         = display.newGroup()
		sections[ 1 ].group = group
		self:insert( group )
		group.id            = sections[ 1 ].id
		group.data          = sections[ 1 ]
		group.x             = 0
		group.y             = y
		local defaultGroup  = display.newGroup()
		group:insert( defaultGroup )
		group._defaultGroup = defaultGroup
		local overGroup     = display.newGroup()
		group:insert( overGroup )
		group._overGroup    = overGroup
		overGroup.isVisible = false

		-- Create default and over versions
		for i = 1, 2 do
			local suffix  = ""
			local bgGroup = defaultGroup
			if i == 2 then
				suffix  = "_over"
				bgGroup = overGroup
			end

			-- Create top left edge
			imageSheet, frame, size = class.getThemeImage( "gfx_optTopLeftHalf" .. suffix )
			local image             = display.newImageRect( bgGroup, imageSheet, frame, leftWidth, sectionHeight / 2 )
			image:setReferencePoint( display.TopLeftReferencePoint )
			image.x                 = 0
			image.y                 = y

			-- Create top middle
			imageSheet, frame, size = class.getThemeImage( "gfx_optTopMiddleHalf" .. suffix )
			local image             = display.newImageRect( bgGroup, imageSheet, frame, midWidth, sectionHeight / 2 )
			image:setReferencePoint( display.TopLeftReferencePoint )
			image.x                 = leftWidth
			image.y                 = y

			-- Create top right edge
			imageSheet, frame, size = class.getThemeImage( "gfx_optTopRightHalf" .. suffix )
			local image             = display.newImageRect( bgGroup, imageSheet, frame, rightWidth, sectionHeight / 2 )
			image:setReferencePoint( display.TopLeftReferencePoint )
			image.x                 = leftWidth + midWidth
			image.y                 = y

			-- Create bottom left edge
			imageSheet, frame, size = class.getThemeImage( "gfx_optBottomLeftHalf" .. suffix )
			local image             = display.newImageRect( bgGroup, imageSheet, frame, leftWidth, sectionHeight / 2 )
			image:setReferencePoint( display.TopLeftReferencePoint )
			image.x                 = 0
			image.y                 = math.floor( sectionHeight / 2 )

			-- Create bottom middle
			imageSheet, frame, size = class.getThemeImage( "gfx_optBottomMiddleHalf" .. suffix )
			local image             = display.newImageRect( bgGroup, imageSheet, frame, midWidth, sectionHeight / 2 )
			image:setReferencePoint( display.TopLeftReferencePoint )
			image.x                 = leftWidth
			image.y                 = math.floor( sectionHeight / 2 )
		
			-- Create bottom right edge
			imageSheet, frame, size = class.getThemeImage( "gfx_optBottomRightHalf" .. suffix )
			local image             = display.newImageRect( bgGroup, imageSheet, frame, rightWidth, sectionHeight / 2 )
			image:setReferencePoint( display.TopLeftReferencePoint )
			image.x                 = leftWidth + midWidth
			image.y                 = math.floor( sectionHeight / 2 )
		end

	else
		for i = 1, sectionsTotal do
			y = ( i - 1 ) * sectionHeight

			-- Which set of graphics to use?
			if i == 1 then                 sectionRoot = "gfx_optTop"
			elseif i == sectionsTotal then sectionRoot = "gfx_optBottom"
			else                           sectionRoot = "gfx_optMid" ; end

			-- Create section group
			local group         = display.newGroup()
			sections[ i ].group = group
			self:insert( group )
			group.id            = sections[ i ].id
			group.data          = sections[ i ]
			group.x             = 0
			group.y             = y
			local defaultGroup  = display.newGroup()
			group:insert( defaultGroup )
			group._defaultGroup = defaultGroup
			local overGroup     = display.newGroup()
			group:insert( overGroup )
			group._overGroup    = overGroup
			overGroup.isVisible = false

			for j = 1, 2 do
				local suffix  = ""
				local bgGroup = defaultGroup
				if j == 2 then
					suffix  = "_over"
					bgGroup = overGroup
				end

				
				-- Create left edge
				imageSheet, frame, size = class.getThemeImage( sectionRoot .. "Left" .. suffix )
				local image             = display.newImageRect( bgGroup, imageSheet, frame, leftWidth, sectionHeight )
				image:setReferencePoint( display.TopLeftReferencePoint )
				image.x                 = 0
				image.y                 = 0

				-- Create middle
				imageSheet, frame, size = class.getThemeImage( sectionRoot .. "Middle" .. suffix )
				local image             = display.newImageRect( bgGroup, imageSheet, frame, midWidth, sectionHeight )
				image:setReferencePoint( display.TopLeftReferencePoint )
				image.x                 = leftWidth
				image.y                 = 0

				-- Create right edge
				imageSheet, frame, size = class.getThemeImage( sectionRoot .. "Right" .. suffix )
				local image             = display.newImageRect( bgGroup, imageSheet, frame, rightWidth, sectionHeight )
				image:setReferencePoint( display.TopLeftReferencePoint )
				image.x                 = leftWidth + midWidth
				image.y                 = 0
			end
		end
	end

	-- Set up function
	for i = 1, sectionsTotal do
		local group = sections[ i ].group
		
		-- Allow for a section to be hilighted
		function group.hilight( self, hilight )

			-- Toggle the groups
			self._defaultGroup.isVisible = not hilight
			self._overGroup.isVisible    = hilight
		end

		-- Allow for a section to be hilighted
		function group.setEnabled( self, enabled )
			self.data.enabled = enabled
			self:hilight( false )
			if enabled ~= false then
				self.alpha = 1
			else
				self.alpha = 0.4
			end
		end
	end

	-- Set up the contents
	if params.onRowRender then
		for i = 1, sectionsTotal do
			params.onRowRender( {
				row   = i,
				group = sections[ i ].group,
			} )
		end
	end

	-- Set up the listeners
	if self._onTap then
		for i = 1, sectionsTotal do
			sections[ i ].group:addEventListener( "tap", function( event ) self.onTapListener( event ) ; end )
		end
	end

	-- Set up item
	if params.group then params.group:insert( self ) ; end
	self.x = params.x or 0
	self.y = params.y or 0

	-- Return group
	return self

end

function class.clearBG()
	
	-- Clear image if one exists
	local group = globals.groups.bg
	if group.image then
		group.image:removeSelf()
		group.image    = nil
		group.fileName = nil
	end

end
function class.setBG( fileName )

	local group = globals.groups.bg
	if group.fileName == fileName then return ; end
	
	-- Clear the bg
	class.clearBG()
	
	-- BG
	local image      = display.newImageRect( group, fileName, globals.screenWidth, globals.screenHeight )
	image:setReferencePoint( display.TopLeftReferencePoint )
	image.x, image.y = 0, 0

	-- Store
	group.image    = image
	group.fileName = fileName
	
end
function class.setWatermark( fileName, width, height, x, y )

	-- Watermark
	local image = display.newImageRect( globals.groups.bg, fileName, width, height )
	image:setReferencePoint( display.TopLeftReferencePoint )
	image.x     = x - math.floor( image.width / 2 )
	image.y     = y - math.floor( image.height / 2 )
	image.alpha = 0.1
	
	-- Store the watermark image
	globals.groups.bg.watermark = image

end
function class.setWatermarkAlpha( alpha, time )

	transition.to( globals.groups.bg.watermark, { alpha = alpha, time = time or 400 } )

end

function class.bgRect( width, height, frame )

	-- Set up (reuse) image sheet 
	local theme      = require( globals.themeFile )
	local sheetData  = require( theme._sheetData )
	local imageSheet = graphics.newImageSheet( theme._sheetFile, sheetData:getSheet() )

	-- Create the background
	local bg = display.newImageRect( imageSheet, sheetData:getFrameIndex( frame or "gfx_barBG" ), width, height )
	bg:setReferencePoint( display.TopLeftReferencePoint )

	-- Fill it with event blockers
	bg:addEventListener( "touch", function() return true ; end )
	bg:addEventListener( "tap", function() return true ; end )
	
	return bg

end

function class.shadow( params )

	-- Get options
	params          = params or {}
	local image     = params.image or "gfx/shadow.png"
	local lineColor = params.lineColor or { 0, 0, 0, 255 }
	local alpha     = params.alpha or 0.5
	local drawLine  = true
	if params.line ~= nil then drawLine       = params.line ; end
	if #lineColor == 3 then    lineColor[ 4 ] = 255 ; end

	-- Create a shadow
	local group   = display.newGroup()
	local shadow  = display.newImage( image )
	group:insert( shadow )
	shadow:setReferencePoint( display.TopLeftReferencePoint )
	shadow.x      = 0
	shadow.y      = 0
	shadow.xScale = globals.screenWidth / shadow.contentWidth
	shadow.alpha  = alpha

	-- Draw the top line
	if drawLine == true then
		local line = display.newLine( group, 0, -0.5, globals.screenWidth, -0.5 )
		line:setColor( lineColor[ 1 ], lineColor[ 2 ], lineColor[ 3 ], lineColor[ 4 ] )
	end

	-- Return group
	return group
	
end

function class.textDisplay( params )

	local data      = params.data or {}
	local group     = params.group or display.newGroup()
	local x         = params.x or 0
	local y         = params.y or 0
	local width     = params.width or globals.areaWidth
	local fontSize  = params.fontSize or 14
	local textColor = params.textColor or { 63, 0, 63 }
	local font      = params.font or native.systemFontBold
	local titleFont = params.titleFont or font
	
	-- Create group just for this
	local localGroup = display.newGroup()
	group:insert( localGroup )

	-- Now lay out properly
	for i = 1, #data do

		-- Print info (not translated)
		local lines = data[ i ][ 1 ]
		if type( lines ) ~= "table" then lines = { lines } ; end
		for j, v in ipairs( lines ) do
			local info
			if data[ i ][ 2 ] == true then
				info = display.newEmbossedText( localGroup, lines[ j ], 0, 0, width, 0, titleFont, fontSize )
				info:setTextColor( 0, 0, 0 )
			else         
				info = display.newText( localGroup, lines[ j ], 0, 0, width, 0, font, fontSize )
				info:setTextColor( unpack( textColor ) )
			end
			info:setReferencePoint( display.TopLeftReferencePoint )
			info.x     = x
			info.y     = y

			-- Move down for next item
			y = y + info.height
		end
		
	end

	return y, localGroup

end
function class.dataDisplay( params )

	-- Set up parameters
	local data      = params.data or {}
	local group     = params.group or display.newGroup()
	local x         = params.x or 0
	local y         = params.y or 0
	local order     = params.order or {}
	local noTitle   = params.noTitle or {}
	local ignore    = params.ignore or {}
	local gap       = params.gap or 20
	local width     = params.width or globals.areaWidth
	local font      = params.font or native.systemFontBold
	local titleFont = params.titleFont or font
	
	if type( order ) == "string" then   order   = { order } ; end
	if type( noTitle ) == "string" then noTitle = { noTitle } ; end
	if type( ignore ) == "string" then  ignore  = { ignore } ; end
	
	-- Create the order
	local keyedData = {}
	for _, v in ipairs( data ) do
		local title = v[ 1 ]

		-- Should I ignore this key?
		local processData = true
		for i = 1, #ignore do
			if ignore[ i ] == title then
				processData = false
				break
			end
		end

		-- Find the key in the order - if not in order just add to end of list		
		if processData == true then

			-- Process
			local inOrder = false
			for i = 1, #order do
				if order[ i ] == title then
					inOrder = true
					break
				end
			end
			
			-- Add to order if not there
			if inOrder == false then order[ #order + 1 ] = title ; end
			
			-- Store a copy of the data ( a copy as we don't want to edit the table data directly)
			local vCopy = {}
			for i, value in  ipairs( v ) do
				vCopy[ i ] = value
			end
			keyedData[ title ] = vCopy
		end
	end

	-- Build up the data in order - which allows for no titles
	local orderedData = {}
	for i, v in ipairs( order ) do
		orderedData[ i ] = keyedData[ v ]

		-- Strip title if not wanted
		for j = 1, #noTitle do
			if noTitle[ j ] == v then orderedData[ i ][ 1 ] = "" ; end
		end
	end

	-- Create group just for this
	local localGroup = display.newGroup()
	group:insert( localGroup )

	-- First do the titles to get the maximum width
	local maxWidth = 0
	local titles   = {}
	for i = 1, #orderedData do
		local titleText = orderedData[ i ][ 1 ]
		if titleText:len() > 0 then
			local title = display.newEmbossedText( localGroup, titleText .. ":", 0, 0, 0, 0, titleFont, 12 )
			title:setReferencePoint( display.TopLeftReferencePoint )
			title:setTextColor( 0, 0, 0 )
			titles[ i ] = title
			maxWidth    = mMax( maxWidth, title.width )
		end
	end
	if maxWidth > 0 then maxWidth = maxWidth + gap ; end
	width = width - maxWidth - gap

	-- Now lay out properly
	for i = 1, #orderedData do

		-- Print title (translated)
		local title = titles[ i ]
		if title then
			title.x     = x
			title.y     = y
		end
		
		-- Print info (not translated)
		local lines = orderedData[ i ][ 2 ]
		if type( lines ) ~= "table" then lines = { lines } ; end
		for j, v in ipairs( lines ) do
			local info = display.newText( localGroup, lines[ j ], 0, 0, width, 0, font, 12 )
			if orderedData[ i ][ 3 ] == true then info:setTextColor( 0, 0, 0 )
			else                                  info:setTextColor( 127, 100, 0 ) ; end
			info:setReferencePoint( display.TopLeftReferencePoint )
			info.x     = maxWidth
			info.y     = y

			-- Move down for next item
			if j == 1 and title then y = y + mMax( title.height, info.height )
			else                     y = y + info.height ; end
		end
		
	end

	return y, localGroup, maxWidth

end

function class.getThemeImageSheet()

	local theme       = require( globals.themeFile )
	local sheet       = require( theme._sheetData )
	local sheetData   = sheet:getSheet()
	local sheetFrames = sheetData.frames
	local imageSheet  = graphics.newImageSheet( theme._sheetFile, sheetData )

	return imageSheet
	
end

function class.loadImage( params )

	if type( params ) == "string" then return class.getThemeImage( params )
	elseif type( params ) == "table" then
		if #params <= 2 then     return display.newImage( unpack( params ) )
		elseif #params == 3 then return display.newImageRect( unpack( params ) ) ; end
	end

	return false

end
function class.getThemeImage( frameName )

	-- Set up (reuse) image sheet 
	local theme       = require( globals.themeFile )
	local sheet       = require( theme._sheetData )
	local sheetData   = sheet:getSheet()
	local sheetFrames = sheetData.frames
	local imageSheet  = graphics.newImageSheet( theme._sheetFile, sheetData )
	local frame       = sheet:getFrameIndex(frameName )

	-- Return image sheet, frame number, and frame size
	return imageSheet, frame, sheetFrames[ frame ]

end

-- Return value
return class

