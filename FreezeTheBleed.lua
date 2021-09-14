--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...)
end

local _, class = UnitClass("player");
if ( class ~= "DRUID") then
    return;
end

local SPELL_TIGERS_LUST_ID = 5217;
local SPELL_BLOODTALONS_ID = 145152;

FreezeTheBleed = CreateFrame("Frame",nil,UIParent)
FreezeTheBleed.cachedUnits = {}

function FreezeTheBleed:getOldBleed(unit)
    local guid = UnitGUID(unit)
    self.cachedUnits[guid] = self.cachedUnits[guid] or {}
    local tigersResult = self.cachedUnits[guid].tigersLust or 0
    local bloodTalons = self.cachedUnits[guid].bloodTalons or 0
    
    return tigersResult, bloodTalons
end

function FreezeTheBleed:getNewBleed()
    local now = GetTime();
    if self.potentialBuffs and self.potentialBuffs.tigersLust and self.potentialBuffs.bloodTalons and self.lastCalculated and now - self.lastCalculated < 0.1 then
        return self.potentialBuffs.tigersLust, self.potentialBuffs.bloodTalons
    end
    self.potentialBuffs = self.potentialBuffs or {}
    self.potentialBuffs.tigersLust = self:checkCurrentBuff("player",SPELL_TIGERS_LUST_ID,"player")
    self.potentialBuffs.bloodTalons = self:checkCurrentBuff("player",SPELL_BLOODTALONS_ID,"player")
    self.lastCalculated = now

    return self.potentialBuffs.tigersLust, self.potentialBuffs.bloodTalons

end

function FreezeTheBleed:setOldBleed(guid)
    self.cachedUnits[guid] = self.cachedUnits[guid] or {}
    self.cachedUnits[guid].tigersLust = self.potentialBuffs.tigersLust or 0
    self.cachedUnits[guid].bloodTalons = self.potentialBuffs.bloodTalons or 0
end

function FreezeTheBleed:resetBleed(guid)
    if not guid then
        return
    end
    self.cachedUnits[guid] = self.cachedUnits[guid] or {}
    self.cachedUnits[guid].tigersLust = 0
    self.cachedUnits[guid].bloodTalons = 0
end

function FreezeTheBleed:checkCurrentBuff(unit, searchID, filter)
    for i=1,40,1 do
        local _, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit,i,filter)
        if spellID == nil then
            return 0
        end
        if spellID == searchID then
            return 1
        end
    end
end