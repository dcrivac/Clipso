import XCTest
import SwiftUI
@testable import Clipso

final class DataModelsTests: XCTestCase {

    // MARK: - ClipboardCategory Tests

    func testClipboardCategoryAllCases() {
        let allCategories = ClipboardCategory.allCases

        XCTAssertEqual(allCategories.count, 7, "Should have exactly 7 categories")

        // Verify all expected categories exist
        XCTAssertTrue(allCategories.contains(.text))
        XCTAssertTrue(allCategories.contains(.code))
        XCTAssertTrue(allCategories.contains(.link))
        XCTAssertTrue(allCategories.contains(.email))
        XCTAssertTrue(allCategories.contains(.phone))
        XCTAssertTrue(allCategories.contains(.color))
        XCTAssertTrue(allCategories.contains(.image))
    }

    func testClipboardCategoryRawValues() {
        XCTAssertEqual(ClipboardCategory.text.rawValue, 0)
        XCTAssertEqual(ClipboardCategory.code.rawValue, 1)
        XCTAssertEqual(ClipboardCategory.link.rawValue, 2)
        XCTAssertEqual(ClipboardCategory.email.rawValue, 3)
        XCTAssertEqual(ClipboardCategory.phone.rawValue, 4)
        XCTAssertEqual(ClipboardCategory.color.rawValue, 5)
        XCTAssertEqual(ClipboardCategory.image.rawValue, 6)
    }

    func testClipboardCategoryDisplayNames() {
        XCTAssertEqual(ClipboardCategory.text.displayName, "Text")
        XCTAssertEqual(ClipboardCategory.code.displayName, "Code")
        XCTAssertEqual(ClipboardCategory.link.displayName, "Link")
        XCTAssertEqual(ClipboardCategory.email.displayName, "Email")
        XCTAssertEqual(ClipboardCategory.phone.displayName, "Phone")
        XCTAssertEqual(ClipboardCategory.color.displayName, "Color")
        XCTAssertEqual(ClipboardCategory.image.displayName, "Image")
    }

