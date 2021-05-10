# lovr-g2d
A 2d graphics rendering library for [LÖVR](https://lovr.org)

# Usage
```lua
g2d = require("lovr-g2d").init()

function lovr.load()
    g2d.setLineWidth(1)
    g2d.setPointSize(5)
end

function lovr.draw()
  -- start 2d graphics
  g2d.set()
    g2d.setColor(1,1,0)
    g2d.rectangle("fill", 100,100, 50,50)

    g2d.setColor(0.6,0,0.8)
    g2d.rectangle("fill", 120,120, 50,50)

    g2d.setColor(1,1,1)
    g2d.rectangle("line", 140,140, 50,50)

    g2d.setColor(1,1,1)
		
    g2d.setColor(1,1,1)
    g2d.line(285,75, 300,60, 315,75)
    g2d.setColor(1,0,0)
    g2d.points(285,75, 300,60, 315,75)
  g2d.unset()

  lovr.graphics.print(lovr.graphics.getStats().drawcalls, 0,0, -20)
  lovr.graphics.print(lovr.timer.getFPS(), 18,1, -20)
end
```

# TODO
- Shaders support
- Stacks and coordinate system transform functions
  - push, pop, origin
  - translate, rotate, scale
- Quad, spritebatches and autobatching [most likely based on this](https://github.com/rxi/autobatch)
- Shape rendering functions
  - arc, circle, line, points, ellipse, polygon, rectangle
  - line join styles, anti-aliasing for lines
- 2d print function
- stencil and blend mode support(?)
