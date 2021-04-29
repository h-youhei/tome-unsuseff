local _M = loadPrevious(...)

local base_setupCommands = _M.setupCommands
function _M:setupCommands()
	base_setupCommands(self)
	game.key:addBinds {
		-- CANCEL_SUSTAINS = function()
		-- end,
		-- CANCEL_EFFECTS = function()
		-- end,
		CANCEL_EFFECTS_DIALOG = function()
			game:registerDialog(require('mod.dialogs.CancelEffectsDialog').new(game.player))
		end
		-- CANCEL_SUSTAINS_DIALOG = function()
			-- game:registerDialog(require('mod.dialogs.CancelSustainsDialog').new(game.player))
		-- end
	}
end

return _M
