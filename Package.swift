// swift-tools-version: 5.4

import PackageDescription

let package = Package(
	name: "DSFRegex",
	products: [
		.library(name: "DSFRegex", targets: ["DSFRegex"]),
		.library(name: "DSFRegex-static", type: .static, targets: ["DSFRegex"]),
		.library(name: "DSFRegex-dynamic", type: .dynamic, targets: ["DSFRegex"]),
	],
	targets: [
		.target(
			name: "DSFRegex",
			dependencies: [],
			resources: [
				.copy("PrivacyInfo.xcprivacy"),
			]
		),
		.testTarget(
			name: "DSFRegexTests",
			dependencies: ["DSFRegex"]),
	]
)
