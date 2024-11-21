//
//  PhotoEditorViewModel.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/17/24.
//
import Observation
import CoreImage
import UIKit
import Photos
import SwiftUI

@Observable
class PhotoEditorViewModel {
	private let context = CIContext()
	private var originalImage: UIImage?
	var editedImage: UIImage?
	private var adjustments: [AdjustmentType: Double] = [:]
	var isComparing: Bool = false
	
	func adjustmentBinding(for type: AdjustmentType) -> Binding<Double> {
		Binding(
			get: { self.adjustments[type] ?? 0 }, // Start with no adjustment
			set: { newValue in
				self.adjustments[type] = newValue
				self.applyAdjustments()
			}
		)
	}
	
	func toggleCompare() {
		isComparing.toggle()
	}
	
	func resetAdjustments() {
		adjustments.removeAll()
		applyAdjustments()
	}
	
	func resetSingleAdjustment(_ type: AdjustmentType) {
		adjustments.removeValue(forKey: type)
		applyAdjustments()
	}
	
	func loadImage(from asset: PHAsset) {
		let options = PHImageRequestOptions()
		options.deliveryMode = .highQualityFormat
		options.isNetworkAccessAllowed = true
		
		PHImageManager.default().requestImage(
			for: asset,
			targetSize: PHImageManagerMaximumSize,
			contentMode: .aspectFit,
			options: options
		) { [weak self] image, _ in
			guard let image = image else { return }
			DispatchQueue.main.async {
				self?.originalImage = image
				self?.editedImage = image
				self?.resetAdjustments()
			}
		}
	}
	
	private func applyAdjustments() {
		guard let originalImage = originalImage,
			  let ciImage = CIImage(image: originalImage) else { return }
		
		var currentImage = ciImage
		
		// Sort adjustments to ensure consistent ordering of filter application
		let sortedAdjustments = adjustments.sorted { $0.key.rawValue < $1.key.rawValue }
		
		for (adjustmentType, adjustment) in sortedAdjustments {
			currentImage = adjustmentType.apply(to: currentImage, adjustment: adjustment)
		}
		
		if let outputImage = context.createCGImage(currentImage, from: currentImage.extent) {
			editedImage = UIImage(cgImage: outputImage)
		}
	}
	
	func hasAdjustments() -> Bool {
		!adjustments.isEmpty
	}
	
	@MainActor
	func savePhoto() async {
		guard let editedImage = editedImage else { return }
		UIImageWriteToSavedPhotosAlbum(editedImage, nil, nil, nil)
		
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(.success)
	}
}

enum AdjustmentType: String, CaseIterable, Identifiable {
	case exposure
	case contrast
	case brightness
	case saturation
	case vibrance
	case highlights
	case shadows
	case sharpness
	case temperature
	case tint
	
	var id: String { rawValue }
	
	var name: String {
		rawValue.capitalized
	}
	
	var icon: String {
		switch self {
		case .exposure: return "sun.max.fill"
		case .contrast: return "circle.lefthalf.filled"
		case .brightness: return "brightness"
		case .saturation: return "paintpalette.fill"
		case .vibrance: return "wand.and.rays"
		case .highlights: return "sun.max"
		case .shadows: return "moon.fill"
		case .sharpness: return "diamond.fill"
		case .temperature: return "thermometer"
		case .tint: return "paintbrush.fill"
		}
	}
	
	var range: ClosedRange<Double> {
		switch self {
		case .exposure: return -2...2
		case .contrast: return -1...1.5
		case .brightness: return -1...1
		case .saturation: return 0...2
		case .vibrance: return -1...1
		case .highlights: return -1...1
		case .shadows: return -1...1
		case .sharpness: return 0...2
		case .temperature: return -1...1
		case .tint: return -1...1
		}
	}
	
	var step: Double {
		switch self {
		case .sharpness: return 0.05
		default: return 0.1
		}
	}
	
	func getCurrentValue(from image: CIImage) -> Double {
		// Extract current filter values from the image's properties
		if let properties = image.properties as? [String: Any] {
			switch self {
			case .exposure:
				return properties["inputEV"] as? Double ?? 0
			case .contrast:
				return properties["inputContrast"] as? Double ?? 1
			case .brightness:
				return properties["inputBrightness"] as? Double ?? 0
			case .saturation:
				return properties["inputSaturation"] as? Double ?? 1
			case .vibrance:
				return properties["inputAmount"] as? Double ?? 0
			case .highlights:
				return properties["inputHighlightAmount"] as? Double ?? 0
			case .shadows:
				return properties["inputShadowAmount"] as? Double ?? 0
			case .sharpness:
				return properties["inputSharpness"] as? Double ?? 0
			case .temperature:
				if let neutral = properties["inputNeutral"] as? CIVector {
					return (neutral.x - 6500)
				}
				return 0
			case .tint:
				if let neutral = properties["inputNeutral"] as? CIVector {
					return neutral.y 
				}
				return 0
			}
		}
		return 0
	}
	
	func apply(to image: CIImage, adjustment: Double) -> CIImage {
		let currentValue = getCurrentValue(from: image)
		let newValue = currentValue + adjustment
		
		// Clamp the new value to the allowed range
		let clampedValue = min(max(newValue, range.lowerBound), range.upperBound)
		
		switch self {
		case .exposure:
			return image.applyingFilter("CIExposureAdjust", parameters: ["inputEV": clampedValue])
		case .contrast:
			return image.applyingFilter("CIColorControls", parameters: ["inputContrast": clampedValue])
		case .brightness:
			return image.applyingFilter("CIColorControls", parameters: ["inputBrightness": clampedValue])
		case .saturation:
			return image.applyingFilter("CIColorControls", parameters: ["inputSaturation": clampedValue])
		case .vibrance:
			return image.applyingFilter("CIVibrance", parameters: ["inputAmount": clampedValue])
		case .highlights:
			return image.applyingFilter("CIHighlightShadowAdjust", parameters: ["inputHighlightAmount": clampedValue])
		case .shadows:
			return image.applyingFilter("CIHighlightShadowAdjust", parameters: ["inputShadowAmount": clampedValue])
		case .sharpness:
			return image.applyingFilter("CISharpenLuminance", parameters: ["inputSharpness": clampedValue])
		case .temperature:
			return image.applyingFilter("CITemperatureAndTint", parameters: [
				"inputNeutral": CIVector(x: 6500 + clampedValue * 1000, y: getCurrentValue(from: image) * 100)
			])
		case .tint:
			return image.applyingFilter("CITemperatureAndTint", parameters: [
				"inputNeutral": CIVector(x: 6500 + getCurrentValue(from: image) * 1000, y: clampedValue * 100)
			])
		}
	}
}
