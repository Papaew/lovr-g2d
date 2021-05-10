local g = lovr.graphics
local tbl_insert = table.insert

local varr = {{}}
local vmap = {{}}
local meshes = {}

local g2d = {}
local o_proj = lovr.math.newMat4() -- orthographic projection matrix
local p_proj = lovr.math.newMat4() -- perspective projection matrix

-- settings (form stack from these in future)
local _col = {1,1,1,1}
local col = {1,1,1,1}
local lW,pS = 0.5,0.5 --line width, point size
---------------------------------------------------------------------------------------------------------------
local function updProj(w,h)
	o_proj:set(
		2/w, 0, 0, 0,
		0, 2/-h, 0, 0,
		0, 0, -2/(g2d.Z_FAR-g2d.Z_NEAR), 0,
		-w/w, 1, -(g2d.Z_FAR+g2d.Z_NEAR)/(g2d.Z_FAR-g2d.Z_NEAR), 1
	)
end

local function flushBuffers()
	for i=1, #varr do
		if not meshes[i] then
			-- too much memory for colors
			-- any alternatives(?)
			meshes[i] = g.newMesh( {{"lovrPosition", "float", 2}, {"lovrVertexColor", "float", 4}}, g2d.V_MAX, "triangles", 'dynamic', false)
		end

		-- need to replace with blobs
		meshes[i]:setVertices(varr[i], 1, #varr[i])
		meshes[i]:setVertexMap(vmap[i])
		meshes[i]:draw()
	end
end

local function makerect( x,y,w,h )
	local i = #varr
	local total = #varr[i]

	if total + 4 > g2d.V_MAX then
		-- add new batch
		i = #varr+1
		varr[i] = {}
		vmap[i] = {}
		total = 0
	end

	tbl_insert(varr[i], { x,y, 		col[1], col[2], col[3], col[4] })
	tbl_insert(varr[i], { x+w,y, 	col[1], col[2], col[3], col[4] })
	tbl_insert(varr[i], { x+w,y+h,	col[1], col[2], col[3], col[4] })
	tbl_insert(varr[i], { x,y+h,	col[1], col[2], col[3], col[4] })

	tbl_insert(vmap[i], 2+total)
	tbl_insert(vmap[i], 3+total)
	tbl_insert(vmap[i], 4+total)
	tbl_insert(vmap[i], 4+total)
	tbl_insert(vmap[i], 1+total)
	tbl_insert(vmap[i], 2+total)
end

local function makeline( arg ) -- doesn't split vertices into several batches properly
	if #arg < 4 then error("Need at least two vertices to draw a line", 3)
	elseif #arg%2~= 0 then error("Number of vertex must be a multile of two", 3) end

	local i = #varr
	local total = #varr[i]

	if total + 4 > g2d.V_MAX then
		-- add new batch
		i = #varr+1
		varr[i] = {}
		vmap[i] = {}
		total = 0
	end

	local x1,y1,x2,y2, nx,ny, len
	for j=3, #arg, 2 do
		x1,y1 = arg[j-2], arg[j-1]
		x2,y2 = arg[j], arg[j+1]

		nx,ny = y1-y2, x2-x1
		len = (nx*nx + ny*ny)^0.5
		nx,ny = nx/len, ny/len -- not protected from division by zero

		tbl_insert(varr[i], { x1-nx*lW, y1-ny*lW, col[1], col[2], col[3], col[4] })
		tbl_insert(varr[i], { x2-nx*lW, y2-ny*lW, col[1], col[2], col[3], col[4] })
		tbl_insert(varr[i], { x2+nx*lW, y2+ny*lW, col[1], col[2], col[3], col[4] })
		tbl_insert(varr[i], { x1+nx*lW, y1+ny*lW, col[1], col[2], col[3], col[4] })

		total = total+4
		tbl_insert(vmap[i], total-3)
		tbl_insert(vmap[i], total-2)
		tbl_insert(vmap[i], total-1)
		tbl_insert(vmap[i], total-1)
		tbl_insert(vmap[i], total)
		tbl_insert(vmap[i], total-3)
		
	end

end

local function makepoints( arg )
	if #arg % 2 ~= 0 then error("Number of vertex must be a multile of two", 3) end

	local x,y, total
	for v=1, #arg*2, g2d.V_MAX do
		local i = #varr
		local total = #varr[i]

		v = math.ceil(v*0.5)

		for j=v, math.min(v+g2d.V_MAX*0.5-1, #arg), 2 do -- kinda messy
			if total + 4 > g2d.V_MAX then
				-- add new batch
				i = #varr+1
				varr[i] = {}
				vmap[i] = {}
				total = 0
			end

			x,y = arg[j]+0.5, arg[j+1]+0.5

			tbl_insert(varr[i], { x-pS, y-pS, col[1], col[2], col[3], col[4] })
			tbl_insert(varr[i], { x+pS, y-pS, col[1], col[2], col[3], col[4] })
			tbl_insert(varr[i], { x+pS, y+pS, col[1], col[2], col[3], col[4] })
			tbl_insert(varr[i], { x-pS, y+pS, col[1], col[2], col[3], col[4] })

			tbl_insert(vmap[i], 2+total)
			tbl_insert(vmap[i], 3+total)
			tbl_insert(vmap[i], 4+total)
			tbl_insert(vmap[i], 4+total)
			tbl_insert(vmap[i], 1+total)
			tbl_insert(vmap[i], 2+total)
		
			total = total + 4
		end
	end

end

-- API --------------------------------------------------------------------------------------------------------
function g2d.init( max_vertices, near,far )

	g2d.V_MAX = max_vertices or 25000
	g2d.Z_NEAR = near or -1
	g2d.Z_FAR = far or 1

	updProj(g.getDimensions())

	return g2d
end

function g2d.set()
	-- save current color, projection matrix and transform stack
	p_proj = g.getProjection(1, p_proj)
	_col = {g.getColor()}
	g.push()

	-- switch to orthographic projection
	g.setProjection(1, o_proj)
	g.setColor(1,1,1)

	-- reset vertex map and vertex array
	vmap = {{}}
	varr = {{}}
end

function g2d.unset()
	-- form meshes from vertex arrays and draw it on screen
	flushBuffers()

	-- turn back projection matrix and color
	g.setProjection(1, p_proj)
	g.setColor(_col)
	g.pop()
end

function g2d.rectangle( mode, x,y, w,h )
	if mode == "fill" then
		makerect( x,y,w,h )
	elseif mode == "line" then
		makeline({x,y, x+w,y, x+w,y+h, x,y+h, x,y})
	end
end

function g2d.points( ... )
	makepoints( type(...) == "table" and (...) or {...} )
end

function g2d.line( ... )
	makeline( type(...) == "table" and (...) or {...} )
end

---------------------------------------------------------------------------------------------------------------

function g2d.setColor( r, _g, b, a )
	col[1], col[2], col[3], col[4] = r, _g, b, a or 1
end

function g2d.getColor( r,g,b,a )
	return col[1], col[2], col[3], col[4]
end

function g2d.setLineWidth( val )
	lW = val*0.5
end

function g2d.getLineWidth()
	return lW*2
end

function g2d.setPointSize( val )
	pS = val*0.5
end

function g2d.getPointSize()
	return pS*2
end

---------------------------------------------------------------------------------------------------------------
local ffi = require 'ffi'
local C = ffi.os == 'Windows' and ffi.load('glfw3') or ffi.C
local C_str = ffi.string
ffi.cdef [[
	typedef struct GLFWwindow GLFWwindow;
	GLFWwindow* glfwGetCurrentContext(void);

	typedef void(* GLFWwindowsizefun) (GLFWwindow *, int, int);
	GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, GLFWwindowsizefun callback);
]]

local W = C.glfwGetCurrentContext()
C.glfwSetWindowSizeCallback(W, function(_, w, h)
	updProj(w,h)

	-- called after the mouse button released and stretches things up. not good
	-- lovr.event.push('resize', w, h)

	if lovr.resize then
		lovr.resize(w,h) -- instant function call
	end
end)

return g2d
