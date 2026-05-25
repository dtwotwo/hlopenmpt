package openmpt;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
#if heaps
import hxd.res.Config;
#end

/**
	Macro bootstrap for Heaps tracker integration.

	Call `openmpt.Boot.setup()` from your build macros to register tracker
	resources as `hxd.res.Sound` and install the Heaps sound patch.
**/
class Boot {
	/**
		Installs the Heaps resource and macro hooks for tracker support.
	**/
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
		for (ext in TrackerFormat.resourceExtensions)
			Config.addExtension(ext, "hxd.res.Sound");
		#end
		Compiler.addMetadata("@:build(openmpt.Macro.buildSound())", "hxd.res.Sound");
	}
}
#else

/**
	Runtime placeholder for non-macro builds.
**/
class Boot {}
#end
