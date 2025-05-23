// AppJanitorTests/AppJanitorTests.swift
import XCTest
@testable import appuninstall // Import your main app module to access internal types

final class AppJanitorTests: XCTestCase {

    var fileFinder: AppFileFinder! // Instance of your core logic actor

    // Setup before each test method
    override func setUpWithError() throws {
        try super.setUpWithError()
        fileFinder = AppFileFinder() // Create a new instance for each test
        // Note: If tests relied on `computerName` being loaded immediately,
        // you might need a short `await` here with `Task { await fileFinder.loadComputerName() }`
        // and `XCTWaiter` if you need to block the test for it.
        // For these string manipulation tests, it's not strictly necessary.
    }

    // Teardown after each test method
    override func tearDownWithError() throws {
        fileFinder = nil
        try super.tearDownWithError()
    }

    // MARK: - replaceSpaceCharacters Tests

    func testReplaceSpaceCharacters_replacesSpaces() {
        let appNameWithSpaces = "app Name"
        let bundleIdWithSpaces = "com test app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        XCTAssertEqual(fileFinder.replaceSpaceCharacters(appNameWithSpaces), expectedAppOutput)
        XCTAssertEqual(fileFinder.replaceSpaceCharacters(bundleIdWithSpaces), expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesDots() {
        let appNameWithDot = "app.Name"
        let bundleId = "com.test.app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        XCTAssertEqual(fileFinder.replaceSpaceCharacters(appNameWithDot), expectedAppOutput)
        XCTAssertEqual(fileFinder.replaceSpaceCharacters(bundleId), expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesUnderscores() {
        let appNameWithUnderscore = "app_Name"
        let bundleIdWithUnderscore = "com_test_app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        XCTAssertEqual(fileFinder.replaceSpaceCharacters(appNameWithUnderscore), expectedAppOutput)
        XCTAssertEqual(fileFinder.replaceSpaceCharacters(bundleIdWithUnderscore), expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesDashes() {
        let appNameWithDash = "app-Name"
        let bundleIdWithDash = "com-test-app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        XCTAssertEqual(fileFinder.replaceSpaceCharacters(appNameWithDash), expectedAppOutput)
        XCTAssertEqual(fileFinder.replaceSpaceCharacters(bundleIdWithDash), expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesCombination() {
        let bundleIdCombo = "com-test_app"
        let expectedBundleOutput = "com*test*app"
        XCTAssertEqual(fileFinder.replaceSpaceCharacters(bundleIdCombo), expectedBundleOutput)
    }

    // MARK: - getAppNameVariations Tests

    func testGetAppNameVariations_returnsArrayOfStrings() { // No async needed for this pure function
        let appName = "appName"
        let bundleId = "com.test.app"
        let variations = fileFinder.getAppNameVariations(appName: appName, bundleId: bundleId)
        XCTAssertFalse(variations.isEmpty)
        XCTAssertTrue(variations.allSatisfy { !$0.isEmpty }) // Ensure no empty strings
    }

    func testGetAppNameVariations_convertsToLowercase() {
        let appName = "AppName"
        let bundleId = "Com.Test.App"
        let variations = fileFinder.getAppNameVariations(appName: appName, bundleId: bundleId)
        XCTAssertTrue(variations.allSatisfy { $0 == $0.lowercased() })
    }

    func testGetAppNameVariations_replacesSpaceChars() {
        let appNameWithSpaces = "app Name"
        let bundleId = "com.test.app"
        let variations = fileFinder.getAppNameVariations(appName: appNameWithSpaces, bundleId: bundleId)
        XCTAssertTrue(variations.allSatisfy { !$0.contains(" ") })
        XCTAssertTrue(variations.contains("app*name"))
        XCTAssertTrue(variations.contains("appname")) // normalizeString also adds this
        XCTAssertTrue(variations.contains("com*test"))
    }

    func testGetAppNameVariations_createsNewPatternIfAppContainsDot() {
        let appNameWithDot = "app.Name"
        let bundleId = "com.test.app"
        let variations = fileFinder.getAppNameVariations(appName: appNameWithDot, bundleId: bundleId)
        XCTAssertTrue(variations.contains("app"))
    }

    func testGetAppNameVariations_doesNotReturnDuplicates() {
        let appName = "appName"
        let bundleId = "com.test.app"
        let variations = fileFinder.getAppNameVariations(appName: appName, bundleId: bundleId)
        XCTAssertTrue(isArrayUniqueValues(variations)) // isArrayUniqueValues is from Utils/Utils.swift
    }

    // MARK: - removeCommonFileSubstrings Tests

    func testRemoveCommonFileSubstrings_removesUUID() async {
        let appName = "appName"
        let exampleUUID = "a7293542-411f-400f-ac18-fb93c61bb5b6"
        let result = await fileFinder.removeCommonFileSubstrings("\(appName)\(exampleUUID)")
        XCTAssertFalse(result.contains(exampleUUID))
        XCTAssertEqual(result, "appname")
    }

    func testRemoveCommonFileSubstrings_removesDate() async {
        let appName = "appName"
        let exampleDate = "2022-13-040123456" // Invalid date but format matches regex
        let result = await fileFinder.removeCommonFileSubstrings("\(appName)\(exampleDate)")
        XCTAssertFalse(result.contains(exampleDate))
        XCTAssertEqual(result, "appname")
    }

    func testRemoveCommonFileSubstrings_removesVersionNumbers() async {
        let appName = "appName"
        let exampleVersion1 = "1.2.3"
        let exampleVersion2 = "2022.2"

        let result1 = await fileFinder.removeCommonFileSubstrings("\(appName)\(exampleVersion1)")
        XCTAssertFalse(result1.contains(exampleVersion1))
        XCTAssertEqual(result1, "appname")

        let result2 = await fileFinder.removeCommonFileSubstrings("\(appName)\(exampleVersion2)")
        XCTAssertFalse(result2.contains(exampleVersion2))
        XCTAssertEqual(result2, "appname")
    }

    func testRemoveCommonFileSubstrings_removesCommonExtensions() async {
        let appName = "appName"
        for extensionStr in commonExtensions { // commonExtensions is from Utils/FilePatterns.swift
            var name = appName
            name = "\(name)\(extensionStr)"
            let result = await fileFinder.removeCommonFileSubstrings(name)
            XCTAssertFalse(result.contains(extensionStr.lowercased()), "Failed to remove extension: \(extensionStr)")
            XCTAssertEqual(result, "appname")
        }
    }

    func testRemoveCommonFileSubstrings_removesCommonSubstrings() async {
        let appName = "appName"
        for subString in commonSubStrings { // commonSubStrings is from Utils/FilePatterns.swift
            var name = appName
            name = "\(name)\(subString)"
            let result = await fileFinder.removeCommonFileSubstrings(name)
            XCTAssertFalse(result.contains(subString.lowercased()), "Failed to remove substring: \(subString)")
            XCTAssertEqual(result, "appname")
        }
    }

    // MARK: - doesFileContainAppPattern Tests

    func testDoesFileContainAppPattern_appNameReturnsTrue() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"

        let result = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "app")
        XCTAssertTrue(result)

        let bundleResult = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "com*app*desktop")
        XCTAssertTrue(bundleResult)
    }

    func testDoesFileContainAppPattern_appNameWithVersionReturnsTrue() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"
        let exampleVersion1 = "1.2.3"
        let exampleVersion2 = "2022.2"

        let result1 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "app-\(exampleVersion1)")
        XCTAssertTrue(result1)

        let result2 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "app-\(exampleVersion2)")
        XCTAssertTrue(result2)

        let bundleResult1 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "com*app*desktop-\(exampleVersion1)")
        XCTAssertTrue(bundleResult1)

        let bundleResult2 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "com*app*desktop-\(exampleVersion2)")
        XCTAssertTrue(bundleResult2)
    }

