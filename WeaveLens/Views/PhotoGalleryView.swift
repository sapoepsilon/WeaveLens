//
//  PhotoGalleryView.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/18/24.
//
import SwiftUI
import Photos

struct PhotoGalleryView: View {
	@State private var viewModel = PhotoGalleryViewModel()
	@State private var selectedAsset: PHAsset?
	
	var body: some View {
		NavigationStack {
			Group {
				switch viewModel.authorizationStatus {
				case .authorized, .limited:
					PhotoGridUIView(assets: viewModel.photos, selectedAsset: $selectedAsset)
						.ignoresSafeArea(.keyboard)
				case .denied, .restricted:
					PhotoAccessDeniedView()
				case .notDetermined:
					ProgressView()
				@unknown default:
					EmptyView()
				}
			}
			.navigationTitle("Photos")
			.navigationBarTitleDisplayMode(.inline)
		}
		.onAppear {
			viewModel.checkPermissions()
		}
		.onChange(of: selectedAsset) { asset in
			if let asset = asset {
				// Handle photo selection (e.g., navigate to editor)
				print("Selected asset: \(asset.localIdentifier)")
			}
		}
	}
}

// Update PhotoGalleryView to present the editor
extension PhotoGalleryView {
	private func presentEditor(for asset: PHAsset) {
		let editorView = PhotoEditorView(asset: asset)
		let hostingController = UIHostingController(rootView: editorView)
		hostingController.modalPresentationStyle = .fullScreen
		
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		   let window = windowScene.windows.first,
		   let rootViewController = window.rootViewController {
			rootViewController.present(hostingController, animated: true)
		}
	}
}