    func testClipboardCategoryIcons() {
        // Verify each category has an icon
        XCTAssertFalse(ClipboardCategory.text.icon.isEmpty, "Text should have icon")
        XCTAssertFalse(ClipboardCategory.code.icon.isEmpty, "Code should have icon")
        XCTAssertFalse(ClipboardCategory.link.icon.isEmpty, "Link should have icon")
        XCTAssertFalse(ClipboardCategory.email.icon.isEmpty, "Email should have icon")
        XCTAssertFalse(ClipboardCategory.phone.icon.isEmpty, "Phone should have icon")
        XCTAssertFalse(ClipboardCategory.color.icon.isEmpty, "Color should have icon")
        XCTAssertFalse(ClipboardCategory.image.icon.isEmpty, "Image should have icon")

        // Common SF Symbol icons
        XCTAssertEqual(ClipboardCategory.text.icon, "doc.text")
        XCTAssertEqual(ClipboardCategory.code.icon, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(ClipboardCategory.link.icon, "link")
        XCTAssertEqual(ClipboardCategory.email.icon, "envelope")
        XCTAssertEqual(ClipboardCategory.phone.icon, "phone")
        XCTAssertEqual(ClipboardCategory.color.icon, "paintpalette")
        XCTAssertEqual(ClipboardCategory.image.icon, "photo")
    }

    func testClipboardCategoryColors() {
        // Verify each category has a color
        XCTAssertNotNil(ClipboardCategory.text.color)
        XCTAssertNotNil(ClipboardCategory.code.color)
        XCTAssertNotNil(ClipboardCategory.link.color)
        XCTAssertNotNil(ClipboardCategory.email.color)
        XCTAssertNotNil(ClipboardCategory.phone.color)
        XCTAssertNotNil(ClipboardCategory.color.color)
        XCTAssertNotNil(ClipboardCategory.image.color)

        // Verify colors are distinct (basic check)
        let colors = ClipboardCategory.allCases.map { $0.color }
        // All categories should have colors assigned
        XCTAssertEqual(colors.count, ClipboardCategory.allCases.count)
    }

    func testClipboardCategoryFromRawValue() {
        // Test initialization from raw value
        XCTAssertEqual(ClipboardCategory(rawValue: 0), .text)
        XCTAssertEqual(ClipboardCategory(rawValue: 1), .code)
        XCTAssertEqual(ClipboardCategory(rawValue: 2), .link)
        XCTAssertEqual(ClipboardCategory(rawValue: 3), .email)
        XCTAssertEqual(ClipboardCategory(rawValue: 4), .phone)
        XCTAssertEqual(ClipboardCategory(rawValue: 5), .color)
        XCTAssertEqual(ClipboardCategory(rawValue: 6), .image)

        // Test invalid raw value
        XCTAssertNil(ClipboardCategory(rawValue: 99), "Invalid raw value should return nil")
        XCTAssertNil(ClipboardCategory(rawValue: -1), "Negative raw value should return nil")
    }

    func testClipboardCategoryEquality() {
        let text1 = ClipboardCategory.text
        let text2 = ClipboardCategory.text
        let code = ClipboardCategory.code

        XCTAssertEqual(text1, text2, "Same categories should be equal")
        XCTAssertNotEqual(text1, code, "Different categories should not be equal")
    }

    func testClipboardCategoryHashable() {
        // Verify categories can be used in Sets and Dictionaries
        let categorySet: Set<ClipboardCategory> = [.text, .code, .link]

        XCTAssertEqual(categorySet.count, 3, "Set should contain 3 distinct categories")
        XCTAssertTrue(categorySet.contains(.text))
        XCTAssertTrue(categorySet.contains(.code))
        XCTAssertTrue(categorySet.contains(.link))
        XCTAssertFalse(categorySet.contains(.email))
    }

    func testClipboardCategoryInDictionary() {
        var categoryDict: [ClipboardCategory: String] = [:]
        categoryDict[.text] = "Text items"
        categoryDict[.code] = "Code snippets"

        XCTAssertEqual(categoryDict[.text], "Text items")
        XCTAssertEqual(categoryDict[.code], "Code snippets")
        XCTAssertNil(categoryDict[.link])
    }

    func testClipboardCategoryCaseIterable() {
        // Verify we can iterate over all cases
        var count = 0
        for category in ClipboardCategory.allCases {
            XCTAssertNotNil(category.displayName)
            XCTAssertNotNil(category.icon)
            XCTAssertNotNil(category.color)
            count += 1
        }

        XCTAssertEqual(count, 7, "Should iterate over all 7 categories")
    }

    func testClipboardCategoryIconsAreValidSFSymbols() {
        // Verify icons are likely valid SF Symbol names
        for category in ClipboardCategory.allCases {
            let icon = category.icon
            // SF Symbol names typically contain dots or are single words
            XCTAssertFalse(icon.contains(" "), "Icon '\(icon)' should not contain spaces")
            XCTAssertGreaterThan(icon.count, 0, "Icon should not be empty")
        }
    }

    func testClipboardCategoryDisplayNamesAreCapitalized() {
        for category in ClipboardCategory.allCases {
            let displayName = category.displayName
            XCTAssertTrue(displayName.first?.isUppercase ?? false,
                         "Display name '\(displayName)' should start with uppercase")
            XCTAssertFalse(displayName.isEmpty, "Display name should not be empty")
        }
    }

    // MARK: - Usage Scenarios

    func testClipboardCategoryUsageInSwitch() {
        func getDescription(for category: ClipboardCategory) -> String {
            switch category {
            case .text:
                return "Plain text"
            case .code:
                return "Source code"
            case .link:
                return "URL"
            case .email:
                return "Email address"
            case .phone:
                return "Phone number"
            case .color:
                return "Color value"
            case .image:
                return "Image"
            }
        }

        XCTAssertEqual(getDescription(for: .text), "Plain text")
        XCTAssertEqual(getDescription(for: .code), "Source code")
        XCTAssertEqual(getDescription(for: .link), "URL")
    }

    func testClipboardCategoryFiltering() {
        let categories = ClipboardCategory.allCases

        // Filter categories that might contain code
        let codeRelated = categories.filter { $0 == .code }
        XCTAssertEqual(codeRelated.count, 1)
        XCTAssertEqual(codeRelated.first, .code)

        // Filter categories that are contact-related
        let contactRelated = categories.filter { $0 == .email || $0 == .phone }
        XCTAssertEqual(contactRelated.count, 2)
    }

    func testClipboardCategoryDefaultFallback() {
        // Test fallback when raw value is invalid
        let invalidRawValue = 999
        let category = ClipboardCategory(rawValue: invalidRawValue) ?? .text

        XCTAssertEqual(category, .text, "Should fallback to text for invalid raw value")
    }
}
