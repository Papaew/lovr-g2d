# lovr-g2d
A 2d graphics rendering library for [LÖVR](https://lovr.org)

# Usage
![alt text](https://github.com/Papaew/lovr-g2d/blob/main/test.png?raw=true)
```lua
g2d = require("lovr-g2d").init()

local image = g.newTexture("/lovr-ico.png")
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
#### The entry point into drawing 2D graphics. Can be called several times per frame, but must be closed with [g2d.unset()](#unset)
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
#### Exit point from drawing 2D graphics. Must be called after [g2d.set()](#set) for correct rendering
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
