#define HL_NAME(n) openmpt_##n

#include <hl.h>

#ifdef _GUID
#undef _GUID
#endif

#include <libopenmpt/libopenmpt.h>

#include <string>
#include <vector>

static int lastDecodedChannels = 0;
static int lastDecodedSampleRate = 0;
static int lastDecodedSamples = 0;
static std::string lastError;

static void clear_last_error() {
	lastError.clear();
}

static void set_last_error(const char* message) {
	lastError = message ? message : "Unknown error";
}

static void set_last_decoded_format(int channels, int sampleRate, int samples) {
	lastDecodedChannels = channels;
	lastDecodedSampleRate = sampleRate;
	lastDecodedSamples = samples;
}

static bool is_tracker_module_data(const unsigned char* bytes, size_t size) {
	int openmptError = 0;
	const char* openmptErrorMessage = nullptr;
	const int probeResult = openmpt_probe_file_header(
		OPENMPT_PROBE_FILE_HEADER_FLAGS_DEFAULT,
		bytes,
		size,
		static_cast<uint64_t>(size),
		openmpt_log_func_silent,
		nullptr,
		openmpt_error_func_ignore,
		nullptr,
		&openmptError,
		&openmptErrorMessage
	);

	if (openmptErrorMessage != nullptr)
		openmpt_free_string(openmptErrorMessage);

	return probeResult == OPENMPT_PROBE_FILE_HEADER_RESULT_SUCCESS;
}

static openmpt_module* create_module(const unsigned char* bytes, size_t size) {
	int openmptError = 0;
	const char* openmptErrorMessage = nullptr;
	openmpt_module* module = openmpt_module_create_from_memory2(
		bytes,
		size,
		openmpt_log_func_silent,
		nullptr,
		openmpt_error_func_ignore,
		nullptr,
		&openmptError,
		&openmptErrorMessage,
		nullptr
	);

	if (module == nullptr)
		set_last_error(openmptErrorMessage != nullptr ? openmptErrorMessage : "Invalid module");
	else
		clear_last_error();

	if (openmptErrorMessage != nullptr)
		openmpt_free_string(openmptErrorMessage);

	return module;
}

template <typename T>
static vbyte * decode_module(const unsigned char * bytes, int size, int repeatCount, int renderSeconds, bool floatOutput) {
	const int sampleRate = 48000;
	const int channels = 2;
	const size_t chunkFrames = 1024;
	const size_t maxFrames = renderSeconds > 0 ? static_cast<size_t>(sampleRate) * static_cast<size_t>(renderSeconds) : 0;
	openmpt_module * module;

	if (bytes == nullptr || size <= 0) {
		set_last_error("Invalid data");
		return nullptr;
	}

	if (repeatCount != 0 && renderSeconds <= 0) {
		set_last_error("Loop decode duration must be greater than zero");
		return nullptr;
	}

	module = create_module(bytes, static_cast<size_t>(size));
	if (module == nullptr)
		return nullptr;

	openmpt_module_set_repeat_count(module, repeatCount);

	if (floatOutput) {
		float chunk[1024 * 2];
		std::vector<float> pcm;
		if (maxFrames > 0)
			pcm.reserve(maxFrames * channels);

		for (;;) {
			size_t framesToRead = chunkFrames;
			if (maxFrames > 0 && pcm.size() / channels >= maxFrames)
				break;

			if (maxFrames > 0) {
				const size_t remaining = maxFrames - (pcm.size() / channels);
				if (remaining < framesToRead)
					framesToRead = remaining;
			}

			if (framesToRead == 0)
				break;

			const size_t framesRead = openmpt_module_read_interleaved_float_stereo(module, sampleRate, framesToRead, chunk);
			if (framesRead == 0)
				break;

			pcm.insert(pcm.end(), chunk, chunk + (framesRead * channels));
		}

		openmpt_module_destroy(module);

		if (pcm.empty()) {
			set_last_error("No PCM data decoded");
			return nullptr;
		}

		return copy_samples(pcm, channels, sampleRate);
	} else {
		int16_t chunk[1024 * 2];
		std::vector<int16_t> pcm;
		if (maxFrames > 0)
			pcm.reserve(maxFrames * channels);

		for (;;) {
			size_t framesToRead = chunkFrames;
			if (maxFrames > 0 && pcm.size() / channels >= maxFrames)
				break;

			if (maxFrames > 0) {
				const size_t remaining = maxFrames - (pcm.size() / channels);
				if (remaining < framesToRead)
					framesToRead = remaining;
			}

			if (framesToRead == 0)
				break;

			const size_t framesRead = openmpt_module_read_interleaved_stereo(module, sampleRate, framesToRead, chunk);
			if (framesRead == 0)
				break;

			pcm.insert(pcm.end(), chunk, chunk + (framesRead * channels));
		}

		openmpt_module_destroy(module);

		if (pcm.empty()) {
			set_last_error("No PCM data decoded");
			return nullptr;
		}

		return copy_samples(pcm, channels, sampleRate);
	}
}

