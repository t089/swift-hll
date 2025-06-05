#if canImport(Darwin)
    import Darwin.C
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

/// A protocol for hashing values.
public protocol CustomHasher {
    mutating func combine(bytes: UnsafeRawBufferPointer)
    mutating func finalize() -> Int
}

extension CustomHasher {
    public mutating func combine<T: CustomHashable>(_ value: T) {
        value.hash(into: &self)
    }
}

/// A protocol for values that can be hashed using a `CustomHasher`.
public protocol CustomHashable {
    func hash<H: CustomHasher>(into hasher: inout H)
}

extension Hasher: CustomHasher {}

extension CustomHasher where Self == Hasher {
    /// The standard library's `Hasher` implementation.
    public static var stdlib: Self { Hasher() }
}

/// A HyperLogLog implementation.
///
/// This implementation is based on the paper "HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm" by Flajolet, Fusy, Gandouet, and Meunier.
///
/// The implementation is generic over the hasher used to hash the elements.
///
/// To use the implementation with the standard library's `Hasher`, use the `HyperLogLog(precision:)` initializer.
///
public struct HyperLogLog<Hasher: CustomHasher> {
    public struct Precision: RawRepresentable, ExpressibleByIntegerLiteral, CustomStringConvertible,
        Comparable
    {
        public static var lowest: Self { Self(validated: 4) }
        public static var `default`: Self { Self(validated: 12) }
        public static var highest: Self { Self(validated: 16) }

        public let rawValue: Int

        /// Creates a new Precision.
        ///
        /// - Parameter rawValue: The raw value of the precision.
        /// - Precondition: The raw value must be between 4 and 16.
        public init(rawValue: Int) {
            if rawValue < Self.lowest.rawValue || rawValue > Self.highest.rawValue {
                fatalError(
                    "Precision must be between \(Self.lowest.rawValue) and \(Self.highest.rawValue)"
                )
            }
            self.rawValue = rawValue
        }

        /// Creates a new Precision.
        ///
        /// - Parameter precision: The precision to create.
        /// - Precondition: The precision must be between 4 and 16.
        public init(_ precision: Int) {
            self.init(rawValue: precision)
        }

        private init(validated rawValue: Int) {
            self.rawValue = rawValue
        }

        public init(integerLiteral value: Int) {
            self.init(rawValue: value)
        }

        public var description: String {
            return "Precision(\(rawValue))"
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    /// The precision of the HyperLogLog.
    public let precision: Precision

    /// The number of registers in the HyperLogLog.
    public let m: Int

    @usableFromInline var registers: Registers
    @usableFromInline let makeHasher: () -> Hasher

    /// Creates a new HyperLogLog with the given precision and hasher.
    ///
    /// - Parameters:
    ///   - precision: The precision of the HyperLogLog. Must be between .lowest (4) and .highest (16).
    ///   - makeHasher: A closure that creates a new hasher.
    public init(precision: Precision = .default, makeHasher: @escaping () -> Hasher) {
        self.precision = precision
        self.m = 1 << precision.rawValue
        self.registers = Registers(count: m)
        self.makeHasher = makeHasher
    }

    /// Inserts an element into the HyperLogLog.
    ///
    /// - Parameter element: The element to insert.
    @inlinable
    public mutating func insert<Element: CustomHashable>(_ element: Element) {
        var hasher = makeHasher()
        hasher.combine(element)
        let hash = hasher.finalize()
        insertRaw(UInt32(truncatingIfNeeded: hash))
    }

    /// Inserts a raw hash value into the HyperLogLog.
    @inlinable
    public mutating func insertRaw(_ hash: UInt32) {
        let index = Int(hash >> (32 - self.precision.rawValue))
        let remainingBits = hash << self.precision.rawValue | (1 << (self.precision.rawValue - 1))
        let zeros = UInt32(1 + remainingBits.leadingZeroBitCount)
        registers.setGreater(index: index, value: zeros)
    }

    /// Merges another HyperLogLog with the current one.
    ///
    /// - Parameter other: The other HyperLogLog to merge with.
    /// Note: The precisions of the two HyperLogLogs must match.
    public mutating func merge(_ other: HyperLogLog) {
        precondition(self.precision == other.precision, "Precisions must match")
        for i in 0..<registers.count {
            registers.setGreater(index: i, value: other.registers[i])
        }
    }

    /// Estimates the number of unique elements in the HyperLogLog.
    ///
    /// The estimate is based on the HyperLogLog algorithm and is accurate up to a standard error of about 1.04/√m, where m is the number of registers used.
    ///
    /// - Returns: The estimated number of unique elements.
    public var estimatedUniqueCount: Double {
        let alpha = HyperLogLog.alpha(for: m)
        let m = Double(m)
        var Z = 0.0
        for i in 0..<registers.count {
            Z += pow(2.0, -Double(registers[i]))
        }
        let E = alpha * m * m / Z

        let zeros = registers.zeros
        if E <= 2.5 * m && zeros > 0 {
            return HyperLogLog.linearCount(m: m, zeros: Double(zeros))
        }

        let two32 = Double(1 << 32)
        if E > two32 / 30.0 {
            return -two32 * log(1.0 - E / two32)
        }

        return E
    }

    /// Computes the constant α_m based on the number of registers `m`.
    /// For m = 16: α = 0.673, m = 32: α = 0.697, m = 64: α = 0.709, else α = 0.7213 / (1 + 1.079 / m).
    private static func alpha(for m: Int) -> Double {
        switch m {
        case 16:
            return 0.673
        case 32:
            return 0.697
        case 64:
            return 0.709
        default:
            return 0.7213 / (1.0 + 1.079 / Double(m))
        }
    }

    /// Linear counting for small cardinalities: m * ln(m / V), where V = number of zero registers.
    private static func linearCount(m: Double, zeros: Double) -> Double {
        return m * log(m / zeros)
    }
}

extension HyperLogLog where Hasher == Swift.Hasher {
    /// Creates a new HyperLogLog with the default precision and the standard library's `Hasher`.
    ///
    /// - Parameter precision: The precision of the HyperLogLog.
    public init(precision: Precision = .default) {
        self.init(precision: precision, makeHasher: { .stdlib })
    }

    /// Inserts an element into the HyperLogLog.
    ///
    /// - Parameter element: The element to insert.
    public mutating func insert<Element: Hashable>(_ element: Element) {
        var hasher = Hasher()
        hasher.combine(element)
        let hash = hasher.finalize()
        insertRaw(UInt32(truncatingIfNeeded: hash))
    }
}

@usableFromInline
struct Registers {
    @usableFromInline
    static let size = 5  // bits per register

    @usableFromInline
    static let countPerWord = 32 / size

    /// A bitmask used to extract the value of a single register from a word.
    /// For size=5, this creates a mask of 0b11111 (31 in decimal)
    @usableFromInline
    static let mask: UInt32 = (1 << size) - 1

    @usableFromInline
    var buffer: [UInt32]  // should be inline array

    @usableFromInline
    var count: Int
    @usableFromInline
    var zeros: Int

    init(count: Int) {
        self.buffer = [UInt32](repeating: 0, count: Int(ceilDivision(count, Self.countPerWord)))
        self.count = count
        self.zeros = count
    }

    //   Mask:                                  11111
    // Word 0: 00 00000 00000 00000 00000 00000 00000
    //                0     1     2     3     4     5
    // Word 1: 00 00000 00000 00000 00000 00000 00000
    //                6     7     8     9    10    11

    @inlinable
    subscript(index: Int) -> UInt32 {
        get {
            precondition(index < count, "Index out of bounds")
            let wordIndex = index / Self.countPerWord
            let bitIndex = index % Self.countPerWord
            return buffer[wordIndex] &>> (bitIndex * Self.size) & Self.mask
        }
    }

    @inlinable
    mutating func setGreater(index: Int, value: UInt32) {
        precondition(index < count, "Index out of bounds")

        assert(value < (1 << Self.size), "Value must be less than \(1<<Self.size)")

        let wordIndex = index / Self.countPerWord
        let bitIndex = index % Self.countPerWord

        let currentValue = self.buffer[wordIndex] &>> (bitIndex * Self.size) & Self.mask

        if value > currentValue {
            if currentValue == 0 {
                self.zeros -= 1
                self.buffer[wordIndex] |= (value << (bitIndex * Self.size))
            } else {
                let mask = Self.mask << (bitIndex * Self.size)
                self.buffer[wordIndex] =
                    (self.buffer[wordIndex] & ~mask) | (value << (bitIndex * Self.size))
            }
        }
    }
}

private func ceilDivision<I: BinaryInteger>(_ a: I, _ b: I) -> I {
    return (a + b - 1) / b
}
