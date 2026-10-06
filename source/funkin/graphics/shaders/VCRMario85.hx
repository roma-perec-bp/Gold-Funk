package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

class VCRMario85 extends FlxShader // https://www.shadertoy.com/view/ldjGzV and https://www.shadertoy.com/view/Ms23DR and https://www.shadertoy.com/view/MsXGD4 and https://www.shadertoy.com/view/Xtccz4
{
	@glFragmentSource('
#pragma header

uniform float time;

vec3 mod289(vec3 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec2 mod289(vec2 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec3 permute(vec3 x) {return mod289(((x * 34.0) + 1.0) * x);}

float snoise(vec2 v) {
  const vec4 c = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
  vec2 x0 = v - floor(v + dot(v, c.yy)) + dot(floor(v + dot(v, c.yy)), c.xx);
  vec4 x12 = x0.xyxy + c.xxzz;
  x12.xy -= (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
  vec3 x = 2.0 * fract(permute(permute(mod289(floor(v + dot(v, c.yy))).y + vec3(0.0, ((x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0)).y, 1.0)) + mod289(floor(v + dot(v, c.yy))).x + vec3(0.0, ((x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0)).x, 1.0)) * c.www) - 1.0;
  return 130.0 * dot((m * m * m * m) * (1.79284291400159 - 0.85373472095314 * (floor(x + 0.5) * floor(x + 0.5) + (abs(x) - 0.5) * (abs(x) - 0.5))), vec3(floor(x + 0.5).x * x0.x + (abs(x) - 0.5).x * x0.y, floor(x + 0.5).y * x12.x + (abs(x) - 0.5).y * x12.y, floor(x + 0.5).z * x12.z + (abs(x) - 0.5).z * x12.w));
}

vec2 curve(vec2 uv) {
  uv = ((uv - 0.5) * 2.0) * 1.1;
  uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
  uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
  uv = ((uv / 2.0) + 0.5) * 0.92 + 0.04;
  return uv;
}

#define PI 3.1415926535897932384626433832795 // better than just 3.1415, moreso for accuracy though
float vignette(vec2 uv) {
  uv = (uv - 0.5) * 0.98;
  return clamp(pow(cos(uv.x * PI), 2.5) * pow(cos(uv.y * PI), 2.5) * 100.0, 0.0, 1.0);
}

void main() {
  vec2 uv = openfl_TextureCoordv;
  vec2 logic = curve(vec2(uv.x + (snoise(vec2(time * 15.0, uv.y * 80.0)) * 0.0005 + snoise(vec2(time * 1.0, uv.y * 25.0)) * 0.001), uv.y));
  vec4 texColor = flixel_texture2D(bitmap, logic);
	texColor.r = flixel_texture2D(bitmap, logic - vec2(0.0025, 0.0)).r;
	texColor.b = flixel_texture2D(bitmap, logic + vec2(0.0025, 0.0)).b;
  texColor.rgb -= sin(uv.y * 800.0) * 0.04;
  if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {discard;}
	gl_FragColor = vec4(texColor.rgb * vignette(curve(uv)), texColor.a);
}
  ')
	public function new()
	{
		super();
		this.time.value = [0];
	}

	public function update(elapsed:Float)
	{
		this.time.value[0] += elapsed;
	}
}