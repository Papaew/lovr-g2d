# lovr-g2d
A 2d graphics rendering library for [LÖVR](https://lovr.org)

# Usage
![alt text](https://github.com/Papaew/lovr-g2d/blob/main/resources/test.png?raw=true)
```lua
g2d = require("lovr-g2d").init()

-- https://github.com/Papaew/lovr-g2d/blob/main/resources/lovr-ico.png
local image = lovr.graphics.newTexture("/lovr-ico.png")
function lovr.draw()
    g2d.set()
        g2d.print("Hello, LÖVR!", 10,10)
        g2d.draw(image, 14,30)
    g2d.unset()
end
```

# API
###### Coordinate System
| Function | Description |
|-|-|
| [g2d.init()](#init) | Initializes the module with selected settings |
| [g2d.set()](#set) | The entry point into drawing 2D graphics |
| [g2d.unset()](#unset) | Exit point from drawing 2D graphics |
| [g2d.push()](#push) | Copies and pushes the current rendering settings onto the stack |
| [g2d.pop()](#pop) | Pops the current rendering settings from the stack |
| [g2d.reset()](#reset) | Resets the current graphics settings |
###### Drawing
| Function | Description |
|-|-|
| [g2d.draw()](#circle) | Draws a texture on the screen |
| [g2d.circle()](#circle) | Draws a circle |
| [g2d.line()](#line) | Draws lines between points |
| [g2d.points()](#points) | Draws one or more points |
| [g2d.print()](#print) | Draws text on screen |
| [g2d.rectangle()](#rectangle) | Draws a rectangle |
###### Graphics State
| Function | Description |
|-|-|
| [g2d.getColor()](#getColor) | Gets the current color |
| [g2d.getFont()](#getFont) | Gets the current Font object |
| [g2d.getLineWidth()](#getLineWidth) | Gets the current line width |
| [g2d.getPointSize()](#getPointSize) | Gets the point size |
| [g2d.getShader()](#getShader) | Gets the current Shader |
| [g2d.isWireframe()](#isWireframe) | Gets whether wireframe mode is used when drawing |
| [g2d.setColor( r,g,b,a )](#setColor) | Sets the color used for drawing |
| [g2d.setFont( font )](#setFont) | Set an already-loaded Font as the current font |
| [g2d.setlineWidth( width )](#setlineWidth) | Sets the line width |
| [g2d.setPointSize( size )](#setPointSize) | Sets the point size |
| [g2d.setShader( shader )](#setShader) | Routes drawing operations through a shader |
| [g2d.setWireframe( enabled )](#setWireframe) | Sets whether wireframe lines will be used when drawing |


# TODO
- Stacks and coordinate system transform functions
  - origin, translate, rotate, scale
- Quad, spritebatches and image autobatching [most likely based on this](https://github.com/rxi/autobatch)
- Shape rendering functions
  - arc, ellipse, polygon
  - line join styles, anti-aliasing for lines
- stencil and blend modes support(?)


# Documentation
## init()
#### Initializes the module with selected settings. 
###### Function 
``` lua
g2d = require("lovr-g2d").init( maxTriangles, stackSize, zNear, zFar, useVeraSans )
```

###### Arguments
**[`number`](#number)** maxTriangles (5000) <br>
**[`number`](#number)** stackSize (64) <br>
**[`number`](#number)** zNear (-1) <br>
**[`number`](#number)** zFar (1) <br>
**[`boolean`](#boolean)** useVeraSans <br>

###### Returns
**[`table`](#number)** g2d





## set()
#### The entry point into drawing 2D graphics.
#### Can be called several times per frame, but must be closed with [g2d.unset()](#unset)
###### Function 
``` lua
g2d:set()
-- draw 2d stuff
```

###### Arguments
None.

###### Returns
Nothing.

###### Notes
Functions from [lovr.graphics](https://lovr.org/docs/v0.15.0/lovr.graphics) called between [g2d.set()](#set) and [g2d.unset()](#unset) may not work correctly




## unset()
#### Exit point from drawing 2D graphics.
#### Must be called after [g2d.set()](#set) for correct rendering
###### Function 
``` lua
-- draw 2d stuff
g2d:unset()
```

###### Arguments
None.

###### Returns
Nothing.






## push()
#### Copies and pushes the current graphics state to the stack
###### Function 
``` lua
g2d:push()
```

###### Arguments
None.

###### Returns
Nothing.

###### Usage
```lua
-- set the current color to red
g2d.setColor(1,0,0)

g2d.push() -- save current graphics state so any changes can be restored

    -- draw something else with a different color
    g2d.setColor(1,0,0)
    g2d.circle("fill", 100,100, 30)

g2d.pop() -- restore the saved graphics state

-- draw a rectangle with restored red color
g2d.rectangle("fill", 64,32, 128,96)
```

###### Notes
The function saves the following types of states:
- current color
- active font
- active shader
- wireframe mode
- line width
- point size






## pop()
#### Returns the current graphics state to what it was before the last preceding [g2d.push()](#push)
###### Function 
``` lua
g2d:pop()
```

###### Arguments
None.

###### Returns
Nothing.





## reset()
#### Resets the current graphics settings to default <br>
#### Makes the current drawing color white, disables active shader and wireframe mode <br>
#### Also changes current font to default, line width and point size to 1.0
###### Function 
``` lua
g2d.reset()
```

###### Arguments
None.

###### Returns
Nothing.

###### Notes
This function, like any other function that change graphics state, only affects the current stack





## draw()
#### Draws a [Texture](https://lovr.org/docs/v0.15.0/Texture) on the screen with optional rotation
###### Function 
``` lua
g2d.draw( texture, x,y, angle )
```

###### Arguments
**[`Texture`](https://lovr.org/docs/v0.15.0/Texture)** texture <br>
**[`number`](#number)** x <br>
**[`number`](#number)** y <br>
**[`number`](#number)** angle

###### Returns
Nothing.

###### Usage
```lua
function lovr.load()
    hamster = lovr.graphics.newTexture("hamster.png")
end

function lovr.draw()
    g2d.set()
        g2d.draw(hamster, 100, 100)
    g2d.unset()
end
```





## circle()
#### Draws a circle on the screen
###### Function 
``` lua
g2d.circle( mode, x,y, radius, segments  )
```

###### Arguments
**[`DrawMode`](#DrawMode)** mode <br>
**[`number`](#number)** x <br>
**[`number`](#number)** y <br>
**[`number`](#number)** radius <br>
**[`number`](#number)** segments

###### Returns
Nothing.





## line()
#### Draws lines between points
###### Function 
``` lua
g2d.line( x1, y1, x2, y2, ...  )
```

###### Arguments
**[`number`](#number)** x1 <br>
**[`number`](#number)** y1 <br>
**[`number`](#number)** x2 <br>
**[`number`](#number)** y2 <br>
**[`number`](#number)** ... <br>
You can continue passing point positions


###### Returns
Nothing.

###### Usage
```lua
function lovr.load()
    sometable = {
        100, 100,
        200, 200,
        300, 100,
        400, 200,
    }
end

function lovr.draw()
    g2d.set()
        g2d.line(200,50, 400,50, 500,300, 100,300, 200,50)
        g2d.line(sometable) -- Also table of point positions can be passed
    g2d.unset()
end
```





## points()
#### Draws one or more points
###### Function 
``` lua
g2d.points( x, y, ...  )
```

###### Arguments
**[`number`](#number)** x <br>
**[`number`](#number)** y <br>
**[`number`](#number)** ... <br>
You can continue passing point positions

###### Returns
Nothing.

###### Usage
```lua
function lovr.load()
    sometable = {
        100, 100,
        200, 200,
        300, 100,
        400, 200,
    }
end

function lovr.draw()
    g2d.set()
        g2d.points(200,50, 400,50, 500,300, 100,300, 200,50)
        g2d.points(sometable) -- Also table of point positions can be passed
    g2d.unset()
end
```





## print()
#### Draws text on screen
###### Function 
``` lua
g2d.print( text, x,y, r, halign, valign )
```

###### Arguments
**[`string`](#string)** text <br>
**[`number`](#number)** x <br>
**[`number`](#number)** y <br>
**[`number`](#number)** angle <br>
**[`HorizontalAlign`](#HorizontalAlign)** halign <br>
**[`VerticalAlign`](#VerticalAlign)** valign

###### Returns
Nothing.





## rectangle()
#### Draws a rectangle
###### Function 
``` lua
g2d.print( mode, x,y, width,height )
```

###### Arguments
**[`DrawMode`](#DrawMode)** mode <br>
**[`number`](#number)** x <br>
**[`number`](#number)** y <br>
**[`number`](#number)** width <br>
**[`number`](#number)** height <br>

###### Returns
Nothing.





## setColor()
#### Sets the color used for drawing objects
###### Function 
``` lua
g2d.setColor( r,g,b,a )
```

###### Arguments
**[`number`](#number)** r <br>
**[`number`](#number)** g <br>
**[`number`](#number)** b <br>
**[`number`](#number)** a

###### Returns
Nothing.





## setFont()
#### Sets the active font used to render text with [g2d.print](#print)
###### Function 
``` lua
g2d.setFont( font )
```

###### Arguments
**[`Font`](https://lovr.org/docs/v0.15.0/Font)** font

###### Returns
Nothing.





## setlineWidth()
#### Sets the width of lines rendered using [g2d.line](#line)
###### Function 
``` lua
g2d.setlineWidth( width )
```

###### Arguments
**[`number`](#number)** width

###### Returns
Nothing.





## setPointSize()
#### Sets the width of drawn points, in pixels
###### Function 
``` lua
g2d.setPointSize( size )
```

###### Arguments
**[`number`](#number)** size

###### Returns
Nothing.





## setShader()
#### Sets or disables the Shader used for drawing
###### Function 
``` lua
g2d.setShader( shader )
```

###### Arguments
**[`Shader`](https://lovr.org/docs/v0.15.0/Shader)** shader

###### Returns
Nothing.


###### Usage
```lua
-- smol rainbow effect shader
shader = g.newShader([[
// vertex shader
vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
    return projection * transform * vertex;
} ]], [[
// fragment shader
uniform float time;
vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) {
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    return vec4(col, 1.0) * lovrVertexColor * texture(image, uv);
} ]])

local time = 0
function lovr.update(dt)
    time = time + dt
    shader:send("time", time)
end

function lovr.draw()
    g2d.set()
        g2d.setShader(shader)
            g2d.circle('fill', 100,100, 50)
        g2d.setShader()
    g2d.unset()
end
```




## setWireframe()
#### Enables or disables wireframe rendering
###### Function 
``` lua
g2d.setWireframe( enabled )
```

###### Arguments
**[`boolean`](#boolean)** enabled

###### Returns
Nothing.





## getColor()
#### Returns the current color
###### Function 
``` lua
g2d.getColor()
```

###### Arguments
None.

###### Returns
**[`number`](#number)** r <br>
**[`number`](#number)** g <br>
**[`number`](#number)** b <br>
**[`number`](#number)** a





## getFont()
#### Returns the active font
###### Function 
``` lua
g2d.getFont()
```

###### Arguments
None.

###### Returns
**[`Font`](https://lovr.org/docs/v0.15.0/Font)** font





## getLineWidth()
#### Returns the current line width
###### Function 
``` lua
g2d.getLineWidth()
```

###### Arguments
None.

###### Returns
**[`number`](#number)** width





## getPointSize()
#### Returns the current point size
###### Function 
``` lua
g2d.getPointSize()
```

###### Arguments
None.

###### Returns
**[`number`](#number)** size





## getShader()
#### Returns the active shader.
###### Function 
``` lua
g2d.getShader()
```

###### Arguments
None.

###### Returns
**[`Shader`](https://lovr.org/docs/v0.15.0/Shader)** shader





## isWireframe()
#### Returns a boolean indicating whether or not wireframe rendering is enabled
###### Function 
``` lua
g2d.isWireframe()
```

###### Arguments
None.

###### Returns
**[`boolean`](#boolean)** state




## DrawMode
- `"fill"` Draw filled shape
- `"line"` Draw outlined shape

## VerticalAlign
- `"top"` Align the top of the text to the origin
- `"middle"` Vertically center the text
- `"bottom"` Align the bottom of the text to the origin

## HorizontalAlign
- `"left"` Left aligned lines of text
- `"center"` Centered aligned lines of text
- `"right"` Right aligned lines of text
