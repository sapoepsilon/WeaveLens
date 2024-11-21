//
//  WeaveLensUITests.swift
//  WeaveLensUITests
//
//  Created by Varkhuman Mac on 11/17/24.
//

import XCTest

final class WeaveLensUITests: XCTestCase {
	var app: XCUIApplication!
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		app = XCUIApplication()
		
		// Set launch arguments to control app state
		app.launchArguments = ["UI-Testing"]
		
		// Reset authorization status for Photos
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		app.launchArguments.append("--reset-authorization-status-for-photos")
	}
	
	override func tearDownWithError() throws {
		app = nil
	}
	
	@MainActor
	func testPhotoGalleryInitialState() throws {
		// Given
		app.launch()
		// Then
		XCTAssertTrue(app.navigationBars["Photos"].exists)
	}
	
//	@MainActor
//	func testPhotoAccessDeniedView() throws {
//		// Given
//		app.launch()
//		
//		// When
//		let settingsButton = app.buttons["Open Settings"]
//		
//		// Then
//		XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
//		XCTAssertTrue(app.staticTexts["Photo Access Required"].exists)
//		XCTAssertTrue(app.staticTexts["Please allow access to your photos in Settings to use this feature."].exists)
//	}
	
	@MainActor
	func testPhotoGridLayout() throws {
		// Given
		app.launch()
		
		// When
		// Wait for photo grid to appear (assuming photos access is granted)
		let photoGrid = app.scrollViews.firstMatch
		let exists = photoGrid.waitForExistence(timeout: 5)
		
		// Then
		XCTAssertTrue(exists)
		
		// Test scrolling
		photoGrid.swipeUp()
		photoGrid.swipeDown()
	}
	
	@MainActor
	func testPhotoSelection() throws {
		// Given
		app.launch()
		
		// When
		let photoGrid = app.scrollViews.firstMatch
		guard photoGrid.waitForExistence(timeout: 5) else {
			XCTFail("Photo grid did not appear")
			return
		}
		
		// Then
		// Test first photo cell if it exists
		let firstPhoto = photoGrid.images.firstMatch
		if firstPhoto.exists {
			firstPhoto.tap()
			// Add assertions for what should happen after tapping
			// Once you implement photo editor navigation
		}
	}
	
	@MainActor
	func testNavigationBarPresence() throws {
		// Given
		app.launch()
		
		// Then
		let navBar = app.navigationBars["Photos"]
		XCTAssertTrue(navBar.exists)
	}
	
	@MainActor
	func testLaunchPerformance() throws {
		if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
			measure(metrics: [XCTApplicationLaunchMetric()]) {
				XCUIApplication().launch()
			}
		}
	}
}
