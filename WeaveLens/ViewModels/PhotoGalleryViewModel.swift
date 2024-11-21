//
//  PhotoGalleryViewModel.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/17/24.
//
import SwiftUI
import Photos

class LivePhotoLibraryService: PhotoLibraryService {
	func requestAuthorization(for level: PHAccessLevel) async -> PHAuthorizationStatus {
		await withCheckedContinuation { continuation in
			PHPhotoLibrary.requestAuthorization(for: level) { status in
				continuation.resume(returning: status)
			}
		}
	}
	
	func fetchAssets() -> [PHAsset] {
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
		return assets.objects(at: IndexSet(0..<assets.count))
	}
}

@Observable
class PhotoGalleryViewModel {
	var photos: [PHAsset] = []
	var authorizationStatus: PHAuthorizationStatus = .notDetermined
	var gridColumns: Int = 4
	private let photoLibrary: PhotoLibraryService
	
	init(photoLibrary: PhotoLibraryService = LivePhotoLibraryService()) {
		self.photoLibrary = photoLibrary
	}
	
	func checkPermissions() {
		Task {
			let status = await photoLibrary.requestAuthorization(for: .readWrite)
			await MainActor.run {
				self.authorizationStatus = status
				if status == .authorized || status == .limited {
					self.photos = photoLibrary.fetchAssets()
				}
			}
		}
	}
	
	var columns: [GridItem] {
		Array(repeating: GridItem(.flexible(), spacing: 2), count: gridColumns)
	}
}
