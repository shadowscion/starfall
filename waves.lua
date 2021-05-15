
if SERVER then
	return
end

local wireframe = Material("editor/wireframe")

local water = CreateMaterial("water" .. SysTime(), "UnlitGeneric", {
	["$basetexture"] = "color/white",
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
})
local foam = CreateMaterial("foam" .. SysTime(), "UnlitGeneric", {
	["$basetexture"] = "models/props/de_tides/clouds",
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
})

--------------------------------
local render = render
local mesh = mesh
local Vector = Vector
local _vec = Vector()
local _dot = _vec.Dot
local _cross = _vec.Cross
local _normalize = _vec.Normalize

local math = math
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local pi = math.pi

local function BasicGrid(count, uvsize, gridnum, z)
	count = count or 2
	uvsize = uvsize or 4

	local scale = (gridnum / count)*0.5

	local verts = {}
	local faces = {}

	for ycoord = 0, count do
		for xcoord = 0, count do
			local u = (xcoord / uvsize) % 2
			local v = (ycoord / uvsize) % 2

			local vertex = {}
			vertex.pos = Vector(xcoord*scale, ycoord*scale, z or 0)
			vertex.u = u <= 1 and u or 2 - u
			vertex.v = v <= 1 and v or 2 - v

			verts[#verts + 1] = vertex
		end
	end

	local vi, ti = 1, 1
	for ycoord = 1, count do
		for xcoord = 1, count do
			faces[ti + 0] = vi
			faces[ti + 3] = vi + 1
			faces[ti + 2] = vi + 1
			faces[ti + 4] = vi + count + 1
			faces[ti + 1] = vi + count + 1
			faces[ti + 5] = vi + count + 2
			vi = vi + 1
			ti = ti + 6
		end
		vi = vi + 1
	end

	return verts, faces
end


--------------------------------
local Patch = {}
Patch.__index = Patch

--------------------------------
function Patch:Initialize()
	self:ResetCamera()
	self:ResetGrid()
end

--------------------------------
function Patch:ResetCamera()
	local camsize = self.mapsize / self.gridnum

	self.camera = Matrix()
	self.camera:SetScale(Vector(camsize, camsize, camsize))
	self.camera:SetTranslation(Vector(-camsize*0.5*self.gridnum, -camsize*0.5*self.gridnum, -10000))
end

--------------------------------
function Patch:ResetGrid()
	-- water
	self.verts = {}
	self.faces = {}

	for ycoord = 0, self.gridnum do
		for xcoord = 0, self.gridnum do
			local u = (xcoord / self.uvsize) % 2
			local v = (ycoord / self.uvsize) % 2

			local vertex = {}
			vertex.colors = {}
			vertex.normal = Vector(0, 0, 1)
			vertex.xyz = Vector(xcoord, ycoord, 0)
			vertex.pos = Vector(vertex.xyz)
			vertex.u = u <= 1 and u or 2 - u
			vertex.v = v <= 1 and v or 2 - v

			self.verts[#self.verts + 1] = vertex
		end
	end

	local vi, ti = 1, 1
	for ycoord = 1, self.gridnum do
		for xcoord = 1, self.gridnum do
			self.faces[ti + 0] = vi
			self.faces[ti + 3] = vi + 1
			self.faces[ti + 2] = vi + 1
			self.faces[ti + 4] = vi + self.gridnum + 1
			self.faces[ti + 1] = vi + self.gridnum + 1
			self.faces[ti + 5] = vi + self.gridnum + 2
			vi = vi + 1
			ti = ti + 6
		end
		vi = vi + 1
	end

	self.floorv, self.floorf = BasicGrid(nil, nil, self.gridnum * 2, -2)
end

--------------------------------
function Patch:AddColorBlend(id, material, color1, color2)
	local index = table.insert(self.colors, { id = id, material = material, color1 = color1, color2 = color2 })
	for i = 1, #self.verts do
		self.verts[i].colors[index] = { r = 255, g = 255, b = 255, a = 255 }
	end
end

--------------------------------


function Patch:Render()
	cam.PushModelMatrix(self.camera)
		-- ocean floor
		local verts = self.floorv
		local faces = self.floorf
		local fcount = #faces

		render.SetMaterial(water)
		mesh.Begin(MATERIAL_TRIANGLES, fcount / 3)
		for i = 1, fcount do
			local vertex = verts[faces[i]]
			mesh.Position(vertex.pos)
			mesh.TexCoord(0, vertex.u, vertex.v)
			mesh.Color(255, 223, 125, 255)
			mesh.AdvanceVertex()
		end
		mesh.End()

		-- water
		local verts = self.verts
		local faces = self.faces
		local fcount = #faces

		for k, color in ipairs(self.colors) do
			if color.disable then
				goto CONTINUE
			end

			render.SetMaterial(color.material)
			mesh.Begin(MATERIAL_TRIANGLES, fcount / 3)
			for i = 1, fcount do
				local vertex = verts[faces[i]]
				mesh.Position(vertex.pos)
				mesh.TexCoord(0, vertex.u, vertex.v)
				mesh.Normal(vertex.normal)
				local color = vertex.colors[k] or color.color1
				mesh.Color(color.r, color.g, color.b, color.a)
				mesh.AdvanceVertex()
			end
			mesh.End()

			::CONTINUE::
		end

	cam.PopModelMatrix()
end

--------------------------------
function Patch:Update(t, dt)
	local verts = self.verts
	for i = 1, #verts do
		self:UpdateVertex(t, dt, verts[i])
	end
end

--------------------------------
local tan, bin, abs = Vector(), Vector(), Vector()

function Patch:UpdateVertex(t, dt, vertex)
	local pos = vertex.pos
	pos.x = vertex.xyz.x
	pos.y = vertex.xyz.y
	pos.z = vertex.xyz.z

	tan.x = 0
	tan.y = 0
	tan.z = 0
	bin.x = 0
	bin.y = 0
	bin.z = 0

	for i = 1, #self.waves do
		abs.x = pos.x
		abs.y = pos.y

		local wave = self.waves[i]

		local wz = wave.z
		local wa = wave.a
		local wd = wave.xy
		local wf = wave.k * (_dot(wd, abs) - wave.c * t)

		-- tan.x = tan.x - wd.x * wd.x * (wz * sin(wf))
		-- tan.y = tan.y - wd.x * wd.y * (wz * sin(wf))
		-- tan.z = tan.z + wd.x * (wz * cos(wf))

		-- bin.x = bin.x - wd.x * wd.y * (wz * sin(wf))
		-- bin.y = bin.y - wd.y * wd.y * (wz * sin(wf))
		-- bin.z = bin.z + wd.y * (wz * cos(wf))

		pos.x = pos.x + wd.x * (wa * cos(wf))
		pos.y = pos.y + wd.y * (wa * cos(wf))
		pos.z = pos.z + wa * sin(wf)
	end

--	local norm = _cross(bin, tan)
--	_normalize(norm)
--	vertex.normal = norm

	local t = vertex.pos.z
	if t < 0 then t = 0 elseif t > 1 then t = 1 end

	local wcolors = self.colors
	local vcolors = vertex.colors

	for i = 1, #wcolors do
		local c0 = wcolors[i].color1
		local c1 = wcolors[i].color2
		local c2 = vcolors[i]

		c2.r = c0.r + t * (c1.r - c0.r)
		c2.g = c0.g + t * (c1.g - c0.g)
		c2.b = c0.b + t * (c1.b - c0.b)
		c2.a = c0.a + t * (c1.a - c0.a)
	end
end

--------------------------------
function Patch:AddWave(wavelength, steepness, direction)
	local wave = { w = wavelength, z = steepness, xy = direction:GetNormalized() }
	wave.k = 2 * math.pi / wave.w
	wave.c = math.sqrt(9.8 / wave.k)
	wave.a = wave.z / wave.k
	wave.id = table.insert(self.waves, wave)
end

--------------------------------
local function CreatePatch(gridnum, mapsize, uvsize)
	local self = setmetatable({}, Patch)

	self.gridnum = math.floor(gridnum)
	if self.gridnum < 4  then self.gridnum = 4 end
	if self.gridnum > 42 then self.gridnu = 42 end

	self.mapsize = mapsize
	if self.mapsize < 64 then self.mapsize = 64 end
	if self.mapsize > 32768 then self.mapsize = 32768 end

	self.uvsize = uvsize or 4
	self.colors = {}
	self.waves = {}

	self:Initialize()

	return self
end


--------------------------------

local test = CreatePatch(42, 33000, 8)
-- test:AddWave(10, 0.5, Vector(1, 0, 0))
-- test:AddWave(20, 0.25, Vector(0, 1, 0))
-- test:AddWave(10, 0.15, Vector(1, 1, 0))

test:AddWave(10, 0.5/2, Vector(1, 0, 0))
test:AddWave(20, 0.25/2, Vector(0, 1, 0))
test:AddWave(10, 0.15/2, Vector(1, 1, 0))

-- for i = 1, 5 do
-- 	test:AddWave(math.Rand(5, 20), math.Rand(0.05, 0.25), Angle(0, math.random(0, 360), 0):Forward())
-- end
--test:AddColorBlend("wireframe", Material("editor/wireframe"), Color(0, 0, 0), Color(0, 255, 0))


test:AddColorBlend("water", water, Color(6, 66, 115, 255), Color(118, 182, 196, 205))
test:AddColorBlend("foam", foam, Color(29, 162, 216, 15), Color(255, 255, 255, 255))

hook.Add("Think", "PatchTest", function()
	test:Update(CurTime()/3, FrameTime())
end)

hook.Add("PostDrawOpaqueRenderables", "PatchTest", function()
	test:Render()
end)
