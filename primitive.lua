local constructPrimitive
do
	local primitives = {}
	local function registerPrimitive(name, verts, faces)
		primitives[name] = {
			verts = verts,
			faces = faces,
		}
	end

	function constructPrimitive(name, pos, scale)
		local primitive = primitives[name]
		if not primitive then return end

		local hull = {}
		for k, v in ipairs(primitive.verts) do
			local vert = Vector(v)
			if scale then
				vert.x = vert.x*scale.x
				vert.y = vert.y*scale.y
				vert.z = vert.z*scale.z
			end
			if pos then
				vert.x = vert.x+pos.x
				vert.y = vert.y+pos.y
				vert.z = vert.z+pos.z
			end
			hull[k] = vert
		end

		local tris
		if CLIENT then
			local uv = 1/48
			tris = {}
			for k, face in ipairs(primitive.faces) do
				local t1 = face[1]
				local t2 = face[2]
				for j = 3, #face do
					local t3 = face[j]
					local v1, v2, v3 = hull[t1], hull[t2], hull[t3]
					local normal = (v3 - v1):Cross(v2 - v1)
					normal:Normalize()

					v1 = { pos = v1, normal = normal }
					v2 = { pos = v2, normal = normal }
					v3 = { pos = v3, normal = normal }

					local nx, ny, nz = math.abs(normal.x), math.abs(normal.y), math.abs(normal.z)
					if nx > ny and nx > nz then
						local nw = normal.x < 0 and -1 or 1
						v1.u = v1.pos.z*nw*uv
						v1.v = v1.pos.y*uv
						v2.u = v2.pos.z*nw*uv
						v2.v = v2.pos.y*uv
						v3.u = v3.pos.z*nw*uv
						v3.v = v3.pos.y*uv
					elseif ny > nz then
						local nw = normal.y < 0 and -1 or 1
						v1.u = v1.pos.x*uv
						v1.v = v1.pos.z*nw*uv
						v2.u = v2.pos.x*uv
						v2.v = v2.pos.z*nw*uv
						v3.u = v3.pos.x*uv
						v3.v = v3.pos.z*nw*uv
					else
						local nw = normal.z < 0 and 1 or -1
						v1.u = v1.pos.x*nw*uv
						v1.v = v1.pos.y*uv
						v2.u = v2.pos.x*nw*uv
						v2.v = v2.pos.y*uv
						v3.u = v3.pos.x*nw*uv
						v3.v = v3.pos.y*uv
					end

					tris[#tris + 1] = v1
					tris[#tris + 1] = v2
					tris[#tris + 1] = v3
                                	t2 = t3
				end
			end
		end

		return hull, tris
	end

	registerPrimitive("wedge",
		{
			Vector(-0.500000,-0.500000,0.500000),
			Vector(-0.500000,0.500000,0.300000),
			Vector(-0.500000,-0.500000,0.300000),
			Vector(0.500000,-0.000000,-0.500000),
			Vector(0.500000,-0.500000,0.300000),
			Vector(0.500000,-0.500000,0.500000),
			Vector(0.500000,0.500000,0.500000),
			Vector(0.500000,0.500000,0.300000),
			Vector(-0.500000,0.500000,0.500000),
			Vector(-0.500000,0.000000,-0.500000),
		},
		{
			{1,3,2},
			{3,5,4},
			{6,5,3},
			{2,8,7},
			{6,1,9},
			{2,10,4},
			{7,8,5},
			{9,1,2},
			{2,3,10},
			{3,4,10},
			{6,3,1},
			{2,7,9},
			{6,9,7},
			{2,4,8},
			{6,7,5},
			{5,8,4},
		}
	)
	registerPrimitive("spike",
		{
			Vector(0.500000,-0.500000,0.300000),
			Vector(-0.500000,-0.500000,0.500000),
			Vector(-0.500000,-0.500000,0.300000),
			Vector(0.500000,0.500000,0.300000),
			Vector(0.000000,0.000000,-0.500000),
			Vector(-0.500000,0.500000,0.300000),
			Vector(0.500000,0.500000,0.500000),
			Vector(0.500000,-0.500000,0.500000),
			Vector(-0.500000,0.500000,0.500000),
		},
		{
			{1,3,2},
			{4,5,1},
			{5,6,3},
			{2,3,6},
			{6,4,7},
			{4,1,8},
			{2,9,7},
			{4,6,5},
			{3,1,5},
			{1,2,8},
			{2,6,9},
			{6,7,9},
			{4,8,7},
			{2,7,8},
		}
	)
	registerPrimitive("cube",
		{
			Vector(-0.500000,0.500000,-0.500000),
			Vector(-0.500000,0.500000,0.500000),
			Vector(0.500000,0.500000,-0.500000),
			Vector(0.500000,0.500000,0.500000),
			Vector(-0.500000,-0.500000,-0.500000),
			Vector(-0.500000,-0.500000,0.500000),
			Vector(0.500000,-0.500000,-0.500000),
			Vector(0.500000,-0.500000,0.500000),
		},
		{
			{3,2,1},
			{7,4,3},
			{5,8,7},
			{1,6,5},
			{1,7,3},
			{6,4,8},
			{3,4,2},
			{7,8,4},
			{5,6,8},
			{1,2,6},
			{1,5,7},
			{6,2,4},
		}
	)
end
