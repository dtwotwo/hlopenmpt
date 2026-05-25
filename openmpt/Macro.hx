package openmpt;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;

using Lambda;

/**
	Build macro that extends `hxd.res.Sound` with tracker-aware behavior.

	It teaches Heaps sound resources to recognize module files and decode
	them through `hxd.snd.OpenMPTData`.
**/
class Macro {
	/**
		Patches `hxd.res.Sound` during compilation.
	**/
	public static macro function buildSound():Array<Field> {
		final fields = Context.getBuildFields();

		if (!fields.exists(f -> f.name == "isTrackerPath")) {
			fields.push({
				name: "isTrackerPath",
				access: [APrivate, AStatic],
				kind: FFun({
					args: [{name: "path", type: macro :String}],
					ret: macro :Bool,
					expr: macro {
						return openmpt.TrackerFormat.isTrackerPath(path);
					}
				}),
				pos: Context.currentPos()
			});
		}

		final getDataField = fields.find(f -> f.name == "getData");
		if (getDataField != null) {
			switch getDataField.kind {
				case FFun(fn):
					final originalExpr = fn.expr;
					fn.expr = macro {
						if (data == null) {
							if (isTrackerPath(entry.path)) {
								final bytes = entry.getBytes();
								if (openmpt.OpenMPT.probeModule(bytes))
									data = new hxd.snd.OpenMPTData(bytes);
							}
						}

						if (data != null)
							return data;

						return $originalExpr;
					};
				default:
			}
		}

		return fields;
	}
}
