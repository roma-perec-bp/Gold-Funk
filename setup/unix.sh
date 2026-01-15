#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git openfl  https://github.com/FunkinCrew/openfl 0475d292861de25960abcbf5d2090f9a4bbab650 --skip-dependencies
haxelib git flixel https://github.com/Psych-Slice/p-slice-1.0-flixel.git 9b1192a23fcfb456123efa14c63c8506ded20e5e --quiet --skip-dependencies
haxelib git flixel-addons https://github.com/FunkinCrew/flixel-addons 6fa30b3f5209146c852c25f3d1003e08898083e2 --skip-dependencies
haxelib install flixel-tools 1.5.1
haxelib git lime https://github.com/FunkinCrew/lime 9d70910a748f9189cc0220276b9d88e341c043bb --skip-dependencies
haxelib install hscript-iris 1.1.3
haxelib install hxWindowColorMode
haxelib install flxgif
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxvlc 2.2.5 --skip-dependencies
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate c61476f4b3a3d225631ab3065e4e925a4b63c076 --quiet --skip-dependencies
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 02bada154b474c2554709b9d12aef0cbf0da3ec9
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio 6409f3c6d1b4c52176813d3ede86c0d34e8af2c1
haxelib git hxcpp https://github.com/FunkinCrew/hxcpp 5932340d095a7eea8635fe4d1355f1c0efd0b3c2 --quiet --skip-dependencies
haxelib git hxcpp-debug-server https://github.com/FunkinCrew/hxcpp-debugger 7459934666a473a4cc4d066ba4a93ef92f1ce94c --quiet --skip-dependencies
haxelib run lime rebuild hxcpp
echo Finished!
