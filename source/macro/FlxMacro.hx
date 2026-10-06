package macro;

#if macro

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

using Lambda;

class FlxMacro
{
  /**
   * A macro to be called targeting the `FlxBasic` class.
   * @return An array of fields that the class contains.
   */
  public static macro function buildFlxBasic():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The FlxBasic class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxClass.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    // haxe.macro.Context.info('[INFO] ${cls.name}: Adding zIndex attribute...', pos);
    var hasZIndex = false;

    for (f in fields)
    {
      if (f.name == "zIndex")
      {
        hasZIndex = true;
        break;
      }
    }

    if (!hasZIndex)
    {
      // Here, we add the zIndex attribute to all FlxBasic objects.
      // This has no functional code tied to it, but it can be used as a target value
      // for the FlxTypedGroup.sort method, to rearrange the objects in the scene.
      fields.push({
        name: "zIndex", // Field name.
        access: [haxe.macro.Expr.Access.APublic], // Access level
        kind: haxe.macro.Expr.FieldType.FVar(macro :Int, macro $v{0}), // Variable type and default value
        pos: pos, // The field's position in code.
      });
    }

    return fields;
  }

  /**
   * A macro to be called targeting the `FlxSprite` class.
   * @return An array of fields that the class contains.
   */
  public static macro function buildFlxSprite():Array<haxe.macro.Expr.Field>
  {
    var pos:haxe.macro.Expr.Position = haxe.macro.Context.currentPos();
    // The FlxSprite class. We can add new properties to this class.
    var cls:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
    // The fields of the FlxSprite.
    var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

    var fieldsToAdd = [];
    fieldsToAdd.push({name: "localX", kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{0})});
    fieldsToAdd.push({name: "localY", kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{0})});
    fieldsToAdd.push({name: "localAngle", kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{0})});
    fieldsToAdd.push({name: "localScale", kind: haxe.macro.Expr.FieldType.FVar(macro :flixel.math.FlxPoint, macro new flixel.math.FlxPoint(1, 1))});
    fieldsToAdd.push({name: "localAlpha", kind: haxe.macro.Expr.FieldType.FVar(macro :Float, macro $v{1})});
    fieldsToAdd.push({name: "localVisible", kind: haxe.macro.Expr.FieldType.FVar(macro :Bool, macro $v{true})});

    var alreadyOwnedFields = [];

    for (f in fields)
    {
      for (a in fieldsToAdd)
      {
        if (f.name == a.name) alreadyOwnedFields.push(a.name);
      }
    }

    for (f in fieldsToAdd)
    {
      if (alreadyOwnedFields.contains(f.name)) continue;

      fields.push({
        name: f.name, // Field name.
        access: [haxe.macro.Expr.Access.APublic], // Access level
        kind: f.kind, // Variable type and default value
        pos: pos, // The field's position in code.
      });
    }

    return fields;
  }

  public static macro function buildFlxCamera():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();
		
		for (field in fields)
		{
			switch (field.kind)
			{
				default:
				case FFun(fun):
					if (field.name == '__get__rotated__matrix')
					{
						// removes the line that translates the sdcroll to the camera poistion grrrrr
						
						fun.expr = macro {
							__angleMatrix.identity();
							__angleMatrix.translate(-width * 0.5, -height * 0.5);
							if (shakeMatrixFix)
								__angleMatrix.translate(_fxShakeXOffset, _fxShakeYOffset);
							__angleMatrix.scale(scaleX, scaleY);
							if (!(_sinScrollAngle == 0 && _sinScrollAngle == 1))
								__angleMatrix.rotateWithTrig(_cosScrollAngle, _sinScrollAngle);
							__angleMatrix.translate(width * 0.5, height * 0.5);
							__angleMatrix.scale(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);
							return __angleMatrix;
						};
					}
					else if (field.name == 'fill')
					{
						fun.expr = macro {
							if (!FlxG.renderBlit)
							{
								final bounds = __get__bounds();
								final targetGraphics:Graphics = (graphics == null) ? canvas.graphics : graphics;
								
								targetGraphics.overrideBlendMode(null);
								targetGraphics.beginFill(Color, FxAlpha);
								targetGraphics.drawRect(bounds.x, bounds.y, Math.ceil(bounds.width), Math.ceil(bounds.height));
								targetGraphics.endFill();
							}
							else
							{
								if (BlendAlpha)
								{
									_fill.fillRect(_flashRect, Color);
									buffer.copyPixels(_fill, _flashRect, _flashPoint, null, null, BlendAlpha);
								}
								else
								{
									buffer.fillRect(_flashRect, Color);
								}
							}
						}
					}
			}
		}
		
		return fields;
	}
}
#end