    func testDoesFileContainAppPattern_appNameWithUUIDReturnsTrue() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"
        let exampleUUID = "a7293542-411f-400f-ac18-fb93c61bb5b6"

        let result = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "app-\(exampleUUID)")
        XCTAssertTrue(result)

        let bundleResult = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "com*app*desktop-\(exampleUUID)")
        XCTAssertTrue(bundleResult)
    }

    func testDoesFileContainAppPattern_appNameWithDateReturnsTrue() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"
        let exampleDate = "2022-13-040123456"

        let result = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "app-\(exampleDate)")
        XCTAssertTrue(result)

        let bundleResult = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "com*app*desktop-\(exampleDate)")
        XCTAssertTrue(bundleResult)
    }

    func testDoesFileContainAppPattern_differentAppNameReturnsFalse() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"
        let result = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "nottheapp")
        XCTAssertFalse(result)
    }

    func testDoesFileContainAppPattern_differentBundleIdReturnsFalse() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"

        let result1 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "com*nottheapp*desktop")
        XCTAssertFalse(result1)

        let result2 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "co*app*desktop")
        XCTAssertFalse(result2)
    }

    func testDoesFileContainAppPattern_containsBundleIdInLongStringReturnsTrue() async {
        let patternArray = ["app", "com*app*desktop", "com*app"]
        let bundleId = "com.test.app"
        let bundleIdWithStar = "com*test*app" // Expected transformed bundleId

        let result1 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: bundleIdWithStar.padding(toLength: 20, withPad: "x", startingAt: 0))
        XCTAssertTrue(result1)

        let result2 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: bundleIdWithStar.padding(toLength: 20, withPad: "x", startingAt: bundleIdWithStar.count))
        XCTAssertTrue(result2)

        let result3 = await fileFinder.doesFileContainAppPattern(appNameVariations: patternArray, bundleId: bundleId, fileNameToCheck: "xxxxx\(bundleIdWithStar)xxxx")
        XCTAssertTrue(result3)
    }
}
