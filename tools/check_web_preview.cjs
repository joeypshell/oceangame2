#!/usr/bin/env node

const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

function parseArgs(argv) {
	const parsed = {
		targetUrl: "http://127.0.0.1:8060/",
		expectedSha: process.env.WEB_PREVIEW_EXPECTED_SHA || "",
	};
	let targetSet = false;
	for (let index = 0; index < argv.length; index += 1) {
		const value = argv[index];
		if (value === "--expected-sha") {
			index += 1;
			if (index >= argv.length) {
				throw new Error("--expected-sha requires a value.");
			}
			parsed.expectedSha = argv[index];
		} else if (value.startsWith("--expected-sha=")) {
			parsed.expectedSha = value.slice("--expected-sha=".length);
		} else if (!targetSet) {
			parsed.targetUrl = value;
			targetSet = true;
		} else {
			throw new Error(`Unexpected argument: ${value}`);
		}
	}
	parsed.expectedSha = parsed.expectedSha.trim().toLowerCase();
	return parsed;
}

const { targetUrl, expectedSha } = parseArgs(process.argv.slice(2));
const screenshotPath = process.env.WEB_PREVIEW_SCREENSHOT || "exports/web-preview-check.png";

const failurePatterns = [
	/SCRIPT ERROR/i,
	/\bERROR:/,
	/Unable to open terrain art texture/,
	/Unable to open texture asset/,
	/Unable to decode texture asset/,
	/Unable to create cave TileSet/,
	/Failed loading resource/i,
];

async function checkBuildMetadata() {
	if (!expectedSha) {
		return;
	}
	if (expectedSha.length < 7) {
		throw new Error("--expected-sha must be at least 7 characters.");
	}

	const metadataUrl = new URL("build_info.json", targetUrl).toString();
	const response = await fetch(metadataUrl, { cache: "no-store" });
	if (!response.ok) {
		throw new Error(`Unable to load build metadata at ${metadataUrl}: HTTP ${response.status}`);
	}

	const metadata = await response.json();
	const actualSha = String(metadata.git_sha || "").toLowerCase();
	const actualVersion = String(metadata.version || "").toLowerCase();
	console.log(`Build metadata ${metadataUrl}`);
	console.log(`Build git_sha ${actualSha || "(missing)"}`);
	console.log(`Build version ${actualVersion || "(missing)"}`);

	if (!actualSha) {
		throw new Error("Build metadata is missing git_sha.");
	}
	if (!actualSha.startsWith(expectedSha) && actualVersion !== expectedSha) {
		throw new Error(`Build metadata git_sha ${actualSha} does not match expected ${expectedSha}.`);
	}
}

async function main() {
	const messages = [];
	const failedRequests = [];

	await checkBuildMetadata();

	const browser = await chromium.launch({ args: ["--no-sandbox"] });
	try {
		const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
		page.on("console", (message) => {
			messages.push({
				type: message.type(),
				text: message.text(),
			});
		});
		page.on("pageerror", (error) => {
			messages.push({
				type: "pageerror",
				text: error.stack || error.message || String(error),
			});
		});
		page.on("requestfailed", (request) => {
			failedRequests.push(`${request.method()} ${request.url()} ${request.failure()?.errorText || ""}`);
		});

		await page.goto(targetUrl, { waitUntil: "networkidle", timeout: 60000 });
		await page.waitForSelector("canvas", { timeout: 30000 });
		await page.waitForTimeout(5000);
		fs.mkdirSync(path.dirname(screenshotPath), { recursive: true });
		await page.screenshot({ path: screenshotPath });

		const canvasSize = await page.locator("canvas").evaluate((canvas) => ({
			width: canvas.width,
			height: canvas.height,
			clientWidth: canvas.clientWidth,
			clientHeight: canvas.clientHeight,
		}));

		const failingMessages = messages.filter((message) =>
			failurePatterns.some((pattern) => pattern.test(message.text))
		);

		console.log(`Checked ${targetUrl}`);
		console.log(
			`Canvas ${canvasSize.width}x${canvasSize.height} (${canvasSize.clientWidth}x${canvasSize.clientHeight} CSS)`
		);

		if (messages.length > 0) {
			console.log("Console output:");
			for (const message of messages) {
				console.log(`[${message.type}] ${message.text}`);
			}
		}

		if (failedRequests.length > 0) {
			console.log("Failed requests:");
			for (const request of failedRequests) {
				console.log(request);
			}
		}

		if (canvasSize.width <= 0 || canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize.");
		}
		if (failedRequests.length > 0) {
			throw new Error("Web preview had failed network requests.");
		}
		if (failingMessages.length > 0) {
			throw new Error("Web preview emitted Godot/browser errors.");
		}
	} finally {
		await browser.close();
	}
}

main().catch((error) => {
	console.error(error.message || error);
	process.exit(1);
});
