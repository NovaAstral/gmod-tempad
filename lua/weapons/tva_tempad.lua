AddCSLuaFile() --Makes it show up in singleplayer

local SWEP = {Primary = {}, Secondary = {}}
SWEP.Author = "Nova Astral"
SWEP.PrintName = "Tempad"
SWEP.Purpose = "Teleport to places"
SWEP.Instructions = "LMB - Open Time Window where you're looking\nRMB- Close Time Window\nReload - Set Destination"
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 3
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the swep
SWEP.Primary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false

SWEP.Category = "TVA"

-- absolute basics before i make a control menu and do a bunch of stuff i've never done before for waypoints and colors and stuff:
-- R - sets destination to 

function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:DrawWorldModel() end --make invis until i implement the model
function SWEP:DrawWorldModelTranslucent() end
function SWEP:PreDrawViewModel() return true end

function SWEP:Initialize()
    if(self.SetHoldType) then
        self:SetHoldType("pistol")
    end

    self:DrawShadow(false)

    self.ReloadDelay = CurTime()+1
    self.Dest = Vector(0,0,0)
    self.Door2Ang = Angle(0,0,0)
end

if SERVER then
    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime()+2)
        self:SetNextSecondaryFire(CurTime()+2)

        local ply = self:GetOwner()

        if(not IsValid(ply)) then return end
        if(self.Dest == Vector(0,0,0)) then return end
        if(IsValid(self.Door1)) then return end

        local tr = ply:GetEyeTraceNoCursor()
        local hitpos = tr.HitPos

        local ang = Vector(hitpos - ply:GetPos()):Angle()
        local angp = Angle(0,ang.y,ang.z)
        self.Door1Ang = angp

        self.Door1 = ents.Create("tva_time_door")
        self.Door1:SetPos(hitpos + Vector(0,0,self.Door1.MaxSize+10))
        self.Door1:SetAngles(self.Door1Ang)
        self.Door1:Spawn()

        self.Door2 = ents.Create("tva_time_door")
        self.Door2:SetPos(self.Dest + Vector(0,0,self.Door2.MaxSize+10))
        self.Door2:SetAngles(self.Door2Ang)
        self.Door2:Spawn()

        self.Door1.ConnectedDoor = self.Door2
        self.Door2.ConnectedDoor = self.Door11

        
        timer.Simple(0.4,function()
            self.Door1Portal = ents.Create("linked_portal_door")
            self.Door2Portal = ents.Create("linked_portal_door")
            
            self.Door1Portal:SetWidth(self.Door1.MaxSize+10)
            self.Door1Portal:SetHeight(self.Door1.MaxSize*2+18)
            self.Door1Portal:SetPos(self.Door1:GetPos() + self.Door1:GetForward() * -10)
            self.Door1Portal:SetAngles(self.Door1:GetAngles() + Angle(0,180,0))
            self.Door1Portal:SetExit(self.Door2Portal)
            self.Door1Portal:SetParent(self.Door1)
            self.Door1Portal:Spawn()
            self.Door1Portal:Activate()
            self.Door1Portal:SetRenderMode(1)
            self.Door1Portal:SetTransparency(50)
            self.Door1Portal:SetZFar(500)
            
            self.Door2Portal:SetWidth(self.Door2.MaxSize+10)
            self.Door2Portal:SetHeight(self.Door2.MaxSize*2+18)
            self.Door2Portal:SetPos(self.Door2:GetPos() + self.Door2:GetForward() * -10)
            self.Door2Portal:SetAngles(self.Door2:GetAngles() + Angle(0,180,0))
            self.Door2Portal:SetExit(self.Door1Portal)
            self.Door2Portal:SetParent(self.Door2)
            self.Door2Portal:Spawn()
            self.Door2Portal:Activate()
            self.Door2Portal:SetRenderMode(1)
            self.Door2Portal:SetTransparency(50)
            self.Door2Portal:SetZFar(500)
        end)
    end

    function SWEP:CloseDoor()
        if(not IsValid(self.Door1Portal)) then return end

        self.Door1Portal:Remove()
        self.Door2Portal:Remove()
    end

    function SWEP:SecondaryAttack()
        self:SetNextSecondaryFire(CurTime()+2)

        if(not IsValid(self.Door1)) then return end

        self.Door1:CloseDoor()
        self.Door2:CloseDoor()

        self:CloseDoor()
    end

    function SWEP:Reload()
        if(self.ReloadDelay >= CurTime()) then
            return
        else
            self.ReloadDelay = CurTime()+1
        end

        local ply = self:GetOwner()

        if(not IsValid(ply)) then return end

        local tr = ply:GetEyeTraceNoCursor()
        local hitpos = tr.HitPos

        self.Dest = hitpos

        local ang = Vector(tr.HitPos - ply:GetPos()):Angle()
        local angp = Angle(0,ang.y,ang.z)

        self.Door2Ang = angp
    end
end

timer.Simple(0.1, function() weapons.Register(SWEP,"tva_tempad", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused