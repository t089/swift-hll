// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-hyperloglog",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(path: "../") 
    ],
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
)

