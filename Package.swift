// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-hyperloglog",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HyperLogLog",
            targets: ["HyperLogLog"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.29.3"), 
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HyperLogLog"),
        .testTarget(
            name: "HyperLogLogTests",
            dependencies: ["HyperLogLog"]
        ),
    ]
)

// Benchmark of HyperLogLogBenchmarks
package.targets += [
    .executableTarget(
        name: "HyperLogLogBenchmarks",
        dependencies: [
            .product(name: "Benchmark", package: "package-benchmark"),
            "HyperLogLog",
        ],
        path: "Benchmarks/HyperLogLogBenchmarks",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]