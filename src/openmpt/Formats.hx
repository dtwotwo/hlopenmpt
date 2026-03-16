package openmpt;

class Formats {
	public static final resourceExtensions = ["mod", "xm", "it", "s3m"];

	public static function isTrackerPath(path:String):Bool {
		final lower = path.toLowerCase();
		for (ext in resourceExtensions)
			if (StringTools.endsWith(lower, '.$ext'))
				return true;

		return false;
	}
}
