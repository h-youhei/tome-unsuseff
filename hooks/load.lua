local Dialog = require "engine.ui.Dialog"
local ActorTalents = require "engine.interface.ActorTalents"
local KeyBind = require 'engine.KeyBind'

class:bindHook('ToME:load', function(self, data)
	ActorTalents:loadDefinition('/data-unsuseff/talents.lua')
	-- KeyBind:defineAction {
	-- 	default = {},
	-- 	type = 'CANCEL_SUSTAINS',
	-- 	group = 'actions',
	-- 	name = _t'Cancel marked sustains'
	-- }
	-- KeyBind:defineAction {
	-- 	default = {},
	-- 	type = 'CANCEL_EFFECTS',
	-- 	group = 'actions',
	-- 	name = _t'Cancel marked beneficial effects'
	-- }
	KeyBind:defineAction {
		default = { 'sym:_e:true:false:true:false' },
		type = 'CANCEL_EFFECTS_DIALOG',
		group = 'miscellaneous',
		name = _t'Mark effects for cancel'
	}
	-- KeyBind:defineAction {
	-- 	default = {},
	-- 	type = 'CANCEL_SUSTAINS_DIALOG',
	-- 	group = 'miscellaneous',
	-- 	name = _t'Mark sustains for cancel'
	-- }
end)

class:bindHook('ToME:birthDone', function(self, data)
	local p = game.player
	-- Dummy talents, added only so that we can hang callbackOnRest() and callbackOnWait() callbacks on it.
	if p and not p:knowTalent(p.T_CANCEL_SUSTAINS) then
	p:learnTalent(p.T_CANCEL_SUSTAINS, true, nil, {no_unlearn=true})
	end
	if p and not p:knowTalent(p.T_CANCEL_EFFECTS) then
	p:learnTalent(p.T_CANCEL_EFFECTS, true, nil, {no_unlearn=true})
	end
end)

class:bindHook('ToME:runDone', function(self, data)
	local UnSustainsDialog = require 'mod.dialogs.CancelSustainsDialog'
	local UnEffectsDialog = require 'mod.dialogs.CancelEffectsDialog'
	-- to mark after loading game, using talent that activates the effect, etc
	UnSustainsDialog:markSustainsAll(game.player)
	UnEffectsDialog:markEffectsAll(game.player)
end)

class:bindHook('UseTalents:generate', function(self, data)
	local Entity = require 'engine.Entity'
	if data.talent.mode == 'sustained' then
		data.actor.addon = data.actor.addon or {}
		data.actor.addon.unsustain = data.actor.addon.unsustain or { mark={} }
		local unsustain = data.actor.addon.unsustain
		if unsustain.mark[data.talent.id] then
			local ui_pfx = self.ui and self.ui..'-' or ''
			local unmarkMenu = Entity.new{ image=ui_pfx..'ui/minus.png' }
			data.menu[#data.menu+1] = {
				name = unmarkMenu:getDisplayString() .. _t'Unmark talent for unsustain on rest',
				what = 'disable_unsustain',
			}
		else
			local markMenu = Entity.new{ image='mark-cancel-menu.png' }
			data.menu[#data.menu+1] = {
				name = markMenu:getDisplayString() .. _t'Mark talent for unsustain on rest',
				what = 'enable_unsustain',
			}
		end
	end
end)
class:bindHook('UseTalents:use', function(self, data)
	local UnSustainsDialog = require 'mod.dialogs.CancelSustainsDialog'
	local unsustain = data.actor.addon.unsustain
	local t = data.talent
	-- TODO: make only resustain or unsustain can be enabled
	if data.what == 'enable_unsustain' then
		local resustain = data.actor.addon.resustain
		if resustain and resustain.mark and resustain.mark[t.id] then
			Dialog:simplePopup(_t'Unsustain', _t'Sustains are not canceled but restarted if both resustain and unsustain are enabled.')
		end
		unsustain.mark[t.id] = true
		UnSustainsDialog:markSustains(data.actor, t.id)
		-- Dialog:simplePopup(_t"Unsustain enabled", ("%s will cancel automatically."):tformat(t.name:capitalize()))
	elseif data.what == 'disable_unsustain' then
		unsustain.mark[t.id] = nil
		UnSustainsDialog:markSustains(data.actor, t.id)
		-- Dialog:simplePopup(_t"Unsustain disabled", ("%s will not cancel automatically anymore."):tformat(t.name:capitalize()))
	end
end)
