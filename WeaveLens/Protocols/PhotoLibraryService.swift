//
//  PhotoLibraryService.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/17/24.
//

import Photos

protocol PhotoLibraryService {
	func requestAuthorization(for level: PHAccessLevel) async -> PHAuthorizationStatus
	func fetchAssets() -> [PHAsset]
}
