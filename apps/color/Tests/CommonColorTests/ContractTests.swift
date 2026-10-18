import CommonTesting
import Testing

@Suite struct ContractTests {
    @Test func keepsTheFamilyContract() throws {
        #expect(try AppContract(slug: "color").violations() == [])
    }
}
