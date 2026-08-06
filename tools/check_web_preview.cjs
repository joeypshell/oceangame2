#!/usr/bin/env node

const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");
const { parseArgs } = require("./check_web_preview_args.cjs");

const { targetUrl, expectedSha, checkpoint } = parseArgs(process.argv.slice(2));
const screenshotPath = process.env.WEB_PREVIEW_SCREENSHOT || "exports/web-preview-check.png";
const mobileScreenshotPath = process.env.WEB_PREVIEW_MOBILE_SCREENSHOT || "";
const primaryViewport = { width: 1280, height: 720 };
const wideViewport = { width: 1920, height: 1080 };
const mobileViewport = { width: 844, height: 390 };
const framingThreshold = 18;
const canvasPositionTolerance = 1;
const mobileTouchThreshold = 2;
const logicalGameSize = { width: 1280, height: 720 };

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
		const freshReviewUrl = buildFreshReviewUrl(targetUrl);
		const freshReview = await inspectPreview(browser, freshReviewUrl, primaryViewport, "");
		const checkpointReviewUrl = buildCheckpointReviewUrl(targetUrl);
		const checkpointReview = await inspectPreview(browser, checkpointReviewUrl, primaryViewport, "");
		const checkpointMobile = await inspectPreview(
			browser,
			checkpointReviewUrl,
			mobileViewport,
			"",
			{ deviceScaleFactor: 3, hasTouch: true, isMobile: true },
			true
		);
		const referenceSliceUrl = buildReferenceSliceReviewUrl(targetUrl);
		const referenceDesktop = await inspectPreview(browser, referenceSliceUrl, primaryViewport, "");
		const referenceMobile = await inspectPreview(
			browser,
			referenceSliceUrl,
			mobileViewport,
			"",
			{ deviceScaleFactor: 3, hasTouch: true, isMobile: true }
		);
		const mobile = await inspectPreview(
			browser,
			targetUrl,
			mobileViewport,
			mobileScreenshotPath,
			{ deviceScaleFactor: 3, hasTouch: true, isMobile: true },
			true
		);
		const framingDiff = compareSignatures(primary.signature, wide.signature);

		fs.mkdirSync(path.dirname(screenshotPath), { recursive: true });
		const allMessages = primary.messages.concat(
			wide.messages,
			freshReview.messages,
			checkpointReview.messages,
			checkpointMobile.messages,
			referenceDesktop.messages,
			referenceMobile.messages,
			mobile.messages
		);
		const allFailedRequests = primary.failedRequests.concat(
			wide.failedRequests,
			freshReview.failedRequests,
			checkpointReview.failedRequests,
			checkpointMobile.failedRequests,
			referenceDesktop.failedRequests,
			referenceMobile.failedRequests,
			mobile.failedRequests
		);
		const failingMessages = allMessages.filter((message) =>
			failurePatterns.some((pattern) => pattern.test(message.text))
		);
		const freshReviewMarker = freshReview.messages.find((message) =>
			message.text.includes("Fresh review profile active: persistence=false propulsion_fins=false.")
		);
		const checkpointMarker = checkpointReview.messages.find((message) =>
			message.text.includes(`Review checkpoint active: id=${checkpoint} persistence=false propulsion_fins=true.`)
		);
		const checkpointMobileMarker = checkpointMobile.messages.find((message) =>
			message.text.includes(`Review checkpoint active: id=${checkpoint} persistence=false propulsion_fins=true.`)
		);
		const defaultMapMarker = primary.messages.find((message) =>
			message.text.includes("Web map active: map=production_level_01 review=false.")
		);
		const freshReviewMapMarker = freshReview.messages.find((message) =>
			message.text.includes("Web map active: map=production_level_01 review=true.")
		);
		const checkpointMapMarker = checkpointReview.messages.find((message) =>
			message.text.includes("Web map active: map=production_level_01 review=true.")
		);
		const checkpointMobileMapMarker = checkpointMobile.messages.find((message) =>
			message.text.includes("Web map active: map=production_level_01 review=true.")
		);
		const referenceDesktopMarker = referenceDesktop.messages.find((message) =>
			message.text.includes("Web map active: map=production_slice_01 review=true.")
		);
		const referenceMobileMarker = referenceMobile.messages.find((message) =>
			message.text.includes("Web map active: map=production_slice_01 review=true.")
		);
		const referenceFreshMarker = referenceDesktop.messages.find((message) =>
			message.text.includes("Fresh review profile active: persistence=false propulsion_fins=false.")
		);

		console.log(`Checked ${targetUrl}`);
		console.log(`Fresh-profile review ${freshReviewUrl}`);
		console.log(`Checkpoint review ${checkpointReviewUrl}`);
		console.log(
			`Checkpoint mobile canvas ${checkpointMobile.canvasSize.width}x${checkpointMobile.canvasSize.height} (${checkpointMobile.canvasRect.width}x${checkpointMobile.canvasRect.height} CSS at ${checkpointMobile.canvasRect.left},${checkpointMobile.canvasRect.top})`
		);
		console.log(
			`Checkpoint mobile touch alignment ${Object.entries(checkpointMobile.touchDiffs)
				.map(([name, difference]) => `${name}=${difference.toFixed(2)}`)
				.join(" ")} (min ${mobileTouchThreshold})`
		);
		console.log(`Reference slice review ${referenceSliceUrl}`);
		console.log(
			`Canvas ${primary.canvasSize.width}x${primary.canvasSize.height} (${primary.canvasSize.clientWidth}x${primary.canvasSize.clientHeight} CSS)`
		);
		console.log(
			`Wide canvas ${wide.canvasSize.width}x${wide.canvasSize.height} (${wide.canvasSize.clientWidth}x${wide.canvasSize.clientHeight} CSS)`
		);
		console.log(
			`Mobile canvas ${mobile.canvasSize.width}x${mobile.canvasSize.height} (${mobile.canvasRect.width}x${mobile.canvasRect.height} CSS at ${mobile.canvasRect.left},${mobile.canvasRect.top}; position ${mobile.canvasSize.cssPosition})`
		);
		console.log(
			`Mobile visual viewport ${mobile.viewportMetrics.visualWidth}x${mobile.viewportMetrics.visualHeight} offset ${mobile.viewportMetrics.visualLeft},${mobile.viewportMetrics.visualTop}`
		);
		console.log(
			`Mobile touch alignment ${Object.entries(mobile.touchDiffs)
				.map(([name, difference]) => `${name}=${difference.toFixed(2)}`)
				.join(" ")} (min ${mobileTouchThreshold})`
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
		if (freshReview.canvasSize.width <= 0 || freshReview.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize in fresh-profile review mode.");
		}
		if (checkpointReview.canvasSize.width <= 0 || checkpointReview.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize in checkpoint review mode.");
		}
		if (checkpointMobile.canvasSize.width <= 0 || checkpointMobile.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize in mobile checkpoint review mode.");
		}
		if (!freshReviewMarker) {
			throw new Error("Fresh-profile review URL did not report isolated state with propulsion fins unowned.");
		}
		if (!checkpointMarker || !checkpointMobileMarker || !checkpointMapMarker || !checkpointMobileMapMarker) {
			throw new Error(`${checkpoint} did not report its isolated seeded state on production_level_01 at desktop and mobile sizes.`);
		}
		if (!defaultMapMarker || !freshReviewMapMarker) {
			throw new Error("The Web root or map-unspecified review URL did not load production_level_01.");
		}
		if (!referenceDesktopMarker || !referenceMobileMarker || !referenceFreshMarker) {
			throw new Error("The reference-slice review URL did not load production_slice_01 with isolated state at desktop and mobile sizes.");
		}
		if (referenceDesktop.canvasSize.width <= 0 || referenceDesktop.canvasSize.height <= 0) {
			throw new Error("Reference-slice canvas did not initialize at the desktop review size.");
		}
		if (referenceMobile.canvasSize.width <= 0 || referenceMobile.canvasSize.height <= 0) {
			throw new Error("Reference-slice canvas did not initialize at the mobile review size.");
		}
		if (mobile.canvasSize.width <= 0 || mobile.canvasSize.height <= 0) {
			throw new Error("Godot canvas did not initialize at the mobile framing check size.");
		}
		if (mobile.canvasSize.cssPosition === "fixed") {
			throw new Error("The Web shell must not fix the canvas independently of Godot's touch-coordinate geometry.");
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
		for (const [name, difference] of Object.entries(mobile.touchDiffs)) {
			if (difference < mobileTouchThreshold) {
				throw new Error(
					`Mobile control ${name} did not respond at its rendered touch position; pixel difference ${difference.toFixed(2)} is below ${mobileTouchThreshold}.`
				);
			}
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

function buildFreshReviewUrl(url) {
	const reviewUrl = new URL(url);
	reviewUrl.searchParams.set("review", expectedSha || "fresh");
	return reviewUrl.toString();
}

function buildCheckpointReviewUrl(url) {
	const reviewUrl = new URL(buildFreshReviewUrl(url));
	reviewUrl.searchParams.set("checkpoint", checkpoint);
	return reviewUrl.toString();
}

function buildReferenceSliceReviewUrl(url) {
	const reviewUrl = new URL(url);
	reviewUrl.searchParams.set("review", expectedSha || "fresh");
	reviewUrl.searchParams.set("map", "production_slice_01");
	return reviewUrl.toString();
}

async function inspectPreview(browser, url, viewport, outputPath, pageOptions = {}, verifyMobileTouches = false) {
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
			cssPosition: getComputedStyle(canvas).position,
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
		const touchDiffs = verifyMobileTouches ? await probeMobileControls(page, canvasRect) : {};

		return { canvasRect, canvasSize, failedRequests, messages, signature, touchDiffs, viewportMetrics };
	} finally {
		await page.close();
	}
}

async function probeMobileControls(page, canvasRect) {
	const probes = mobileControlProbes();
	const client = await page.context().newCDPSession(page);
	const differences = {};
	try {
		for (const probe of probes) {
			const point = projectLogicalPoint(canvasRect, probe.point);
			const region = projectLogicalRect(canvasRect, probe.region);
			const before = await sampleCanvasRegion(page, region);
			await client.send("Input.dispatchTouchEvent", {
				type: "touchStart",
				touchPoints: [{ x: point.x, y: point.y, id: 1, radiusX: 4, radiusY: 4, force: 1 }],
			});
			try {
				await page.waitForTimeout(150);
				const pressed = await sampleCanvasRegion(page, region);
				differences[probe.name] = compareSignatures(before, pressed);
			} finally {
				await client.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
				await page.waitForTimeout(100);
			}
		}
	} finally {
		await client.detach();
	}
	return differences;
}

function mobileControlProbes() {
	// These logical regions mirror the 3x3 command grid in mobile_test_controls.gd.
	const probes = [
		{
			name: "stick_down",
			point: { x: 142, y: 604.8 },
			region: { left: 30, top: 392, width: 224, height: 224 },
		},
	];
	const commandNames = [
		"oxygen_button",
		"cargo_button",
		"tool_button",
		"project_button",
		"day_button",
		"reset_button",
		"interact_button",
		"use_button",
		"bond_button",
	];
	for (let index = 0; index < commandNames.length; index += 1) {
		const column = index % 3;
		const row = Math.floor(index / 3);
		const region = {
			left: 846 + column * 138,
			top: 356 + row * 90,
			width: 128,
			height: 80,
		};
		probes.push({
			name: commandNames[index],
			point: { x: region.left + 64, y: region.top + 40 },
			region,
		});
	}
	return probes;
}

function projectLogicalPoint(canvasRect, point) {
	const scale = Math.min(
		canvasRect.width / logicalGameSize.width,
		canvasRect.height / logicalGameSize.height
	);
	const contentLeft = canvasRect.left + (canvasRect.width - logicalGameSize.width * scale) * 0.5;
	const contentTop = canvasRect.top + (canvasRect.height - logicalGameSize.height * scale) * 0.5;
	return {
		x: contentLeft + point.x * scale,
		y: contentTop + point.y * scale,
	};
}

function projectLogicalRect(canvasRect, region) {
	const topLeft = projectLogicalPoint(canvasRect, { x: region.left, y: region.top });
	const scale = Math.min(
		canvasRect.width / logicalGameSize.width,
		canvasRect.height / logicalGameSize.height
	);
	return {
		left: topLeft.x,
		top: topLeft.y,
		width: region.width * scale,
		height: region.height * scale,
	};
}

async function sampleCanvasRegion(page, region) {
	return page.locator("canvas").evaluate((canvas, sampleRegion) => {
		const rect = canvas.getBoundingClientRect();
		const sourceScaleX = canvas.width / rect.width;
		const sourceScaleY = canvas.height / rect.height;
		const scratch = document.createElement("canvas");
		scratch.width = 64;
		scratch.height = 48;
		const context = scratch.getContext("2d", { willReadFrequently: true });
		context.drawImage(
			canvas,
			(sampleRegion.left - rect.left) * sourceScaleX,
			(sampleRegion.top - rect.top) * sourceScaleY,
			sampleRegion.width * sourceScaleX,
			sampleRegion.height * sourceScaleY,
			0,
			0,
			scratch.width,
			scratch.height
		);
		return Array.from(context.getImageData(0, 0, scratch.width, scratch.height).data);
	}, region);
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
