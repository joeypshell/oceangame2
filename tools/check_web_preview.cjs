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
const mobileScreenshotPath = process.env.WEB_PREVIEW_MOBILE_SCREENSHOT || "";
const primaryViewport = { width: 1280, height: 720 };
const wideViewport = { width: 1920, height: 1080 };
const mobileViewport = { width: 844, height: 390 };
const framingThreshold = 18;
const canvasPositionTolerance = 1;

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
	await checkBuildMetadata();

	const browser = await chromium.launch({ args: ["--no-sandbox"] });
	try {
		const primary = await inspectPreview(browser, targetUrl, primaryViewport, screenshotPath);
		const wide = await inspectPreview(browser, targetUrl, wideViewport, "");
		const mobile = await inspectPreview(
			browser,
			targetUrl,
			mobileViewport,
			mobileScreenshotPath,
			{ deviceScaleFactor: 3, hasTouch: true, isMobile: true }
		);
		const framingDiff = compareSignatures(primary.signature, wide.signature);

		fs.mkdirSync(path.dirname(screenshotPath), { recursive: true });
		const allMessages = primary.messages.concat(wide.messages, mobile.messages);
		const allFailedRequests = primary.failedRequests.concat(wide.failedRequests, mobile.failedRequests);
		const failingMessages = allMessages.filter((message) =>
			failurePatterns.some((pattern) => pattern.test(message.text))
		);

		console.log(`Checked ${targetUrl}`);
		console.log(
			`Canvas ${primary.canvasSize.width}x${primary.canvasSize.height} (${primary.canvasSize.clientWidth}x${primary.canvasSize.clientHeight} CSS)`
		);
		console.log(
			`Wide canvas ${wide.canvasSize.width}x${wide.canvasSize.height} (${wide.canvasSize.clientWidth}x${wide.canvasSize.clientHeight} CSS)`
		);
		console.log(
			`Mobile canvas ${mobile.canvasSize.width}x${mobile.canvasSize.height} (${mobile.canvasRect.width}x${mobile.canvasRect.height} CSS at ${mobile.canvasRect.left},${mobile.canvasRect.top})`
		);
		console.log(
			`Mobile visual viewport ${mobile.viewportMetrics.visualWidth}x${mobile.viewportMetrics.visualHeight} offset ${mobile.viewportMetrics.visualLeft},${mobile.viewportMetrics.visualTop}`
		);
		console.log(`Framing thumbnail mean difference ${framingDiff.toFixed(2)} (max ${framingThreshold})`);

		if (allMessages.length > 0) {
			console.log("Console output:");
			for (const message of allMessages) {
				console.log(`[${message.type}] ${message.text}`);
			}
		}

		if (allFailedRequests.length > 0) {
			console.log("Failed requests:");
			for (const request of allFailedRequests) {
				console.log(request);
			}
		}

		if (primary.canvasSize.width <= 0 || primary.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize.");
		}
		if (wide.canvasSize.width <= 0 || wide.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize at the wide framing check size.");
		}
		if (mobile.canvasSize.width <= 0 || mobile.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize at the mobile framing check size.");
		}
		if (
			Math.abs(mobile.canvasRect.left) > canvasPositionTolerance ||
			Math.abs(mobile.canvasRect.top) > canvasPositionTolerance
		) {
			throw new Error(
				`Mobile canvas is not top anchored: left=${mobile.canvasRect.left} top=${mobile.canvasRect.top}.`
			);
		}
		if (
			mobile.canvasRect.width + canvasPositionTolerance < mobile.viewportMetrics.visualWidth ||
			mobile.canvasRect.height + canvasPositionTolerance < mobile.viewportMetrics.visualHeight
		) {
			throw new Error(
				`Mobile canvas does not cover the visual viewport: canvas=${mobile.canvasRect.width}x${mobile.canvasRect.height} viewport=${mobile.viewportMetrics.visualWidth}x${mobile.viewportMetrics.visualHeight}.`
			);
		}
		if (framingDiff > framingThreshold) {
			throw new Error(
				`Web preview framing changed across viewport sizes; thumbnail mean difference ${framingDiff.toFixed(2)} exceeds ${framingThreshold}.`
			);
		}
		if (allFailedRequests.length > 0) {
			throw new Error("Web preview had failed network requests.");
		}
		if (failingMessages.length > 0) {
			throw new Error("Web preview emitted Godot/browser errors.");
		}
	} finally {
		await browser.close();
	}
}

async function inspectPreview(browser, url, viewport, outputPath, pageOptions = {}) {
	const messages = [];
	const failedRequests = [];
	const page = await browser.newPage({ viewport, ...pageOptions });
	try {
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

		await page.goto(url, { waitUntil: "networkidle", timeout: 60000 });
		await page.waitForSelector("canvas", { timeout: 30000 });
		await page.waitForTimeout(5000);
		if (outputPath) {
			fs.mkdirSync(path.dirname(outputPath), { recursive: true });
			await page.screenshot({ path: outputPath });
		}

		const canvasSize = await page.locator("canvas").evaluate((canvas) => ({
			width: canvas.width,
			height: canvas.height,
			clientWidth: canvas.clientWidth,
			clientHeight: canvas.clientHeight,
		}));
		const canvasRect = await page.locator("canvas").evaluate((canvas) => {
			const rect = canvas.getBoundingClientRect();
			return {
				left: rect.left,
				top: rect.top,
				width: rect.width,
				height: rect.height,
			};
		});
		const viewportMetrics = await page.evaluate(() => ({
			innerWidth: window.innerWidth,
			innerHeight: window.innerHeight,
			visualWidth: window.visualViewport?.width || window.innerWidth,
			visualHeight: window.visualViewport?.height || window.innerHeight,
			visualLeft: window.visualViewport?.offsetLeft || 0,
			visualTop: window.visualViewport?.offsetTop || 0,
		}));
		const signature = await page.locator("canvas").evaluate((canvas) => {
			const sampleWidth = 64;
			const sampleHeight = 36;
			const scratch = document.createElement("canvas");
			scratch.width = sampleWidth;
			scratch.height = sampleHeight;
			const context = scratch.getContext("2d", { willReadFrequently: true });
			context.drawImage(canvas, 0, 0, sampleWidth, sampleHeight);
			return Array.from(context.getImageData(0, 0, sampleWidth, sampleHeight).data);
		});

		return { canvasRect, canvasSize, failedRequests, messages, signature, viewportMetrics };
	} finally {
		await page.close();
	}
}

function compareSignatures(left, right) {
	if (left.length !== right.length || left.length === 0) {
		throw new Error("Unable to compare web preview framing signatures.");
	}
	let total = 0;
	for (let index = 0; index < left.length; index += 1) {
		total += Math.abs(left[index] - right[index]);
	}
	return total / left.length;
}

main().catch((error) => {
	console.error(error.message || error);
	process.exit(1);
});
