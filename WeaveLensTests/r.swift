//
//  WeaveLensTests.swift
//  WeaveLensTests
//
//  Created by Varkhuman Mac on 11/17/24.
//

import Testing
import Photos
import SwiftUI
@testable import WeaveLens

struct WeaveLensTests {
	// MARK: - Mocks
	class MockPhotoLibraryService: PhotoLibraryService {
		var authorizationStatus: PHAuthorizationStatus = .notDetermined
		var mockAssets: [PHAsset] = []
		
		func requestAuthorization(for level: PHAccessLevel) async -> PHAuthorizationStatus {
			return authorizationStatus
		}
		
		func fetchAssets() -> [PHAsset] {
			return mockAssets
		}
	}
	
	// MARK: - ViewModel Tests
	@Test func testPhotoGalleryViewModelInitialState() async throws {
		// Given
		let mockService = MockPhotoLibraryService()
		let viewModel = PhotoGalleryViewModel(photoLibrary: mockService)
		
		// Then
		#expect(viewModel.photos.isEmpty)
		#expect(viewModel.authorizationStatus == .notDetermined)
	}
	
	@Test func testPhotoGalleryViewModelAuthorizedState() async throws {
		// Given
		let mockService = MockPhotoLibraryService()
		mockService.authorizationStatus = .authorized
		let viewModel = PhotoGalleryViewModel(photoLibrary: mockService)
		
		// When
		viewModel.checkPermissions()
		
		// Wait for async operations to complete
		try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
		
		// Then
		#expect(viewModel.authorizationStatus == .authorized)
	}
	
	@Test func testPhotoGalleryViewModelDeniedState() async throws {
		// Given
		let mockService = MockPhotoLibraryService()
		mockService.authorizationStatus = .denied
		let viewModel = PhotoGalleryViewModel(photoLibrary: mockService)
		
		// When
		viewModel.checkPermissions()
		
		// Wait for async operations to complete
		try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
		
		// Then
		#expect(viewModel.authorizationStatus == .denied)
		#expect(viewModel.photos.isEmpty)
	}
	
	@Test func testPhotoGalleryViewModelLoadingPhotos() async throws {
		// Given
		let mockService = MockPhotoLibraryService()
		mockService.authorizationStatus = .authorized
		mockService.mockAssets = [MockPHAsset(identifier: "test-1")]
		let viewModel = PhotoGalleryViewModel(photoLibrary: mockService)
		
		// When
		viewModel.checkPermissions()
		
		// Wait for async operations to complete
		try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
		
		// Then
		#expect(viewModel.authorizationStatus == .authorized)
		#expect(!viewModel.photos.isEmpty)
		#expect(viewModel.photos.count == 1)
	}
}

class MockPHAsset: PHAsset {
	let mockIdentifier: String
	
	init(identifier: String) {
		self.mockIdentifier = identifier
		super.init()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var localIdentifier: String {
		return mockIdentifier
	}
}
