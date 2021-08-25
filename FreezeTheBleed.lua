--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...)
end

local _, class = UnitClass("player");
if ( class ~= "DRUID") then
    return;
end

local SPELL_RIP_ID = 1079;

FreezeTheBleed = CreateFrame("GameTooltip","FreezeTheBleed",UIParent,"GameTooltipTemplate")
FreezeTheBleed.cachedUnits = {};

function FreezeTheBleed:getOldBleed(unit)
    --if unit then
        local guid = UnitGUID(unit);
        local now = GetTime();
        if self.cachedUnits[guid] and self.cachedUnits[guid].lastCalculated and now - self.cachedUnits[guid].lastCalculated < 0.1 then
            --debugPrint("early out", now - self.cachedUnits[guid].lastCalculated)
            return self.cachedUnits[guid].storedBleed
        end
        local tooltipText = self:getTooltipFromEnemy(unit, SPELL_RIP_ID,"TextLeft2")
        --debugPrint(tooltipText)
        self.cachedUnits[guid] = self.cachedUnits[guid] or {};
        self.cachedUnits[guid].storedBleed = self:getOldDamageFromTooltip(tooltipText)
        self.cachedUnits[guid].lastCalculated = now
        return self.cachedUnits[guid].storedBleed
    --end
end

function FreezeTheBleed:getNewBleed()
    local now = GetTime();
    if self.lastCalculated and now - self.lastCalculated < 0.1 then
        --debugPrint("time potential damage calculated last:", now - self.lastCalculated)
        return self.potentialDamage
    end
    local tooltipText = self:getTooltipFromSelf(SPELL_RIP_ID,"TextLeft5")
    if not string.match(tooltipText,"Bleed") then
        tooltipText = self:getTooltipFromSelf(SPELL_RIP_ID,"TextLeft6") --IF GCD is on, then the line moves down one
    end
    --debugPrint("Tooltip", tooltipText)
    self.potentialDamage = self:getNewDamageFromTooltip(tooltipText)
    self.lastCalculated = now
    --debugPrint("New Bleed: ", self.potentialDamage)
    return self.potentialDamage
end

function FreezeTheBleed:getTooltipFromEnemy(unit, spellID,textLine)
    self:SetOwner(UIParent, "ANCHOR_NONE");
    local debuffIndex = self:getDebuffIndex(unit,spellID)
    if debuffIndex == 0 then
        return nil --Early out
    end
    self:SetUnitDebuff(unit,debuffIndex,"PLAYER");
    self:Show()
    local fontstring = self:getTooltipText(textLine)
    local text = fontstring:GetText()
    return text
end

function FreezeTheBleed:getTooltipFromSelf(spellID,textLine)
    self:SetOwner(UIParent, "ANCHOR_NONE");
    self:SetSpellByID(spellID)
    self:Show()
    local fontstring = self:getTooltipText(textLine)
    --debugPrint("fontstring ", fontstring)
    local text = fontstring:GetText()
    return text
end

function FreezeTheBleed:getOldDamageFromTooltip(tooltipText)
    if tooltipText then
        local tickDamage, tickRate = string.match(tooltipText,"Bleeding for (%d*,?%d+) damage every (%d*%.?%d+) sec")
        tickDamage = tickDamage:gsub(",","")
        local dps = self:calculateDPS(tickDamage,tickRate)
        return dps
    end
end

function FreezeTheBleed:getNewDamageFromTooltip(tooltipText)
    if tooltipText then
        local totalDamage, totalTime = string.match(tooltipText,"5 points: (%d*,?%d+) over (%d*,?%d+) sec")
        --debugPrint("Full Damage and Time:", totalDamage, totalTime)
        if totalDamage and totalTime then
            totalDamage = totalDamage:gsub(",","")
            totalTime = totalTime:gsub(",","")
        else
        end
        --debugPrint("Removed damage & time:", totalDamage, totalTime)
        local dps = self:calculateDPS(totalDamage,totalTime)
        return dps
    end
end

function FreezeTheBleed:calculateDPS(damage,time)
    if damage and time then
        local dps = damage/time
        return dps
    end
end

function FreezeTheBleed:getDebuffIndex(unit, searchID)
    for i=1,40, 1 do
        local _, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, i, "PLAYER");
        if spellID == nil then
            return 0
        end

        if spellID == searchID then
            return i
        end
    end
end

function FreezeTheBleed:getTooltipText(line)
    --debugPrint(self:GetName())
    --debugPrint(_G[self:GetName()..line]:GetText())
    return _G[self:GetName()..line]
end
