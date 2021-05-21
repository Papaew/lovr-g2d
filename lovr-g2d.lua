local g2d = {}
local g = lovr.graphics
local tbl_add, min, sin,cos, rad = table.insert, math.min, math.sin,math.cos, math.rad
local base = ...

local ffi = require 'ffi'
local C = ffi.os == 'Windows' and ffi.load('glfw3') or ffi.C
local C_str = ffi.string
ffi.cdef [[
	typedef struct GLFWwindow GLFWwindow;
	GLFWwindow* glfwGetCurrentContext(void);

	typedef void(*GLFWwindowsizefun) (GLFWwindow*, int, int);
	GLFWwindowsizefun glfwSetFramebufferSizeCallback(GLFWwindow* window, GLFWwindowsizefun callback);
]]

local p_proj = lovr.math.newMat4() -- perspective projection matrix
local o_proj = lovr.math.newMat4() -- orthographic projection matrix
local Z_NEAR, Z_FAR = -1, 1

local function updProj( w,h )
	o_proj:set(
		2/w, 0, 0, 0,
		0, 2/-h, 0, 0,
		0, 0, -2/(Z_FAR-Z_NEAR), 0,
		-w/w, 1, -(Z_FAR+Z_NEAR)/(Z_FAR-Z_NEAR), 1
	)
end

local W = C.glfwGetCurrentContext()
C.glfwSetFramebufferSizeCallback(W, function( _, w,h )
	updProj(w,h)
end)

---------------------------------------------------------------------------------------------------------------
local max_vertices, max_indices
local batch, varr, vertices
local vmap, indices

ffi.cdef([[
struct vertex {
	float position[2];
	uint8_t color[4];
};
]])
local ct_vertex = ffi.typeof("struct vertex")

local vCount = 0 -- current vertex count
local mIndex = 0 -- vertex map last index

local imgMat = lovr.graphics.newMaterial()
local imgMesh = g.newMesh( {{"lovrPosition", "float", 2}, {"lovrTexCoord", "float", 2}}, 4, "triangles", 'static', false)
imgMesh:setVertexMap({1,2,3, 3,4,1})
imgMesh:setMaterial(imgMat)
---------------------------------------------------------------------------------------------------------------
local basicFont
local lStack = {} -- lua stack for fonts and shaders
local stack, maxStack
local curstack = 0

ffi.cdef([[
typedef struct {
	uint8_t color[4];
	uint16_t lineWidth;
	uint16_t pointSize;
	bool wireframe;
	// font
	// shader
} stackData;
]])

-- struct to keep lovr graphics stack
local gStack = {
	r=1, g=1, b=1, a=1,
	wireframe = false
}

---------------------------------------------------------------------------------------------------------------
function g2d.init( maxTriangles, stackSize, zNear, zFar, useVeraSans )

	max_vertices = maxTriangles and maxTriangles*3 or 15000 -- by default maximum is 5k triangles
	max_indices = maxTriangles and maxTriangles*6 or 30000

	-- vertex buffer
	batch = g.newMesh( {{"lovrPosition", "float", 2}, {"lovrVertexColor", "ubyte", 4}}, max_vertices, "triangles", 'dynamic', false)
	varr = lovr.data.newBlob(max_vertices * ffi.sizeof(ct_vertex), "varr")
	vertices = ffi.cast("struct vertex*", varr:getPointer())

	-- vertex map
	vmap = lovr.data.newBlob(max_indices * ffi.sizeof("uint16_t"), "vmap")
	indices = ffi.cast("uint16_t*", vmap:getPointer())

	-- stack
	maxStack = stackSize or 64
	curstack = 0
	stack = ffi.new("stackData["..maxStack.."]")

	-- stack setup
	stack[0].color[0] = 255
	stack[0].color[1] = 255
	stack[0].color[2] = 255
	stack[0].color[3] = 255
	stack[0].lineWidth = 1
	stack[0].pointSize = 1
	stack[0].wireframe = false

	basicFont = useVeraSans and g.newFont(base .. "/Vera.ttf", 12, 5, 100) or g.newFont(12, 10, 5)
	basicFont:setPixelDensity(1)
	basicFont:setFlipEnabled(true)
	lStack[0] = {font = basicFont}

	-- projection
	Z_NEAR = zNear or -1
	Z_FAR = zFar or 1

	updProj(g.getDimensions())
	return g2d
