AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Time Door"
ENT.Author = "Nova Astral"
ENT.Category = "TVA"
ENT.Contact	= "https://github.com/NovaAstral"
ENT.Purpose	= "Decoration"
ENT.Instructions = "Just put it somewhere"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.MaxSize = 50
ENT.SizeMult = 1


if CLIENT then
    function ENT:Draw()
        self:DrawEntityOutline(0.0)
        self.Entity:DrawModel()
    end

    function ENT:DrawEntityOutline() return end

    function ENT:Think()
        if(self:GetNWBool("On",false) == true) then
            local dlight = DynamicLight(self:EntIndex())

            if(dlight) then
                dlight.Pos = self:GetPos()
                dlight.Brightness = 1
                dlight.Decay = 1024 * 5
                dlight.Size = 400
                dlight.DieTime = CurTime() + 1

                if(self:GetColor() == Color(255,255,255)) then
                dlight.r = 0
                dlight.g = 255
                dlight.b = 158
                else
                dlight.r = self:GetColor().r
                dlight.g = self:GetColor().g
                dlight.b = self:GetColor().b
                end
            end
        end
    end

    function ENT:OpenAnim()
        local scalex = 0*self.SizeMult
        local scaley = 0*self.SizeMult
        local scalez = 5*self.SizeMult
    
        timer.Create("openanim"..self.Entity:EntIndex(),0.01,100,function()
            if(not IsValid(self.Entity)) then return end

            if(scalex < self.MaxSize*self.SizeMult/5) then
                scalex = math.Clamp(scalex+1*self.SizeMult,0,self.MaxSize*self.SizeMult/5)
            end

            if(scaley < self.MaxSize*self.SizeMult) then
                scaley = math.Clamp(scaley+4*self.SizeMult,0,self.MaxSize*self.SizeMult)
            end

            if(scaley >= self.MaxSize*self.SizeMult and scalez < self.MaxSize*self.SizeMult*2) then
                scalez = math.Clamp(scalez+6*self.SizeMult,0,self.MaxSize*self.SizeMult*2)
            end
    
            local mat = Matrix()
            mat:Scale(Vector(scalex,scaley,scalez))
            self.Entity:EnableMatrix("RenderMultiply",mat)
        end)
    end

    function ENT:CloseAnim()
        local scalex = self.MaxSize*self.SizeMult/5
        local scaley = self.MaxSize*self.SizeMult
        local scalez = self.MaxSize*self.SizeMult*2
    
        timer.Create("closeanim"..self.Entity:EntIndex(),0.01,100,function()
            if(not IsValid(self.Entity)) then return end

            if(scalez > 5) then
                scalez = math.Clamp(scalez-6*self.SizeMult,5,self.MaxSize*self.SizeMult*2)
            end

            if(scalez == 5) then
                if(scalex > 0) then
                    scalex = math.Clamp(scalex-1*self.SizeMult,0,self.MaxSize*self.SizeMult/5)
                end

                if(scaley > 0) then
                    scaley = math.Clamp(scaley-4*self.SizeMult,0,self.MaxSize*self.SizeMult)
                end
            end

            if(scaley == 0) then
                net.Start("time_door_close"..self.Entity:EntIndex())
                net.SendToServer()
            end
    
            local mat = Matrix()
            mat:Scale(Vector(scalex,scaley,scalez))
            self.Entity:EnableMatrix("RenderMultiply",mat)
        end)
    end

    function ENT:Initialize()
        local halotbl = {
            self.Entity
        }

        hook.Add("PreDrawHalos","TimeDoorHalo"..self.Entity:EntIndex(),function()
            if(not wp.drawing) then
                halo.Add(halotbl,Color(255,115,0,200),2,0,1)
            end
        end)

        hook.Add("PreDrawOpaqueRenderables","TimeDoorRender"..self.Entity:EntIndex(),function()
            if(wp.drawing) then
                render.Clear(255,115,0,1)
                render.SetColorModulation(0.1,0.1,0.1)
            end
        end)
        
        hook.Add("wp-postrender", "stuff", function(portal)
            local rt = render.GetRenderTarget()
            render.BlurRenderTarget( portal:GetTexture(), 2, 2, 1 )
            render.SetRenderTarget( rt )
        end)


        self.Entity:SetModelScale(0.1,0)

        self:OpenAnim()
        local maxs = Vector(self.MaxSize*self.SizeMult/5,self.MaxSize*self.SizeMult/5,self.MaxSize*self.SizeMult*2)
        local mins = -maxs

        self.Entity:SetRenderBounds(maxs,mins)

        net.Receive("time_door_close"..self.Entity:EntIndex(),function(len,ply)
            self:CloseAnim()
        end)
    end

    function ENT:OnRemove()
        hook.Remove("PreDrawHalos","TimeDoorHalo"..self.Entity:EntIndex())
        hook.Remove("PreDrawSkyBox", "TimeDoorRender"..self.Entity:EntIndex())
        hook.Remove("wp-postrender","stuff"..self.Entity:EntIndex())
    end
else -- server

function ENT:SpawnFunction(ply, tr)
    local ent = ents.Create("tva_time_door")
    ent:SetPos(tr.HitPos + Vector(0, 0, self.MaxSize+10*self.SizeMult))
    ent:SetVar("Owner",ply)
    ent:Spawn()
    return ent
end 

function ENT:Initialize()
    self.Entity:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self.Entity:SetMaterial("models/debug/debugwhite") --probably create a texture later so i can give it blur, maybe even a real texture and not in code
    self.Entity:SetColor(Color(255,115,0,200))
    self.Entity:SetRenderMode(4)
    
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
    self.Entity:SetSolid(SOLID_VPHYSICS)
    self.Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
    
    self.Entity:SetModelScale(0.1,0.0001)
    
    self.Entity:DrawShadow(false)
    
    local phys = self.Entity:GetPhysicsObject()
    
    if(phys:IsValid()) then
        phys:SetMass(100)
        phys:EnableGravity(false)
        phys:Wake()
        phys:EnableMotion(false)
    end

    self.Entity:SetNWBool("On",true)

    self.Entity:EmitSound("tva/timedoor_open.wav")

    self.ConnectedDoor = nil

    util.AddNetworkString("time_door_close"..self.Entity:EntIndex())

    net.Receive("time_door_close"..self.Entity:EntIndex(),function(len,ply)
        if(IsValid(self.Entity)) then
            self.Entity:Remove()
        end
    end)
end

function ENT:CloseDoor()
    self.Entity:EmitSound("tva/timedoor_close.wav")

    net.Start("time_door_close"..self.Entity:EntIndex())
    net.Broadcast()
end

end