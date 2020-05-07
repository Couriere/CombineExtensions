// swift-tools-version:5.1
import PackageDescription

let package = Package(
	name: "Combine Extensions",
	platforms: [ .iOS( .v11 ), .tvOS( .v11 ) ],
	products: [
		.library( name: "CombineExtensions", targets: ["CombineExtensions"]),
	],
	targets: [
		.target( name: "CombineExtensions", dependencies: [], path: "CombineExtensions" ),
	],
	swiftLanguageVersions: [ .v5 ]
)
