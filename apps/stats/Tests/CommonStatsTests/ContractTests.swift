import CommonTesting
import Testing

/// The rename to Common Stats changed only what people see; the identifiers the contract pins are
/// what an existing install's preferences and login item hang on.
@Suite struct ContractTests {
    @Test func keepsTheFamilyContract() throws {
        #expect(try AppContract(slug: "stats").violations() == [])
    }
}
