--------------------------------------------------------------
-- SETUP -----------------------------------------------------

local __G        = require( "libs.globals" )
local gfx        = require( "libs.gfx" )
local storyboard = require( "storyboard" )
local scene      = storyboard.newScene()

--------------------------------------------------------------
-- STORYBOARD ------------------------------------------------

function scene:createScene( event )

	local group = self.view

	local button = gfx.newButton{
		label     = "PLAY",
		labelSize = 25,
		width     = 200,
		height    = 60,
		useRects  = true,
		onRelease = function()
			storyboard.gotoScene( "code.game", __G.sbFade )
		end,
	}
	group:insert( button )
	button.x = __G.screenWidth / 2
	button.y = __G.screenHeight / 2

end
function scene:didExitScene( event )

	storyboard.purgeScene( "code.menu" )

end

--------------------------------------------------------------
-- STORYBOARD LISTENERS --------------------------------------

scene:addEventListener( "createScene", scene )
scene:addEventListener( "didExitScene", scene )

--------------------------------------------------------------
-- RETURN STORYBOARD OBJECT ----------------------------------

return scene
