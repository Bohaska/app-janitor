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

    func testReplaceSpaceCharacters_replacesSpaces() async { // Marked as async
        let appNameWithSpaces = "app Name"
        let bundleIdWithSpaces = "com test app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        let actualAppOutput = await fileFinder.replaceSpaceCharacters(appNameWithSpaces) // Await call outside XCTAssert
        XCTAssertEqual(actualAppOutput, expectedAppOutput)

        let actualBundleOutput = await fileFinder.replaceSpaceCharacters(bundleIdWithSpaces) // Await call outside XCTAssert
        XCTAssertEqual(actualBundleOutput, expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesDots() async { // Marked as async
        let appNameWithDot = "app.Name"
        let bundleId = "com.test.app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        let actualAppOutput = await fileFinder.replaceSpaceCharacters(appNameWithDot)
        XCTAssertEqual(actualAppOutput, expectedAppOutput)

        let actualBundleOutput = await fileFinder.replaceSpaceCharacters(bundleId)
        XCTAssertEqual(actualBundleOutput, expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesUnderscores() async { // Marked as async
        let appNameWithUnderscore = "app_Name"
        let bundleIdWithUnderscore = "com_test_app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        let actualAppOutput = await fileFinder.replaceSpaceCharacters(appNameWithUnderscore)
        XCTAssertEqual(actualAppOutput, expectedAppOutput)

        let actualBundleOutput = await fileFinder.replaceSpaceCharacters(bundleIdWithUnderscore)
        XCTAssertEqual(actualBundleOutput, expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesDashes() async { // Marked as async
        let appNameWithDash = "app-Name"
        let bundleIdWithDash = "com-test-app"
        let expectedAppOutput = "app*name"
        let expectedBundleOutput = "com*test*app"

        let actualAppOutput = await fileFinder.replaceSpaceCharacters(appNameWithDash)
        XCTAssertEqual(actualAppOutput, expectedAppOutput)

        let actualBundleOutput = await fileFinder.replaceSpaceCharacters(bundleIdWithDash)
        XCTAssertEqual(actualBundleOutput, expectedBundleOutput)
    }

    func testReplaceSpaceCharacters_replacesCombination() async { // Marked as async
        let bundleIdCombo = "com-test_app"
        let expectedBundleOutput = "com*test*app"
        let actualBundleOutput = await fileFinder.replaceSpaceCharacters(bundleIdCombo)
        XCTAssertEqual(actualBundleOutput, expectedBundleOutput)
    }

    // MARK: - getAppNameVariations Tests

    func testGetAppNameVariations_returnsArrayOfStrings() async { // Marked as async
        let appName = "appName"
        let bundleId = "com.test.app"
        let variations = await fileFinder.getAppNameVariations(appName: appName, bundleId: bundleId) // Added await
        XCTAssertFalse(variations.isEmpty)
        XCTAssertTrue(variations.allSatisfy { !$0.isEmpty }) // Ensure no empty strings
    }

    func testGetAppNameVariations_convertsToLowercase() async { // Marked as async
        let appName = "AppName"
        let bundleId = "Com.Test.App"
        let variations = await fileFinder.getAppNameVariations(appName: appName, bundleId: bundleId) // Added await
        XCTAssertTrue(variations.allSatisfy { $0 == $0.lowercased() })
    }

    func testGetAppNameVariations_replacesSpaceChars() async { // Marked as async
        let appNameWithSpaces = "app Name"
        let bundleId = "com.test.app"
        let variations = await fileFinder.getAppNameVariations(appName: appNameWithSpaces, bundleId: bundleId) // Added await
        XCTAssertTrue(variations.allSatisfy { !$0.contains(" ") })
        XCTAssertTrue(variations.contains("app*name"))
        XCTAssertTrue(variations.contains("appname")) // normalizeString also adds this
        XCTAssertTrue(variations.contains("com*test"))
    }

    func testGetAppNameVariations_createsNewPatternIfAppContainsDot() async { // Marked as async
        let appNameWithDot = "app.Name"
        let bundleId = "com.test.app"
        let variations = await fileFinder.getAppNameVariations(appName: appNameWithDot, bundleId: bundleId) // Added await
        XCTAssertTrue(variations.contains("app"))
    }

    func testGetAppNameVariations_doesNotReturnDuplicates() async { // Marked as async
        let appName = "appName"
        let bundleId = "com.test.app"
        let variations = await fileFinder.getAppNameVariations(appName: appName, bundleId: bundleId) // Added await
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

        let bundleResult1 = await fileFinder.removeCommonFileSubstrings("com*app*desktop-\(exampleVersion1)")
        XCTAssertTrue(bundleResult1.contains("com*app*desktop")) // This checks if the version is removed, not if the entire string becomes "appname"
        XCTAssertFalse(bundleResult1.contains(exampleVersion1))


        let bundleResult2 = await fileFinder.removeCommonFileSubstrings("com*app*desktop-\(exampleVersion2)")
        XCTAssertTrue(bundleResult2.contains("com*app*desktop"))
        XCTAssertFalse(bundleResult2.contains(exampleVersion2))

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
