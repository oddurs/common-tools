import CommonTesting
import Testing

/// The rename to Common Keys changed only what people see; Accessibility access, preferences and
/// the login item hang on the identifiers the contract pins.
@Suite struct ContractTests {
    @Test func keepsTheFamilyContract() throws {
        #expect(try AppContract(slug: "keys").violations() == [])
    }
}
