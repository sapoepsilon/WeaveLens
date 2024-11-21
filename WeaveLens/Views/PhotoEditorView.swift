//
//  PhotoEditorView.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/17/24.
//

import SwiftUI
import Photos

struct PhotoEditorView: View {
	let asset: PHAsset
	@Environment(\.dismiss) private var dismiss
	@State private var viewModel = PhotoEditorViewModel()
	@State private var selectedAdjustment: AdjustmentType?
	@State private var showingSaveDialog = false
	
	var body: some View {
		NavigationStack {
			GeometryReader { geometry in
				VStack(spacing: 20) {
					if let image = viewModel.editedImage {
						Image(uiImage: image)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(maxWidth: geometry.size.width)
					} else {
						ProgressView()
							.frame(height: geometry.size.height * 0.6)
					}
					
					CarouselControls(selectedAdjustment: $selectedAdjustment)
						.padding(.horizontal)
					
					if let adjustment = selectedAdjustment {
						AdjustmentSlider(
							adjustment: adjustment,
							value: viewModel.adjustmentBinding(for: adjustment)
						)
						.padding(.horizontal)
					}
					
					Spacer()
				}
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Cancel", role: .cancel) {
						dismiss()
					}
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Done") {
						showingSaveDialog = true
					}
				}
			}
			.navigationBarTitleDisplayMode(.inline)
		}
		.confirmationDialog(
			"Save Changes?",
			isPresented: $showingSaveDialog,
			titleVisibility: .visible
		) {
			Button("Save Changes") {
				Task {
					await viewModel.savePhoto()
					dismiss()
				}
			}
			Button("Discard Changes", role: .destructive) {
				dismiss()
			}
			Button("Cancel", role: .cancel) { }
		} message: {
			Text("Do you want to save the changes you made to this photo?")
		}
		.preferredColorScheme(.dark)
		.onAppear {
			viewModel.loadImage(from: asset)
		}
	}
}
struct AdjustmentSlider: View {
	let adjustment: AdjustmentType
	@Binding var value: Double
	
	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Text(adjustment.name)
					.foregroundStyle(.primary)
				Spacer()
				Text(value.formatted())
					.monospacedDigit()
					.foregroundStyle(.secondary)
			}
			
			Slider(
				value: $value,
				in: adjustment.range,
				step: adjustment.step
			) { changed in
				if changed {
					let generator = UISelectionFeedbackGenerator()
					generator.selectionChanged()
				}
			}
			.tint(.orange)
		}
	}
}

#Preview {
	PhotoEditorView(asset: PHAsset())
}
