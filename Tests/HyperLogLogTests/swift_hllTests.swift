import Testing

@testable import HyperLogLog

#if canImport(Darwin)
    import Darwin.C
#elseif canImport(Glibc)
    import Glibc
#endif

@Test func example() async throws {
    var hll = HyperLogLog(precision: 10)
    hll.insert("a")
    hll.insert("b")
    hll.insert("c")
    hll.insert("d")
    hll.insert("e")
    hll.insert("f")

    #expect(round(hll.estimatedUniqueCount) == 6)
}

@Test func example2() async throws {
    var hll = HyperLogLog(precision: 10)
    hll.insert("a")
    hll.insert("b")
    hll.insert("b")
    hll.insert("b")
    hll.insert("b")
    hll.insert("b")
    hll.insert("b")
    hll.insert("b")
    hll.insert("b")
    hll.insert("c")
    hll.insert("d")
    hll.insert("e")
    hll.insert("f")

    #expect(round(hll.estimatedUniqueCount) == 6)
}

@Test func testMany() {
    let realCount: UInt32 = 1_000_000
    var hll = HyperLogLog(precision: .highest)
    for i in 0..<realCount {
        hll.insert(i)
    }

    let estimated = hll.estimatedUniqueCount
    let relativeError = abs(estimated - Double(realCount)) / Double(realCount)

    #expect(relativeError < 0.01)
}

@Test func testMerge() {
    var hll1 = HyperLogLog(precision: .highest)
    var hll2 = HyperLogLog(precision: .highest)

    hll1.insert(1)
    hll1.insert(2)
    hll1.insert(3)
    hll1.insert(3)
    hll1.insert(3)
    hll1.insert(3)

    #expect(abs(hll1.estimatedUniqueCount - 3) < 0.01)

    hll2.insert(3)
    hll2.insert(4)
    hll2.insert(5)
    hll2.insert(6)
    hll2.insert(7)

    #expect(abs(hll2.estimatedUniqueCount - 5) < 0.01)

    hll1.merge(hll2)

    #expect(abs(hll1.estimatedUniqueCount - 7) < 0.01)
}

@Test func testRegisters() {
    var registers = Registers(count: 10)

    for i in 0..<10 {
        registers.setGreater(index: i, value: UInt32(i))
    }
    #expect(registers.zeros == 1)

    for i in 0..<10 {
        #expect(registers[i] == i)
    }
}
