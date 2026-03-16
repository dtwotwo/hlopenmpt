package openmpt;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
#if heaps
import hxd.res.Config;
#end

class Boot {
	public static function setup() {
		#if (haxe_ver >= 5)
		Context.onAfterInitMacros(() -> apply());
		#else
		apply();
		#end

		return null;
	}

	static function apply() {
		#if heaps
		for (ext in Formats.resourceExtensions)
			Config.addExtension(ext, "hxd.res.Sound");
		#end
		Compiler.addGlobalMetadata("hxd.res.Sound", "@:build(openmpt.Macro.buildSound())", false, true, false);
	}
}
#else
class Boot {}
#end
