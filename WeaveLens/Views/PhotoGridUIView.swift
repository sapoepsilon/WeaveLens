//
//  PhotoGridUIView.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/20/24.
//

import SwiftUI
import Photos

struct PhotoGridUIView: UIViewControllerRepresentable {
	let assets: [PHAsset]
	@Binding var selectedAsset: PHAsset?
	
	func makeUIViewController(context: Context) -> PhotoGridViewController {
		let controller = PhotoGridViewController(assets: assets)
		controller.delegate = context.coordinator
		return controller
	}
	
	func updateUIViewController(_ uiViewController: PhotoGridViewController, context: Context) {
		Task { @MainActor in
			await uiViewController.updateAssets(assets)
		}
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
}

// MARK: - PhotoGridCoordinator.swift
extension PhotoGridUIView {
	class Coordinator: NSObject, PhotoGridViewControllerDelegate {
		var parent: PhotoGridUIView
		
		init(_ parent: PhotoGridUIView) {
			self.parent = parent
		}
		
		func didSelectAsset(_ asset: PHAsset) {
			Task { @MainActor in
				let editorView = PhotoEditorView(asset: asset)
				let hostingController = UIHostingController(rootView: editorView)
				hostingController.modalPresentationStyle = .fullScreen
				
				guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
					  let window = windowScene.windows.first,
					  let rootViewController = window.rootViewController else { return }
				
				rootViewController.present(hostingController, animated: true)
			}
		}
	}
}
