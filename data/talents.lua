local Dialog = require 'engine.ui.Dialog'

newTalent {
	name = 'Cancel Sustains',
	type = { 'base/class', 1 },
	mode = 'passive',
	hide = 'always',
	no_unlearn_last = true,
	info = _t[[The ability to disable sustains while resting.]],
	callbackOnRest = function(self, _, mode)
		local data = self.addon and self.addon.unsustain
		if not data then return false end
		if mode == 'start' then
			data.canceling = true
			-- compatibility with Restart Sustains
			local resustain = self.addon and self.addon.resustain
			if resustain and data.mark then
				for id, _ in pairs(data.mark) do
					if resustain.mark[id] then
						local t = self:getTalentFromId(id)
						game.logPlayer(self, '#RED#You cannot cancel %s while you mark it fot restart.#LAST#', t.name)
						data.through = data.through or {}
						data.through[id] = true
					end
				end
			end
		elseif mode == 'stop' then
			-- Clean up
			data.canceling = nil
			data.through = {}
			data.cancel_this_turn = nil
		elseif mode == 'check' then
			-- TODO: config
			-- Check if we have marked sustains
			if not data.mark or not next(data.mark) then return false end
			-- Check if we are not digging
			if auto and self.resting and self.resting.past == 'dug' then return false end

			local need_to_wait, cancel_next = false, nil
			for id, _ in pairs(data.mark) do
				local t = self:getTalentFromId(id)
				local no_energy = util.getval(t.no_energy, self, t)
				no_energy = type(no_energy) == 'boolean' and no_energy == true
				if not self:knowTalent(id) then
					-- Talent not known (tricksy player must have unlearned it); skip it.
				elseif not self:isTalentActive(id) then
					-- Sustain is already inactive; skip it
				elseif data.through and data.through[id] then
					-- compatibility with Restart Sustains
					-- prioritise Retart Sustains
				elseif no_energy then
					-- Sustain can be canceled and is instant-use; cancel it.
					self:useTalent(id)
				else
					-- Sustain can be canceled and is not instant-use; this is the sustain we'll cancel in callbackOnWait() unless we've already got another one lined up.
					cancel_next = cancel_next or id
					need_to_wait = true
				end
			end
			if not need_to_wait then
				-- Nothing left to cancel
				return false
			end
			-- Remember this talent for callbackOnWait().
			data.cancel_this_turn = cancel_next
			if self.resting and self.resting.cnt > 50 then
				-- Emergency fallback: if it takes more than 50 turns to get our sustains canceled, assuce something is wrong and punt.
				return false
			end
			return true
		end
	end,
	callbackOnWait = function(self, t)
		local data = self.addon and self.addon.unsustain
		if self.resting and data and data.cancel_this_turn then
			-- without this check, True Gift go mad somehow. need more investigation.
			if self:isTalentActive(data.cancel_this_turn) then
				-- callbackOnRest() found a sustain for us to cancel; do that now.
				-- Our caller will use Energy(), so we don't.
				self:forceUseTalent(data.cancel_this_turn, {ignore_energy=true})
			end
		end
	end,
}

newTalent {
	name = 'Cancel Effects',
	type = { 'base/class', 1 },
	mode = 'passive',
	hide = 'always',
	no_unlearn_last = true,
	info = _t[[The ability to disable beneficial effects while resting.]],
	callbackOnRest = function(self, _, mode)
		local data = self.addon and self.addon.uneffects
		if not data then return false end
		if mode == 'start' then
			data.canceling = true
			-- TODO: find a way to ask player without disturbing rest
			-- Check for any confirms
			-- local confirms = {}
			-- for id, _ in pairs(data.confirm) do
			-- 	if self.tmp[id] then
			-- 		local e = self.tempeffect_def[id]
			-- 		confirms[#confirms+1] = '  - ' .. e.desc
			-- 	end
			-- end
			-- if #confirms > 0 then
			-- 	local text = table.concat(confirms, '\n')
			-- 	text = 'The following effects are active: \n' .. text .. '\n\nBegin cancel?'
			-- 	local cb = function(ok)
			-- 		if not ok then data.cancelng = false end
			-- 	end
			-- 	Dialog:yesnoLongPopup('Cancel Effects', text, 600, cb)
			-- 	return true
			-- end
		elseif mode == 'stop' then
			-- Clean up
			data.canceling = nil
		elseif mode == 'check' then
			local manual = data.canceling and data.manual
			-- TODO: config
			local auto = data.canceling
			if not (manual or auto) then return false end
			-- Check if we have marked effects
			if not data.mark or not next(data.mark) then return false end
			-- Check if we are not digging
			if auto and self.resting and self.resting.past == 'dug' then return false end

			for id, _ in pairs(data.mark) do
				self:removeEffect(id)
			end
		end
	end,
}
