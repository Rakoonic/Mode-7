--------------------------------------------------------------
-- SETUP -----------------------------------------------------

local __G        = require( "libs.globals" )
local storyboard = require( "storyboard" )
local scene      = storyboard.newScene()

--------------------------------------------------------------
-- INITIALISE ------------------------------------------------

-- Prototypes
local setUp, setUpUi, setUpLevel, setUpTileset
local controlsListener
local enterFrame

-- Variables
local controls, touches
local gameFrame = 0

local pixelSize = 4
local snapshotWidth, snapshotHeight
local playerX, playerY, playerAngle, playerVelocity = -1000, -720, 90, 0

local gameGroup, groundGroup
local snapshot, snapshotGroup

local tileSize = 96
local tiles    = 32

local screenWidth  = __G.screenWidth
local screenHeight = __G.screenHeight
local mFloor       = math.floor
local mRadToDeg    = 180 / math.pi
local mDegToRad    = 1 / mRadToDeg

--------------------------------------------------------------
-- FUNCTIONS -------------------------------------------------

-- Set up
function setUp( sceneGroup )

	-- Create the level
	groundGroup = setUpLevel( sceneGroup )

	-- Set up the snapshot
	display.setDefault( "magTextureFilter", "linear" )
	display.setDefault( "minTextureFilter", "linear" )
	snapshotWidth  = screenWidth * 2 / pixelSize
	snapshotHeight = screenHeight * 2 / pixelSize
	snapshot       = display.newSnapshot( snapshotWidth, snapshotHeight )
	
	snapshot.group.xScale = pixelSize
	snapshot.group.yScale = pixelSize
	snapshot.anchorX      = 0
	snapshot.anchorY      = 0
	
	sceneGroup:insert( snapshot )
	snapshot.x     = 0--screenWidth / 2
	snapshot.y     = 0
	snapshotGroup  = snapshot.group
	snapshotGroup:insert( groundGroup )

	-- Set up the snapshot in 3D
	local border = 10
	local path   = snapshot.path
	
	path.x1 = border
	path.y1 = border--__G.screenHeight - snapshotHeight

	path.x2 = border -- -screenWidth * 4
	path.y2 = screenHeight - snapshotHeight - border -- __G.screenHeight - snapshotHeight

	path.x3 = screenWidth - snapshotWidth - border -- screenWidth * 4
	path.y3 = screenHeight - snapshotHeight - border -- __G.screenHeight - snapshotHeight

	path.x4 = screenWidth - snapshotWidth - border -- screenWidth / -2
	path.y4 = border -- __G.screenHeight - snapshotHeight

	-- Create the UI
	setUpUi( sceneGroup )
	
end

function setUpUi( sceneGroup )
	
	-- Create button locations
	controls = {
		menu       = { 0, 0, 15, 20 }, 
		left       = { 0, 70, 15, 30 }, 
		right      = { 15, 70, 15, 30 }, 
		accelerate = { 70, 60, 30, 20 }, 
		brake      = { 70, 80, 30, 20 }, 
	}

	-- Convert from percentages to actual pixels
	for k, v in pairs( controls ) do
		controls[ k ] = {
			left   = math.floor( v[ 1 ] * screenWidth / 100 ),
			right  = math.floor( ( v[ 1 ] * screenWidth + v[ 3 ] * screenWidth ) / 100 ),
			top    = math.floor( v[ 2 ] * screenHeight / 100 ),
			bottom = math.floor( ( v[ 2 ] * screenHeight + v[ 4 ] * screenHeight ) / 100 ),
			toggle = false,
		}	

		local border     = 2
		local area       = controls[ k ]
		local rect       = display.newRect( sceneGroup, 0, 0, area.right - area.left - border * 2, area.bottom - area.top - border * 2 )
		rect.anchorX     = 0
		rect.anchorY     = 0
		rect.x           = area.left + border
		rect.y           = area.top + border
		rect.strokeWidth = 1
		rect:setStrokeColor ( 1, 1, 1, 0.25 )
		rect:setFillColor( 0, 0, 0, 0 )
	end

	touches = {}

