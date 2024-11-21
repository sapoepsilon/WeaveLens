//
//  ImageLoadingManager.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/20/24.
//

import SwiftUI
import Photos

actor ImageLoadingManager {
	private var activeRequests: [IndexPath: PHImageRequestID] = [:]
	
	func cancelRequest(for indexPath: IndexPath) {
		if let requestID = activeRequests[indexPath] {
			PHCachingImageManager.default().cancelImageRequest(requestID)
			activeRequests[indexPath] = nil
		}
	}
	
	func setRequest(_ requestID: PHImageRequestID, for indexPath: IndexPath) {
		activeRequests[indexPath] = requestID
	}
	
	func clearAllRequests() {
		activeRequests.forEach { PHCachingImageManager.default().cancelImageRequest($0.value) }
		activeRequests.removeAll()
	}
}
