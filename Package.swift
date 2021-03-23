// swift-tools-version:5.1
import PackageDescription

let package = Package(
	name: "Combine Extensions",
	platforms: [ .iOS( .v11 ), .tvOS( .v11 ), .macOS( .v10_15 ) ],
	products: [
		.library( name: "CombineExtensions", targets: ["CombineExtensions"]),
	],
	targets: [
		.target( name: "CombineExtensions", dependencies: [], path: "CombineExtensions" ),
		.testTarget(
			name: "CombineExtensionsTests",
			dependencies: [ "CombineExtensions" ],
			path: "CombineExtensionsTests"
		),

	],
	swiftLanguageVersions: [ .v5 ]
)
