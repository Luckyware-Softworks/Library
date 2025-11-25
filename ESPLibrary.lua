local ESP = {
    Objects = {},
    Settings = {
        Boxes = true,
        Names = true,
        Tracers = true,
        ShowHealth = true,
        ShowDistance = true,
        DefaultColor = Color3.fromRGB(255, 255, 255),
        CustomColorFunction = nil,
        IncludeLocalPlayer = false,
        DistanceThreshold = 300
    },
    Connections = {}
}

getgenv().ESP = ESP

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer

local function CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    return drawing
end

local function GetObjectColor(object)
    return ESP.Settings.CustomColorFunction and ESP.Settings.CustomColorFunction(object) or ESP.Settings.DefaultColor
end

local function IsObjectValid(object)
    local root = object:FindFirstChild("HumanoidRootPart")
    local humanoid = object:FindFirstChild("Humanoid")

     if not humanoid then
        humanoid = object:FindFirstChildOfClass("Humanoid")
    end
    
    return root and humanoid and humanoid.Health > 0
end

local function ShouldRenderObject(object)
    return not (object == LocalPlayer.Character and not ESP.Settings.IncludeLocalPlayer)
end

local function CreateESP(object)
    local elements = {
        BoxOutline = CreateDrawing("Square", {Thickness = 3, Filled = false, Transparency = 0.5, Color = Color3.fromRGB(0, 0, 0)}),
        Box = CreateDrawing("Square", {Thickness = 1, Filled = false}),
        NameTag = CreateDrawing("Text", {Size = 16, Center = true, Outline = true}),
        HealthBarOutline = CreateDrawing("Square", {Filled = true, Color = Color3.fromRGB(0, 0, 0)}),
        HealthBar = CreateDrawing("Square", {Filled = true}),
        DistanceTag = CreateDrawing("Text", {Size = 14, Center = true, Outline = true}),
        Tracer = CreateDrawing("Line", {Thickness = 2})
    }

    ESP.Objects[object] = elements

    local connection = RunService.RenderStepped:Connect(function()
        if not IsObjectValid(object) or not ShouldRenderObject(object) then
            for _, drawing in pairs(elements) do drawing.Visible = false end
            return
        end

        local root = object:FindFirstChild("HumanoidRootPart")
        local humanoid = object:FindFirstChild("Humanoid")

        if not humanoid then
            humanoid = object:FindFirstChildOfClass("Humanoid")
        end

        if not root or not humanoid then
            for _, drawing in pairs(elements) do drawing.Visible = false end
            return
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not playerRoot then
            for _, drawing in pairs(elements) do drawing.Visible = false end
            return
        end

        local distance = (playerRoot.Position - root.Position).Magnitude

        if onScreen and distance <= ESP.Settings.DistanceThreshold then
            local size = Vector2.new(200 / distance, 300 / distance)
            local color = GetObjectColor(object)

            elements.BoxOutline.Visible = ESP.Settings.Boxes
            elements.BoxOutline.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
            elements.BoxOutline.Size = size

            elements.Box.Visible = ESP.Settings.Boxes
            elements.Box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
            elements.Box.Size = size
            elements.Box.Color = color

            elements.NameTag.Visible = ESP.Settings.Names
            elements.NameTag.Position = Vector2.new(screenPos.X, screenPos.Y - size.Y / 2 - 15)
            elements.NameTag.Text = object.Name
            elements.NameTag.Color = color

            elements.DistanceTag.Visible = ESP.Settings.ShowDistance
            elements.DistanceTag.Position = Vector2.new(screenPos.X, screenPos.Y + size.Y / 2 + 5)
            elements.DistanceTag.Text = string.format("%.1f m", distance)
            elements.DistanceTag.Color = color

            elements.Tracer.Visible = ESP.Settings.Tracers
            elements.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            elements.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            elements.Tracer.Color = color
                
            if humanoid.MaxHealth > 0 then
                local healthRatio = humanoid.Health / humanoid.MaxHealth
                elements.HealthBarOutline.Visible = ESP.Settings.ShowHealth
                elements.HealthBarOutline.Position = Vector2.new(screenPos.X - size.X / 2 - 7, screenPos.Y - size.Y / 2)
                elements.HealthBarOutline.Size = Vector2.new(5, size.Y)

                elements.HealthBar.Visible = ESP.Settings.ShowHealth
                elements.HealthBar.Position = Vector2.new(screenPos.X - size.X / 2 - 6, screenPos.Y - size.Y / 2 + size.Y * (1 - healthRatio))
                elements.HealthBar.Size = Vector2.new(3, size.Y * healthRatio)
                elements.HealthBar.Color = Color3.fromRGB(255 * (1 - healthRatio), 255 * healthRatio, 0)
            end
        else
            for _, drawing in pairs(elements) do drawing.Visible = false end
        end
    end)

    table.insert(ESP.Connections, connection)
end


function ESP:AddObject(object)
    if not ESP.Objects[object] then
        CreateESP(object)
    end
end

function ESP:RemoveObject(object)
    if ESP.Objects[object] then
        for _, drawing in pairs(ESP.Objects[object]) do drawing:Remove() end
        ESP.Objects[object] = nil
    end
end

function ESP:Destruct()
    for _, connection in ipairs(ESP.Connections) do connection:Disconnect() end
    ESP.Connections = {}
    for _, elements in pairs(ESP.Objects) do
        for _, drawing in pairs(elements) do drawing:Remove() end
    end
    ESP.Objects = {}
  if cleardrawcache then 
    cleardrawcache()
  end
end

return ESP
