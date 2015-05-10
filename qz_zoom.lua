require "base/internal/ui/reflexcore"

qz_zoom =
  {
    canPosition = false
  };

registerWidget("qz_zoom");

local DEBUG = false

---------------------------------------------
---------------------------------------------

local function DrawOptionsHeader(text, x, y, offsetx, lengthx)
	uiLabel(text, x, y);

	nvgBeginPath();
	nvgMoveTo(x + offsetx, y + 33);
	nvgLineTo(x + offsetx + lengthx, y + 33);
	nvgStrokeWidth(1);
	nvgStrokeColor(Color(150, 150, 150, 80));
	nvgStroke();
end

---------------------------------------------
---------------------------------------------

function qz_zoom:initialize()

  self.userData = loadUserData()
  CheckSetDefaultValue(self, "userData", "table", {})

  CheckSetDefaultValue(self.userData, "default_fov", "number", consoleGetVariable("r_fov"))
  CheckSetDefaultValue(self.userData, "default_sens", "number", consoleGetVariable("m_speed"))

  CheckSetDefaultValue(self.userData, "zoom_fov", "number", 90)

  CheckSetDefaultValue(self.userData, "animate", "boolean", true)
  CheckSetDefaultValue(self.userData, "anim_speed", "number", 5)

  CheckSetDefaultValue(self.userData, "auto_sens", "boolean", true)
  CheckSetDefaultValue(self.userData, "sens_mult", "number", 1)

  widgetCreateConsoleVariable("bind", "int", 0)
end

function qz_zoom:drawOptions(x, y)
  local sliderWidth = 200
  local sliderStart = 140
  local user = self.userData

  y = y + 20
  ---------------
  ---------------
	DrawOptionsHeader("FOV", x, y, -5, 560);
  y = y + 40

	uiLabel("Default FOV", x, y)
	user.default_fov = round(uiSlider(x + sliderStart, y, sliderWidth, 20, 150, user.default_fov))
	user.default_fov = round(uiEditBox(user.default_fov, x + sliderStart + sliderWidth + 10, y, 60))
  y = y + 40

	uiLabel("Zoom FOV", x, y)
	user.zoom_fov = round(uiSlider(x + sliderStart, y, sliderWidth, 20, user.default_fov, user.zoom_fov))
	user.zoom_fov = round(uiEditBox(user.zoom_fov, x + sliderStart + sliderWidth + 10, y, 60))
  y = y + 40

  ---------------
  ---------------
  y = y + 20

	DrawOptionsHeader("Sensitivity", x, y, -5, 560);
  y = y + 40

	uiLabel("Default Sens", x, y)
	user.default_sens = clampTo2Decimal(uiSlider(x + sliderStart, y, sliderWidth, 0.1, 30, user.default_sens))
	user.default_sens = clampTo2Decimal(uiEditBox(user.default_sens, x + sliderStart + sliderWidth + 10, y, 60))
  y = y + 40
	user.auto_sens = uiCheckBox(user.auto_sens, "Auto multiplier", x, y);
  y = y + 40

  if not user.auto_sens then
    uiLabel("Sens Multiplier", x, y)
    user.sens_mult = clampTo2Decimal(uiSlider(x + sliderStart, y, sliderWidth, 0.1, 2, user.sens_mult))
    user.sens_mult = clampTo2Decimal(uiEditBox(user.sens_mult, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40
  end

  ---------------
  ---------------
  y = y + 20

	DrawOptionsHeader("Animation", x, y, -5, 560);
  y = y + 40

	user.animate = uiCheckBox(user.animate, "Animate", x, y);
	y = y + 30;
  if user.animate then
    user.anim_speed = round(uiSlider(x + sliderStart, y, sliderWidth, 1, 10, user.anim_speed))
    user.anim_speed = round(uiEditBox(user.anim_speed, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40
  end

	saveUserData(user);
end

local zoomed = false
local animating = false
local next_fov

function qz_zoom:draw()
  -- Early out if HUD shouldn't be shown.
  if not shouldShowHUD() then return end;

  local default_fov = self.userData.default_fov
  local zoom_fov = self.userData.zoom_fov

  local default_sens = self.userData.default_sens
  local sens_mult = self.userData.sens_mult

  local animate = self.userData.animate

  if next_fov == nil then next_fov = default_fov end
  local curr_fov = consoleGetVariable("r_fov")

  local zoom_sens
  if self.userData.auto_sens then
    zoom_sens = default_sens * (zoom_fov/default_fov)
  else
    zoom_sens = default_sens * sens_mult
  end

  local speed
  if animate then speed = (deltaTime*self.userData.anim_speed/100)/(1/250)
  else speed = 1
  end

  if widgetGetConsoleVariable("bind") == 1 then
    next_fov = lerp(next_fov, zoom_fov, speed)
    next_fov = math.floor(next_fov)
  else
    next_fov = lerp(next_fov, default_fov, speed)
    next_fov = math.ceil(next_fov)
  end

  if curr_fov >= default_fov then zoomed = false
  elseif curr_fov <= zoom_fov then zoomed = true
  end

  if zoomed then
    consolePerformCommand("bind game space m_speed " .. default_sens .. "; ui_qz_zoom_bind 0")
  else
    consolePerformCommand("bind game space m_speed " .. zoom_sens .. "; ui_qz_zoom_bind 1")
  end

  if DEBUG then
    nvgText(0, 50, widgetGetConsoleVariable("bind"))
    nvgText(0, 60, curr_fov)
    nvgText(0, 70, next_fov)
    nvgText(0, 80, consoleGetVariable("m_speed"))
    if zoomed then nvgText(0, 90, "zoomed")
    else nvgText(0, 90, "not zoomed")
    end
  end

  consolePerformCommand("r_fov " .. next_fov);

end