template <typename T>
static vbyte* copy_samples(const std::vector<T> & samples, int channels, int sampleRate) {
	const int frameCount = static_cast<int>(samples.size() / (channels > 0 ? channels : 1));
	const int byteCount = static_cast<int>(samples.size() * sizeof(T));
	vbyte* result = hl_copy_bytes(reinterpret_cast<const vbyte *>(samples.data()), byteCount);

	if (result == nullptr) {
		set_last_error("Out of memory");
		return nullptr;
	}

	set_last_decoded_format(channels, sampleRate, frameCount);
	clear_last_error();
	return result;
}

HL_PRIM bool HL_NAME(probe_module)(vbyte* bytes, int size) {
	if (bytes == nullptr || size <= 0)
		return false;

	return is_tracker_module_data(reinterpret_cast<const unsigned char *>(bytes), static_cast<size_t>(size));
}

HL_PRIM vbyte* HL_NAME(decode_pcm_float)(vbyte* bytes, int size) {
	return decode_module<float>(reinterpret_cast<const unsigned char *>(bytes), size, 0, 0, true);
}

HL_PRIM vbyte* HL_NAME(decode_pcm_s16)(vbyte* bytes, int size) {
	return decode_module<int16_t>(reinterpret_cast<const unsigned char *>(bytes), size, 0, 0, false);
}

HL_PRIM vbyte* HL_NAME(decode_loop_pcm_float)(vbyte* bytes, int size, int seconds) {
	return decode_module<float>(reinterpret_cast<const unsigned char *>(bytes), size, -1, seconds, true);
}

HL_PRIM vbyte* HL_NAME(decode_loop_pcm_s16)(vbyte* bytes, int size, int seconds) {
	return decode_module<int16_t>(reinterpret_cast<const unsigned char *>(bytes), size, -1, seconds, false);
}

HL_PRIM int HL_NAME(decoded_channels)() {
	return lastDecodedChannels;
}

HL_PRIM int HL_NAME(decoded_sample_rate)() {
	return lastDecodedSampleRate;
}

HL_PRIM int HL_NAME(decoded_samples)() {
	return lastDecodedSamples;
}

HL_PRIM vbyte* HL_NAME(describe_last_error)() {
	return hl_copy_bytes(reinterpret_cast<const vbyte*>(lastError.c_str()), static_cast<int>(lastError.size() + 1));
}

DEFINE_PRIM(_BOOL,	probe_module,			_BYTES	_I32);
DEFINE_PRIM(_BYTES, decode_pcm_float,		_BYTES	_I32);
DEFINE_PRIM(_BYTES, decode_pcm_s16,			_BYTES	_I32);
DEFINE_PRIM(_BYTES, decode_loop_pcm_float,	_BYTES	_I32 _I32);
DEFINE_PRIM(_BYTES, decode_loop_pcm_s16,	_BYTES	_I32 _I32);
DEFINE_PRIM(_I32,	decoded_channels,		_NO_ARG);
DEFINE_PRIM(_I32,	decoded_sample_rate,	_NO_ARG);
DEFINE_PRIM(_I32,	decoded_samples,		_NO_ARG);
DEFINE_PRIM(_BYTES, describe_last_error,	_NO_ARG);
