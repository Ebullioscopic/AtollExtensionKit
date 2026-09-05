import XCTest
@testable import AtollExtensionKit

final class NotchContentLayoutTests: XCTestCase {
    private typealias Tab = AtollNotchExperienceDescriptor.TabConfiguration

    func testLegacyPayloadDecodesWithoutLayout() throws {
        let data = Data(#"{"title":"Legacy","sections":[],"allowWebInteraction":false}"#.utf8)
        let tab = try JSONDecoder().decode(Tab.self, from: data)
        XCTAssertNil(tab.contentLayout)
        XCTAssertTrue(tab.isValid)
    }

    func testDefaultEncodingOmitsNewKey() throws {
        let data = try JSONEncoder().encode(Tab(title: "Legacy"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(json["contentLayout"])
    }

    func testLayoutsRoundTripWithoutGrantingInteraction() throws {
        for layout: Tab.ContentLayout in [.standard, .contentOnly] {
            let original = Tab(title: "Dashboard", contentLayout: layout)
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Tab.self, from: data)
            XCTAssertEqual(decoded, original)
            XCTAssertFalse(decoded.allowWebInteraction)
            XCTAssertTrue(decoded.isValid)
        }
    }

    func testContentOnlyStillRequiresAccessibleTitle() {
        XCTAssertFalse(Tab(title: "", contentLayout: .contentOnly).isValid)
    }
}
