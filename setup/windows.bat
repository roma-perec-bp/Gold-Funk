@echo off
color 0a
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git lime https://github.com/FunkinCrew/lime 8888c14061aa55243da7fb6bdab21636bb32b248  --skip-dependencies
haxelib git openfl  https://github.com/FunkinCrew/openfl 05b4d5162741c823dab7b97899e38db09e54d775 --skip-dependencies
haxelib git flixel https://github.com/FunkinCrew/flixel f21eaef2c3e470dcee45798ec4402114829f8455 --skip-dependencies
haxelib git flixel-addons https://github.com/FunkinCrew/flixel-addons e038c227c0b48bd23a3ffa0f554e59b9c4c4bf2f --skip-dependencies
haxelib install flixel-tools 1.5.1
haxelib install hscript-iris 1.1.3
haxelib install hxWindowColorMode
haxelib install flxgif
haxelib install format
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4 --skip-dependencies
haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc 5ceac764bd21625d1e9d92ea02f9a0d110c6a58c --skip-dependencies
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound.git ba1274145d5636d1aad53c7188c525bd39a99ee2 --skip-dependencies
haxelib git flixel-animate https://github.com/FunkinCrew/flixel-animate 5d8c335457e69a154bcd06392990a377b9c6f806 --quiet --skip-dependencies
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis f99adae2e1aa18ef1b987ca97e49d1b3c6ee9b9f
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio 6409f3c6d1b4c52176813d3ede86c0d34e8af2c1
haxelib git thx.core https://github.com/fponticelli/thx.core 2bf2b992e06159510f595554e6b952e47922f128
haxelib git thx.semver https://github.com/FunkinCrew/thx.semver b91cf5cfee6ebe43b60f8acea4257f07af176b99
haxelib git hxcpp https://github.com/FunkinCrew/hxcpp a8b5f73b217132cdb595e515bb10332959a1ed39 --quiet --skip-dependencies
haxelib git hxcpp-debug-server https://github.com/FunkinCrew/hxcpp-debugger 7459934666a473a4cc4d066ba4a93ef92f1ce94c --quiet --skip-dependencies
haxelib run lime rebuild hxcpp
haxelib run lime rebuild windows -clean 
echo Finished!
pause
