//
//  PhotoCell.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/20/24.
//
import UIKit
import Photos

final class PhotoCell: UICollectionViewCell {
	private let imageView: UIImageView = {
		let iv = UIImageView()
		iv.contentMode = .scaleAspectFill
		iv.clipsToBounds = true
		iv.layer.cornerRadius = 2
		iv.backgroundColor = .systemGray6
		return iv
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupImageView()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func setupImageView() {
		contentView.addSubview(imageView)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])
	}
	
	func configure(with asset: PHAsset,
				  imageManager: PHCachingImageManager,
				  targetSize: CGSize,
				  imageLoadingManager: ImageLoadingManager) async {
		
		// Load low quality image first
		let lowQualityOptions = PHImageRequestOptions()
		lowQualityOptions.deliveryMode = .fastFormat
		lowQualityOptions.isNetworkAccessAllowed = true
		
		let lowQualityImage = await loadImage(from: asset,
											targetSize: CGSize(width: 100, height: 100),
											options: lowQualityOptions,
											imageManager: imageManager)
		
		await MainActor.run {
			imageView.image = lowQualityImage
		}
		
		// Then load high quality image
		let highQualityOptions = PHImageRequestOptions()
		highQualityOptions.deliveryMode = .highQualityFormat
		highQualityOptions.isNetworkAccessAllowed = true
		
		let highQualityImage = await loadImage(from: asset,
											 targetSize: targetSize,
											 options: highQualityOptions,
											 imageManager: imageManager)
		
		await MainActor.run {
			UIView.transition(with: self.imageView,
							duration: 0.2,
							options: .transitionCrossDissolve) {
				self.imageView.image = highQualityImage
			}
		}
	}
	
	private func loadImage(from asset: PHAsset,
						 targetSize: CGSize,
						 options: PHImageRequestOptions,
						 imageManager: PHCachingImageManager) async -> UIImage? {
		await withCheckedContinuation { continuation in
			imageManager.requestImage(
				for: asset,
				targetSize: targetSize,
				contentMode: .aspectFill,
				options: options
			) { image, _ in
				continuation.resume(returning: image)
			}
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		imageView.image = nil
	}
}
