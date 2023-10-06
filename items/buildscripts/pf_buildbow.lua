require "/scripts/util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"

function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  -- select, load and merge abilities
  setupAbility(config, parameters, "alt")
  setupAbility(config, parameters, "primary")

  -- elemental type
  local elementalType = parameters.elementalType or config.elementalType or "physical"
  replacePatternInData(config, nil, "<elementalType>", elementalType)

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = {}
  config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
  config.tooltipFields.subtitle = parameters.category
  config.tooltipFields.energyPerShotLabel = config.primaryAbility.energyPerShot or 0
  
  -- Frackin' whyyyy?
  local bestDrawTime = config.primaryAbility.powerProjectileTime
  bestDrawTime = type(bestDrawTime) == "number" and {1,1} or bestDrawTime
  bestDrawTime = (bestDrawTime[1] + bestDrawTime[2]) / 2
  local bestDrawMultiplier = root.evalFunction(config.primaryAbility.drawPowerMultiplier or "drawTimeMultiplier", bestDrawTime)
  
  config.tooltipFields.damagePerShotLabel = util.round(config.primaryAbility.projectileParameters.power * config.damageLevelMultiplier * bestDrawMultiplier, 1)
  if elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
  end
  
  if config.altAbility then
    config.tooltipFields.altAbilityTitleLabel = "Special:"
    config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
  end

  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end