Layout Example
==============

An example Stringray project which makes use of the
[Layout](https://github.com/randrew/layout) library for calculating the
rectangles of 2D UI elements.

![](https://raw.githubusercontent.com/wiki/randrew/layoutexample/ui_screenshot_1.png)

![](https://raw.githubusercontent.com/wiki/randrew/layoutexample/ui_anim_small.gif)

Usage
-----

Open the project in Stingray, and then edit the `script/lua/project.lua` file.
You will need to manually enter the absolute path to the Stingray project as a
string literal in order for it to be able to find the layout.dll Lua module.
Find this line near the top of the file:

```
local projectdir = 'C:\\Users\\myname\\Documents\\Stingray\\layoutexample\\'
```

And edit it to be the path to the project on your local disk.

There doesn't currently appear to be a way to handle this automatically in
Stingray.

Once you've done that, you can hit play to see the interface laid out and
animated. To see how it was made, look at the file
`ui/layout_test.s2d/ui_layout_test.lua`.

Notes
-----

The .dll file is built for 64-bit. It's also possible to build it for 32-bit,
and to configure Layout to use either integers or floating point for 2D
coordinates -- take a look at the [project page for
Layout](https://github.com/randrew/layout) for more information.

The API should not be considered stable. I'm still experimenting with the
design. However, the library is small and simple enough that you should be able
to fork it yourself and easily make any changes you need.