end

---------------------------------------------------------------------------------------------------------------

local function flushBatch()
	if vCount > 0 then
		batch:setVertices(varr, 1, vCount)
		batch:setVertexMap(vmap, 2)
		batch:setDrawRange(1, mIndex)

		g.setColor(1,1,1)
		batch:draw()
		g.flush()
	end

	vCount = 0
	mIndex = 0
end

local function makeLine( ... )
	local arg = type(...) == "table" and (...) or {...}
	local lastindex = math.min( #arg-2, (max_vertices-vCount)*0.5 )
	local lW = stack[curstack].lineWidth*0.5

	local x1,y1,x2,y2, nx,ny, len
	for i=1, lastindex, 2 do
		x1,y1 = arg[i], arg[i+1]
		x2,y2 = arg[i+2], arg[i+3]

		nx,ny = y1-y2, x2-x1
		len = (nx*nx + ny*ny)^0.5 + 0.000001
		nx,ny = nx/len, ny/len -- not protected from division by zero

		-- vertex 1
		vertices[vCount].position[0] = x1-nx*lW
		vertices[vCount].position[1] = y1-ny*lW
		-- vertex 2
		vertices[vCount+1].position[0] = x2-nx*lW
		vertices[vCount+1].position[1] = y2-ny*lW
		-- vertex 3
		vertices[vCount+2].position[0] = x2+nx*lW
		vertices[vCount+2].position[1] = y2+ny*lW
		-- vertex 4
		vertices[vCount+3].position[0] = x1+nx*lW
		vertices[vCount+3].position[1] = y1+ny*lW

		-- set vertex color from current stack
		ffi.copy(vertices[vCount].color, stack[curstack].color, 4)
		ffi.copy(vertices[vCount+1].color, stack[curstack].color, 4)
		ffi.copy(vertices[vCount+2].color, stack[curstack].color, 4)
		ffi.copy(vertices[vCount+3].color, stack[curstack].color, 4)

		-- add indices to vertex map
		indices[mIndex] = vCount
		indices[mIndex+1] = vCount+1
		indices[mIndex+2] = vCount+2
		indices[mIndex+3] = vCount+2
		indices[mIndex+4] = vCount+3
		indices[mIndex+5] = vCount

		vCount = vCount + 4
		mIndex = mIndex + 6
	end

	if lastindex < #arg-2 then
		flushBatch()
		makeLine( select(lastindex+1, unpack(arg)) )
	end
end

local function makeRect( x,y, w,h )
	if vCount + 4 > max_vertices or mIndex + 6 > max_indices then
		flushBatch()
	end

	-- vertex 1
	vertices[vCount].position[0] = x
	vertices[vCount].position[1] = y
	-- vertex 2
	vertices[vCount+1].position[0] = x+w
	vertices[vCount+1].position[1] = y
	-- vertex 3
	vertices[vCount+2].position[0] = x+w
	vertices[vCount+2].position[1] = y+h
	-- vertex 4
	vertices[vCount+3].position[0] = x
	vertices[vCount+3].position[1] = y+h

	-- set vertex color from current stack
	ffi.copy(vertices[vCount].color, stack[curstack].color, 4)
	ffi.copy(vertices[vCount+1].color, stack[curstack].color, 4)
	ffi.copy(vertices[vCount+2].color, stack[curstack].color, 4)
	ffi.copy(vertices[vCount+3].color, stack[curstack].color, 4)

	-- add indices to vertex map
	indices[mIndex] = vCount
	indices[mIndex+1] = vCount+1
	indices[mIndex+2] = vCount+2
	indices[mIndex+3] = vCount+2
	indices[mIndex+4] = vCount+3
	indices[mIndex+5] = vCount

	vCount = vCount + 4
	mIndex = mIndex + 6

end

local function makeCircle( x,y, r, s )
	if vCount + s+1 > max_vertices or mIndex + s*3 > max_indices then
		flushBatch()
	end

	local first = vCount
	vertices[vCount].position[0] = x
	vertices[vCount].position[1] = y
	-- copy color from stack
	ffi.copy(vertices[vCount].color, stack[curstack].color, 4)

	vCount = vCount + 1
	for i=0, 360, 360/s do
		vertices[vCount].position[0] = x + cos(rad(i))*r
		vertices[vCount].position[1] = y + sin(rad(i))*r

		-- copy color from stack
		ffi.copy(vertices[vCount].color, stack[curstack].color, 4)

		vCount = vCount + 1
	end

	for i=first, first+s-1 do
		indices[mIndex] = first
		indices[mIndex+1] = i
		indices[mIndex+2] = i+1

		mIndex = mIndex + 3
	end

	indices[mIndex] = first
	indices[mIndex+1] = first+s
	indices[mIndex+2] = first+1

	mIndex = mIndex + 3

end

-- API --------------------------------------------------------------------------------------------------------

function g2d.points( ... )
	local arg = type(...) == "table" and (...) or {...}
	local lastindex = min( #arg, (max_vertices-vCount)*0.5 )
	local pS = stack[curstack].pointSize*0.5

	for j=1, lastindex, 2 do
		local x,y = arg[j]+0.5, arg[j+1]+0.5
		-- vertex 1
		vertices[vCount].position[0] = x-pS
		vertices[vCount].position[1] = y-pS
		-- vertex 2
		vertices[vCount+1].position[0] = x+pS
		vertices[vCount+1].position[1] = y-pS
		-- vertex 3
		vertices[vCount+2].position[0] = x+pS
		vertices[vCount+2].position[1] = y+pS
		-- vertex 4
		vertices[vCount+3].position[0] = x-pS
		vertices[vCount+3].position[1] = y+pS

		-- set vertex color from current stack
		ffi.copy(vertices[vCount].color, stack[curstack].color, 4)
		ffi.copy(vertices[vCount+1].color, stack[curstack].color, 4)
		ffi.copy(vertices[vCount+2].color, stack[curstack].color, 4)
		ffi.copy(vertices[vCount+3].color, stack[curstack].color, 4)
		
		-- add indices to vertex map
		indices[mIndex] = vCount
		indices[mIndex+1] = vCount+1
		indices[mIndex+2] = vCount+2
		indices[mIndex+3] = vCount+2
		indices[mIndex+4] = vCount+3
		indices[mIndex+5] = vCount

		vCount = vCount + 4
		mIndex = mIndex + 6
	end

	if lastindex < #arg then
		flushBatch()
		g2d.points(select(lastindex+1, unpack(arg)))
	end
end

function g2d.print( text, x,y, r, halign, valign )

	g.setColor( stack[curstack].color[0]/255,
				stack[curstack].color[1]/255,
				stack[curstack].color[2]/255,
				stack[curstack].color[3]/255)

	g.print(text, x or 0, y or 0, 0, 1, r or 0, 0,0,1, 0, halign or "left", valign or "top")
	g.setColor(1,1,1)
end

function g2d.line( ... )
	makeLine( ... )
end

function g2d.rectangle( mode, x,y, w,h )
	if mode == "fill" then
		makeRect(x,y, w,h)
	elseif mode == "line" then
		makeLine(x,y, x+w,y, x+w,y+h, x,y+h, x,y)
	end
end

function g2d.circle( mode, x,y, radius, segments )
	segments = segments or 30
	if mode == "fill" then
		makeCircle( x,y, radius, segments )
	elseif mode == "line" then
		local pts = {}
		for i=0, 360, 360/segments do
			table.insert(pts, x + cos( rad(i))*radius )
			table.insert(pts, y + sin( rad(i))*radius )
		end

		makeLine(unpack(pts))
	end
end

function g2d.draw( texture, x,y, r )
	x,y,r = x or 0, y or 0, r or 0
	local w,h = texture:getDimensions()
	imgMat:setColor(stack[curstack].color[0]/255,
					stack[curstack].color[1]/255,
					stack[curstack].color[2]/255,
					stack[curstack].color[3]/255)

	imgMat:setTexture(texture)
	imgMesh:setVertices( {{0,0, 0,1}, {w,0, 1,1}, {w,h, 1,0}, {0,h, 0,0}} )
	imgMesh:draw(x,y,0, 1, r, 0,0,1)
end

---------------------------------------------------------------------------------------------------------------

function g2d.reset()
	g.setShader()
	g.setColor(1,1,1)
	g.setFont( basicFont )
	stack[curstack].color[0] = 255
	stack[curstack].color[1] = 255
	stack[curstack].color[2] = 255
	stack[curstack].color[3] = 255
	stack[curstack].lineWidth = 1
	stack[curstack].pointSize = 1
	stack[curstack].wireframe = false
	lStack[curstack] = {font = basicFont}
end


function g2d.set()
	-- save current stack
	p_proj = g.getProjection(1, p_proj)
	gStack.r, gStack.g, gStack.b, gStack.a = g.getColor()
	gStack.wireframe = g.isWireframe()
	gStack.shader = g.getShader()
	gStack.font = g.getFont()

	-- set orthographic projection
	g.push()
	g.origin()
	g.setColor(1,1,1)
	g.setProjection(1, o_proj)
	g.setFont(lStack[curstack].font)
end

function g2d.unset()
	-- draw everything last in the batch on the screen
	flushBatch()
	
	-- turn back lovr stack
	g.pop()
	g.setProjection(1, p_proj)
	g.setColor(gStack.r, gStack.g, gStack.b, gStack.a)
	g.setWireframe(gStack.wireframe)
	g.setShader(gStack.shader)
	g.setFont(gStack.font)
end

function g2d.push()
	curstack = curstack + 1
	if curstack >= maxStack then error("Stack is too deep! ("..maxStack..")", 2) end

	lStack[curstack] = {font = basicFont}
	ffi.copy(stack[curstack], stack[curstack-1], ffi.sizeof("stackData"))
end

function g2d.pop()
	if curstack == 0 then error("Too much pop() calls!", 2) end
	curstack = curstack - 1
	-- change font and shader
	g.setFont(lStack[curstack].font)
end

---------------------------------------------------------------------------------------------------------------

function g2d.setFont( font )
	lStack[curstack].font = font or basicFont
	lStack[curstack].font:setPixelDensity(1)
	lStack[curstack].font:setFlipEnabled(true)
	g.setFont(lStack[curstack].font)
end

function g2d.getFont()
	return lStack[curstack].font
end

function g2d.setShader( s )
	flushBatch()
	lStack[curstack].shader = s
	g.setShader(s)
end

function g2d.getShader()
	return lStack[curstack].shader
end

function g2d.setColor( r, _g, b, a )
	stack[curstack].color[0] = r*255
	stack[curstack].color[1] = _g*255
	stack[curstack].color[2] = b*255
	stack[curstack].color[3] = a and a*255 or 255
end

function g2d.getColor()
	return	stack[curstack].color[0]/255,
			stack[curstack].color[1]/255,
			stack[curstack].color[2]/255,
			stack[curstack].color[3]/255
end

function g2d.setWireframe( enable )
	flushBatch()
	g.setWireframe(enable)
	stack[curstack].wireframe = enable
end

function g2d.isWireframe()
	return stack[curstack].wireframe
end

function g2d.setLineWidth( val )
	stack[curstack].lineWidth = val
end

function g2d.getLineWidth()
	return stack[curstack].lineWidth
end

function g2d.setPointSize( val )
	stack[curstack].pointSize = val
end

function g2d.getPointSize()
	return stack[curstack].pointSize
end

---------------------------------------------------------------------------------------------------------------
return g2d
