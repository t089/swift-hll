// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "benchmarks",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.29.3"),
        .package(path: "../") 
    ],
    targets: [
        .executableTarget(
            name: "HyperLogLogBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "HyperLogLog", package: "swift-hyperloglog"),
            ],
            path: "HyperLogLogBenchmarks/",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)

