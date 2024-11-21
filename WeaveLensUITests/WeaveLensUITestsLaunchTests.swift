//
//  WeaveLensUITestsLaunchTests.swift
//  WeaveLensUITests
//
//  Created by Varkhuman Mac on 11/17/24.
//

import XCTest

final class WeaveLensUITestsLaunchTests: XCTestCase {
	override class var runsForEachTargetApplicationUIConfiguration: Bool {
		true
	}
	
	override func setUpWithError() throws {
		continueAfterFailure = false
	}
	
	@MainActor
	func testLaunch() throws {
		let app = XCUIApplication()
		app.launch()
		
		// Verify initial UI elements
		XCTAssertTrue(app.navigationBars["Photos"].exists)
		
		// Take screenshot of initial state
		let initialStateScreenshot = XCTAttachment(screenshot: app.screenshot())
		initialStateScreenshot.name = "Initial State"
		initialStateScreenshot.lifetime = .keepAlways
		add(initialStateScreenshot)
		
		// Wait for content to load
		let photoGrid = app.scrollViews.firstMatch
		if photoGrid.waitForExistence(timeout: 5) {
			// Take screenshot of loaded state
			let loadedStateScreenshot = XCTAttachment(screenshot: app.screenshot())
			loadedStateScreenshot.name = "Loaded State"
			loadedStateScreenshot.lifetime = .keepAlways
			add(loadedStateScreenshot)
		}
	}
}
