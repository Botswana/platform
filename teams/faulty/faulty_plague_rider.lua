local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_plague_rider.lua")

behaviorLib.StartingItems = { "Item_MinorTotem 2", "Item_RunesOfTheBlight", "Item_TrinketOfRestoration" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Strength5", "Item_PowerSupply", "Item_Astrolabe" }
behaviorLib.MidItems = { "Item_PostHaste" }
behaviorLib.LateItems = { "Item_Morph" }

-- http://forums.heroesofnewerth.com/showthread.php?24393-Plague-Rider-guide
-- desired skillbuild order
-- 0 = Q(Contagion)
-- 1 = W(Cursed Shield)
-- 2 = E(Extinguish)
-- 3 = R(Plague Carrier)
-- 4 = Attribute boost
plaguerider.tSkills = {
  0, 0, 2, 2, 0,
  3, 0, 2, 2, 1,
  3, 4, 4, 4, 4,
  3, 2, 2, 2, 4,
  4, 4, 4, 4, 4
}

plaguerider.skills = {}
local skills = plaguerider.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function plaguerider:SkillBuildOverride()
	local unitSelf = self.core.unitSelf
	if skills.abilContagion == nil then
		skills.abilContagion  = unitSelf:GetAbility(0)
		skills.abilShield     = unitSelf:GetAbility(1)
		skills.abilExtinguish = unitSelf:GetAbility(2)
		skills.abilPlague     = unitSelf:GetAbility(3)
		skills.abilStats      = unitSelf:GetAbility(4)
	end
	plaguerider:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	-- custom code here
end
plaguerider.onthinkOld = plaguerider.onthink
plaguerider.onthink = plaguerider.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

	-- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride


--------------------------------------------------------------------------------
-- CUSTOM HARASS BEHAVIOR
--
-- Utility: 
--
-- Execute: 

-- 0 = Q(Contagion)
-- 1 = W(Cursed Shield)
-- 2 = E(Extinguish)
-- 3 = R(Plague Carrier)
-- 4 = Attribute boost

-- nuke skill base
local nContagionUp = 10

-- enemy weakened bonuses, attack more if enemy is weaker.
local nEnemyNoMana = 20
local nEnemyNoHealth = 20

-- level bonuses depending of the skill level
local nSkillLevelBonus = 5

plaguerider.doHarass = {}

local function HeroStateValue(hero, nNoManaVal, nNoHealthVal)
	local nHealthPercent = hero:GetHealthPercent()
	local nManaPercent   = hero:GetManaPercent()

	local nRet = 0
	if nHealthPercent ~= nil then
		nRet = nRet + (1 - nHealthPercent) * nNoHealthVal
	end
	if nManaPercent ~= nil then
		nRet = nRet + (1 - nManaPercent) * nNoManaVal
	end
	return nRet
end

local function CustomHarassUtilityFnOverride(hero)
	plaguerider.doHarass = {} -- reset
	local unitSelf = core.unitSelf

	local heroPos = hero:GetPosition()
	local selfPos = unitSelf:GetPosition()

	local nRet = 0
	local nMe = HeroStateValue(unitSelf, nEnemyNoMana, nEnemyNoHealth)
	local nEnemy = HeroStateValue(hero, nEnemyNoMana, nEnemyNoHealth)
	nRet = (nRet + nEnemy - nMe)

	local bCanSee = core.CanSeeUnit(plaguerider, hero)

	if skills.abilContagion:CanActivate() and bCanSee then
		local nRange = skills.abilContagion:GetRange()
		local targetDistanceSq = Vector3.Distance2DSq(selfPos, heroPos)

		if targetDistanceSq < (nRange * nRange) then
			plaguerider.doHarass["target"] = hero
			plaguerider.doHarass["skill"]  = skills.abilContagion

			nRet = nRet + nContagionUp + skills.abilContagion:GetLevel() * nSkillLevelBonus
			BotEcho(format("  CustomHarass, nRet: %g", nRet))
		end
	end

	return nRet
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = plaguerider.doHarass["target"]
	local skill = plaguerider.doHarass["skill"]
	if unitTarget == nil or skill == nil or not skill:CanActivate() then
		return plaguerider.harassExecuteOld(botBrain)
	end

	local unitSelf = core.unitSelf
	local targetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
	local bActionTaken = false

	if core.CanSeeUnit(botBrain, unitTarget) then
		local range = skill:GetRange()
		if targetDistanceSq < (range * range) then
			BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
			bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)
		end
	end

	if not bActionTaken then
		return plaguerider.harassExecuteOld(botBrain)
	end
end
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
--------------------------------------------------------------------------------

BotEcho("finished loading faulty_plague_rider.lua")
