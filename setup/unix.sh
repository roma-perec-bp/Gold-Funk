#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/FunkinCrew/lime 59bd9ed91401cd5cf0198e5305e14f935e2dc0bd  --skip-dependencies
haxelib git openfl  https://github.com/FunkinCrew/openfl 461fe9f4bf5770f0e75f6c463d3e9a0c40b0d56d --skip-dependencies
haxelib git flixel https://github.com/FunkinCrew/flixel 5129a6b7f27e11bb2b2c5c78bc510d95d5fa2142 --skip-dependencies
haxelib git flixel-addons https://github.com/FunkinCrew/flixel-addons 7df068dbecefa40328d60a1849126a8318b3c80e --skip-dependencies
haxelib install flixel-tools 1.5.1
haxelib install hscript-iris 1.1.3
haxelib install hxWindowColorMode
haxelib install flxgif
haxelib install format
haxelib install hxp 1.3.0
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4 --skip-dependencies
haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc 458d07d89aa22a01282c3d79d12e66702fca70d3 --skip-dependencies
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound.git cf4d3d37e309c4594813d7cc06aec5a800cdb090 --skip-dependencies
haxelib git flixel-animate https://github.com/FunkinCrew/flixel-animate 5d8c335457e69a154bcd06392990a377b9c6f806 --quiet --skip-dependencies
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 9b22f76445eb4dc67fae411841c1644f7b4af044
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio 6409f3c6d1b4c52176813d3ede86c0d34e8af2c1
haxelib git thx.core https://github.com/fponticelli/thx.core 2bf2b992e06159510f595554e6b952e47922f128
haxelib git thx.semver https://github.com/FunkinCrew/thx.semver d7ed6011c506130702ef4953a9ec8ecc86b32210
haxelib git hxcpp https://github.com/FunkinCrew/hxcpp d5bda40ac13f2823fe1bdcb5476e0eb027f1e7e9 --quiet --skip-dependencies
haxelib git hxcpp-debug-server https://github.com/FunkinCrew/hxcpp-debugger 7459934666a473a4cc4d066ba4a93ef92f1ce94c --quiet --skip-dependencies
haxelib run lime rebuild hxcpp
haxelib run lime rebuild windows -clean 
echo Finished!
