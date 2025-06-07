# swift-hyperloglog

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ft089%2Fswift-hyperloglog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/t089/swift-hyperloglog) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ft089%2Fswift-hyperloglog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/t089/swift-hyperloglog)

A Swift implementation of the HyperLogLog algorithm for efficient cardinality estimation. This library provides a memory-efficient way to estimate the number of unique elements in a large dataset with high accuracy.

This implementation is based on the paper "HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm" by Philippe Flajolet, Éric Fusy, Olivier Gandouet, and Frédéric Meunier (2007).

The algorithm provides a memory-efficient way to estimate the cardinality of a multiset with a standard error of about 1.04/√m, where m is the number of registers used. The implementation uses 2^p registers, where p is the precision parameter (4-16 bits).


## Features

- Memory-efficient cardinality estimation
- Configurable precision (4-16 bits)
- Support for merging multiple HyperLogLog instances
- Built-in support for Swift's standard `Hashable` types
- Custom hashing support through the `CustomHashable` protocol

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/t089/swift-hyperloglog.git", from: "0.0.2")
]
```

Add the `HyperLogLog` module as a dependency to your target:

```swift
targets: [
    // ... other targets ...
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "HyperLogLog", package: "swift-hyperloglog"),
        ]
    ),
]
```


## Usage

### Basic Usage

```swift
import HyperLogLog

// Create a HyperLogLog instance with precision 10 (2^10 = 1024 registers)
var hll = HyperLogLog(precision: 10)

// Insert elements
hll.insert("a")
hll.insert("b")
hll.insert("c")

// Get the estimated unique count
let estimatedCount = hll.estimatedUniqueCount
print("Estimated unique elements: \(estimatedCount)")
```

### Handling Duplicates

The HyperLogLog algorithm automatically handles duplicates:

```swift
var hll = HyperLogLog(precision: 10)

// Insert the same element multiple times
hll.insert("a")
hll.insert("a")
hll.insert("a")

// The estimated count will still be 1
print("Estimated unique elements: \(hll.estimatedUniqueCount)")
```

### Merging Multiple HyperLogLog Instances

You can merge multiple HyperLogLog instances to combine their estimates:

```swift
var hll1 = HyperLogLog(precision: 10)
var hll2 = HyperLogLog(precision: 10)

// Add elements to first instance
hll1.insert(1)
hll1.insert(2)
hll1.insert(3)

// Add elements to second instance
hll2.insert(3)
hll2.insert(4)
hll2.insert(5)

// Merge hll2 into hll1
hll1.merge(hll2)

// hll1 now contains the combined estimate
print("Combined estimate: \(hll1.estimatedUniqueCount)")
```

### Precision

The precision parameter determines the accuracy and memory usage of the algorithm:

- Higher precision (e.g., 16) provides better accuracy but uses more memory (≈ 0.406% relative error)
- Lower precision (e.g., 4) uses less memory but may be less accurate (≈ 26% relative error)
- The default precision of 12 is a good balance for most use cases (≈ 1.625% relative error)

```swift
// Create a high-precision instance
var highPrecisionHLL = HyperLogLog(precision: .highest) // 16 bits

// Create a low-precision instance
var lowPrecisionHLL = HyperLogLog(precision: .lowest) // 4 bits
```

## Performance

The implementation is optimized for performance:
- Uses bit-packing for efficient memory usage
- Provides constant-time insertion and merging operations
- Supports custom hashing for specialized use cases

## Acknowledgements

This implementation is loosely based on [tabac/hyperloglog.rs](https://github.com/tabac/hyperloglog.rs).

## License

Copyright (c) 2025 Tobias Haeberle

Licensed under the Apache License, Version 2.0