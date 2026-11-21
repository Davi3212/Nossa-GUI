-- DOUBLEX HUB Dandy V32 Compacto | carregador com diagnostico visivel
-- Mantem o loadstring do arquivo Copia_V32.lua; o codigo esta no _Core.lua.
local Players=game:GetService("Players")
local screenParent=(Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
local coreURL="https://raw.githubusercontent.com/Davi3212/Nossa-GUI/main/DOUBLEX_Dandys_World_Copia_V32_Core.lua?v=compact1"
local function reportError(message)
    local msg=tostring(message):sub(1,1000)
    warn("[DOUBLEX DANDY ERRO] "..msg)
    if not screenParent then return end
    local old=screenParent:FindFirstChild("DOUBLEX_Dandy_Error")
    if old then old:Destroy() end
    local gui=Instance.new("ScreenGui")
    gui.Name="DOUBLEX_Dandy_Error"
    gui.IgnoreGuiInset=true
    gui.ResetOnSpawn=false
    gui.DisplayOrder=200
    gui.Parent=screenParent
    local panel=Instance.new("Frame")
    panel.Size=UDim2.new(.86,0,0,154)
    panel.Position=UDim2.new(.07,0,.12,0)
    panel.BackgroundColor3=Color3.fromRGB(26,22,35)
    panel.BorderSizePixel=0
    panel.Parent=gui
    Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
    local border=Instance.new("UIStroke",panel)
    border.Color=Color3.fromRGB(238,77,90)
    border.Thickness=2
    local heading=Instance.new("TextLabel")
    heading.Size=UDim2.new(1,-42,0,30)
    heading.Position=UDim2.fromOffset(12,5)
    heading.BackgroundTransparency=1
    heading.Text="DOUBLEX DANDY - ERRO"
    heading.Font=Enum.Font.GothamBold
    heading.TextSize=16
    heading.TextXAlignment=Enum.TextXAlignment.Left
    heading.TextColor3=Color3.fromRGB(255,120,130)
    heading.Parent=panel
    local label=Instance.new("TextLabel")
    label.Position=UDim2.fromOffset(12,38)
    label.Size=UDim2.new(1,-24,1,-47)
    label.BackgroundTransparency=1
    label.TextWrapped=true
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextYAlignment=Enum.TextYAlignment.Top
    label.Font=Enum.Font.Code
    label.TextSize=12
    label.TextColor3=Color3.new(1,1,1)
    label.Text="Envie esta mensagem para corrigirmos:\n"..msg
    label.Parent=panel
    local close=Instance.new("TextButton")
    close.Position=UDim2.new(1,-35,0,5)
    close.Size=UDim2.fromOffset(28,28)
    close.Text="X"
    close.TextColor3=Color3.new(1,1,1)
    close.BackgroundColor3=Color3.fromRGB(135,40,60)
    close.Font=Enum.Font.GothamBold
    close.Parent=panel
    close.MouseButton1Click:Connect(function()gui:Destroy()end)
end
local ok,source=pcall(function()return game:HttpGet(coreURL)end)
if not ok or type(source)~="string" or #source<500 then
    reportError("Falha ao baixar o nucleo: "..tostring(source))
    return
end
if type(loadstring)~="function" then
    reportError("O executor nao disponibilizou loadstring.")
    return
end
local compiled,compileError=loadstring(source)
if not compiled then
    reportError("Erro ao compilar: "..tostring(compileError))
    return
end
local worked,runError=xpcall(compiled,function(err)
    if debug and type(debug.traceback)=="function" then
        return debug.traceback(tostring(err),2)
    end
    return tostring(err)
end)
if not worked then
    reportError("Erro ao iniciar: "..tostring(runError))
end