end
function setUpLevel( sceneGroup )

	-- Load level
	local levelData = require( "assets.track" )

	-- Get and build tileset
	local imageSheet = setUpTileset()

	-- Draw level
	local group  = display.newGroup()
	local width  = levelData.width
	local height = levelData.height
	local level  = levelData.layers[ 1 ].data
	for x = 1, width do
		for y = 1, height do
			local index = ( y - 1 ) * width + x
			local frame = level[ index ]
			if frame > 0 then
				local image  = display.newImageRect( group, imageSheet, frame, tileSize, tileSize )
				image.x      = x * tileSize - tileSize / 2
				image.y      = y * tileSize - tileSize / 2
				image.xScale = 1.01
				image.yScale = 1.01
			end
		end
	end

	return group
	
end
function setUpTileset()

	-- Create image sheet
	display.setDefault( "magTextureFilter", "nearest" )
	display.setDefault( "minTextureFilter", "nearest" )
	local options = {
		width     = tileSize,
		height    = tileSize,
		numFrames = tiles,
	}
	local imageSheet = graphics.newImageSheet( "assets/track.png", options )

	return imageSheet
		
end

-- Control function
function controlsListener( event )

	-- Loop through the events
	local id    = event.id
	local phase = event.phase
	if phase == "began" then
		touches[ #touches + 1 ] = { id = id, x = event.x, y = event.y }
	else
	
		-- Find index
		local index = false
		for i = 1, #touches do
			if touches[ i ].id == id then
				index = i
				break
			end
		end

		-- React to remaining options
		if phase == "moved" then
			touches[ index ].x = event.x
			touches[ index ].y = event.y
		else
			table.remove( touches, index )
		end
	end

	return true

end

-- Frame control
function enterFrame()

	-- Update things
	gameFrame = gameFrame + 1

	-- Process movements by checking all active touches
	local buttons = {}
	for k, v in pairs( controls ) do
		buttons[ k ] = false
		for i = 1, #touches do
			local touch = touches[ i ]
			if touch.x >= v.left and touch.x < v.right and touch.y >= v.top and touch.y <= v.bottom then
				buttons[ k ] = true
				break
			end		
		end		
	end

	-- Menu
	if buttons.menu ~= controls.menu.toggle then
		storyboard.gotoScene( "code.menu", __G.sbFade )
		return
	end
	
	-- Control speed
	if buttons.accelerate == true then playerVelocity = math.min( playerVelocity + 0.5, 2 )
	elseif buttons.brake == true then  playerVelocity = math.max( playerVelocity - 0.2, 0 )
	else                               playerVelocity = math.max( playerVelocity - 0.05, 0 ) ; end

	-- Control position
	if buttons.left == true then      playerAngle = playerAngle - 2
	elseif buttons.right == true then playerAngle = playerAngle + 2 ; end

	-- Move player
	playerX = playerX - math.sin( playerAngle * mDegToRad ) * playerVelocity
	playerY = playerY + math.cos( playerAngle * mDegToRad ) * playerVelocity

	-- Update the map position (hacky for the snapshot group!)
	groundGroup.x          = playerX
	groundGroup.y          = playerY
	snapshotGroup.rotation = -playerAngle
	snapshotGroup.y        = __G.screenHeight * 0.9
	
	-- Update the snapshot
	snapshot:invalidate()
	
end

--------------------------------------------------------------
-- STORYBOARD ------------------------------------------------

function scene:createScene( event )

	local sceneGroup = self.view
	setUp( sceneGroup )

	enterFrame()
	
end
function scene:enterScene( event )

	-- Add in the frame event
	Runtime:addEventListener( "enterFrame", enterFrame )

	-- Add in the touch event
	Runtime:addEventListener( "touch", controlsListener )

end
function scene:exitScene( event )

	-- Add in the frame event
	Runtime:removeEventListener( "enterFrame", enterFrame )

	-- Add in the touch event
	Runtime:removeEventListener( "touch", controlsListener )

end
function scene:didExitScene( event )

	storyboard.purgeScene( "code.game" )

end

--------------------------------------------------------------
-- STORYBOARD LISTENERS --------------------------------------

scene:addEventListener( "createScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )
scene:addEventListener( "didExitScene", scene )

--------------------------------------------------------------
-- RETURN STORYBOARD OBJECT ----------------------------------

return scene
