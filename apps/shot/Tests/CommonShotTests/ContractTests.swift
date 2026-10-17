import CommonTesting
import Testing

/// Screen Recording access is granted to the bundle identifier the contract pins.
@Suite struct ContractTests {
    @Test func keepsTheFamilyContract() throws {
        #expect(try AppContract(slug: "shot").violations() == [])
    }
}
