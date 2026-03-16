package openmpt;

enum abstract TrackerFormat(String) from String to String {
	final MOD = "mod";
	final XM = "xm";
	final IT = "it";
	final S3M = "s3m";

	public static final values:Array<TrackerFormat> = [MOD, XM, IT, S3M];
	public static final resourceExtensions:Array<TrackerFormat> = values;

	public static function fromExtension(extension:String):Null<TrackerFormat> {
		final normalized = extension.toLowerCase();
		for (format in values)
			if (format == normalized)
				return format;

		return null;
	}

	public static inline function fromPath(path:String):Null<TrackerFormat> {
		return fromExtension(haxe.io.Path.extension(path));
	}

	public static inline function hasExtension(extension:String):Bool {
		return fromExtension(extension) != null;
	}

	public static inline function isTrackerPath(path:String):Bool {
		return fromPath(path) != null;
	}
}
