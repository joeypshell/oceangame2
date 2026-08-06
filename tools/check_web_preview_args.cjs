const defaultReviewCheckpoint = "living_expedition_01_start";

function parseArgs(argv) {
	const parsed = {
		targetUrl: "http://127.0.0.1:8060/",
		expectedSha: process.env.WEB_PREVIEW_EXPECTED_SHA || "",
		checkpoint: process.env.WEB_PREVIEW_CHECKPOINT || defaultReviewCheckpoint,
	};
	let targetSet = false;
	for (let index = 0; index < argv.length; index += 1) {
		const value = argv[index];
		if (value === "--expected-sha" || value === "--checkpoint") {
			index += 1;
			if (index >= argv.length) {
				throw new Error(`${value} requires a value.`);
			}
			const key = value === "--expected-sha" ? "expectedSha" : "checkpoint";
			parsed[key] = argv[index];
		} else if (value.startsWith("--expected-sha=")) {
			parsed.expectedSha = value.slice("--expected-sha=".length);
		} else if (value.startsWith("--checkpoint=")) {
			parsed.checkpoint = value.slice("--checkpoint=".length);
		} else if (!targetSet) {
			parsed.targetUrl = value;
			targetSet = true;
		} else {
			throw new Error(`Unexpected argument: ${value}`);
		}
	}
	parsed.expectedSha = parsed.expectedSha.trim().toLowerCase();
	parsed.checkpoint = parsed.checkpoint.trim().toLowerCase();
	if (!/^[a-z0-9_]+$/.test(parsed.checkpoint)) {
		throw new Error("--checkpoint must use lower_snake_case.");
	}
	return parsed;
}

module.exports = { parseArgs };
