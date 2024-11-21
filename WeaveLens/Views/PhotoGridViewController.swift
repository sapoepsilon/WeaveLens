//
//  PhotoGridViewController.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/20/24.
//

import UIKit
import Photos

protocol PhotoGridViewControllerDelegate: AnyObject {
	func didSelectAsset(_ asset: PHAsset)
}

@MainActor
final class PhotoGridViewController: UIViewController {
	// MARK: - Properties
	weak var delegate: PhotoGridViewControllerDelegate?
	private var assets: [PHAsset]
	private var currentScale: CGFloat = 1.0
	private let minScale: CGFloat = 0.5
	private let maxScale: CGFloat = 2.0
	
	// Grid configuration
	private let defaultColumnsCount: CGFloat = 3
	private let cellSpacing: CGFloat = 0.5
	private var previousColumnCount: Int = 3
	
	// Zoom and scroll state
	private var initialPinchPoint: CGPoint?
	private var lastPinchCenter: CGPoint?
	private var lastPinchScale: CGFloat = 1.0
	private var isAdjustingAfterZoom = false
	
	// Image management
	private let imageManager = PHCachingImageManager()
	private var previousPreheatRect: CGRect = .zero
	private var thumbnailSize: CGSize = CGSize(width: 100, height: 100)
	private let imageLoadingManager = ImageLoadingManager()
	
	// Feedback generators
	private let selectionFeedback = UISelectionFeedbackGenerator()
	private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
	
	// MARK: - UI Components
	private lazy var collectionView: UICollectionView = {
		 let layout = UICollectionViewFlowLayout()
		 layout.minimumInteritemSpacing = cellSpacing
		 layout.minimumLineSpacing = cellSpacing
		 
		 let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
		 cv.backgroundColor = .clear
		 cv.isOpaque = true
		 cv.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
		 cv.delegate = self
		 cv.dataSource = self
		 cv.prefetchDataSource = self
		 cv.contentInsetAdjustmentBehavior = .never
		 cv.decelerationRate = .fast
		 cv.contentInset = .init(top: cellSpacing, left: cellSpacing, bottom: cellSpacing, right: cellSpacing)
		 return cv
	 }()
	 
	// MARK: - Initialization
	init(assets: [PHAsset]) {
		self.assets = assets
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		setupCollectionView()
		setupGestures()
		prepareImageManagement()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		updateLayout(with: currentScale)
		updateCachedAssets()
	}
	
	func updateAssets(_ newAssets: [PHAsset]) {
		assets = newAssets
		collectionView.reloadData()
	}
	
	private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
			if old.intersects(new) {
				var added = [CGRect]()
				if new.maxY > old.maxY {
					added.append(CGRect(x: new.origin.x,
									  y: old.maxY,
									  width: new.width,
									  height: new.maxY - old.maxY))
				}
				if old.minY > new.minY {
					added.append(CGRect(x: new.origin.x,
									  y: new.minY,
									  width: new.width,
									  height: old.minY - new.minY))
				}
				var removed = [CGRect]()
				if old.maxY > new.maxY {
					removed.append(CGRect(x: old.origin.x,
										y: new.maxY,
										width: old.width,
										height: old.maxY - new.maxY))
				}
				if new.minY > old.minY {
					removed.append(CGRect(x: old.origin.x,
										y: old.minY,
										width: old.width,
										height: new.minY - old.minY))
				}
				return (added, removed)
			} else {
				return ([new], [old])
			}
		}
	
	private func updateCachedAssets() {
		guard isViewLoaded && view.window != nil else { return }
		
		let visibleRect = CGRect(origin: collectionView.contentOffset,
								 size: collectionView.bounds.size)
		let preheatRect = visibleRect.insetBy(dx: -0.5 * visibleRect.width,
											  dy: -0.5 * visibleRect.height)
		
		let delta = abs(preheatRect.midY - previousPreheatRect.midY)
		guard delta > view.bounds.height / 3 else { return }
		
		let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
		
		let removedAssets = assets(in: removedRects)
		
		imageManager.stopCachingImages(for: removedAssets,
									   targetSize: thumbnailSize,
									   contentMode: .aspectFill,
									   options: nil)
		
		let addedAssets = assets(in: addedRects)
		imageManager.stopCachingImages(for: addedAssets,
									   targetSize: thumbnailSize,
									   contentMode: .aspectFill,
									   options: nil)
		
		previousPreheatRect = preheatRect
	}
	
	// MARK: - Setup Methods
	private func setupCollectionView() {
		view.addSubview(collectionView)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			collectionView.topAnchor.constraint(equalTo: view.topAnchor),
			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}
	
	private func setupGestures() {
		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
		pinchGesture.delegate = self
		collectionView.addGestureRecognizer(pinchGesture)
	}
	
	private func prepareImageManagement() {
		imageManager.stopCachingImagesForAllAssets()
		selectionFeedback.prepare()
		impactFeedback.prepare()
	}
	
	private func assets(in rects: [CGRect]) -> [PHAsset] {
		var visibleAssets = Set<PHAsset>()
		
		for rect in rects {
			let indexPaths = collectionView.indexPathsForElements(in: rect)
			for indexPath in indexPaths {
				if indexPath.item < assets.count {
					visibleAssets.insert(assets[indexPath.item])
				}
			}
		}
		
		return Array(visibleAssets)
	}
}

// MARK: - PhotoGridViewController+Layout.swift
extension PhotoGridViewController {
	@objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
		  let location = gesture.location(in: collectionView)
		  
		  switch gesture.state {
		  case .began:
			  initialPinchPoint = location
			  lastPinchCenter = location
			  lastPinchScale = currentScale
			  
		  case .changed:
			  guard let initialPinchPoint = initialPinchPoint else { return }
			  
			  // Calculate new scale
			  var newScale = lastPinchScale * gesture.scale
			  newScale = min(max(newScale, minScale), maxScale)
			  
			  // Calculate content offset adjustment
			  let pinchCenter = location
			  let offsetX = (pinchCenter.x - collectionView.bounds.midX)
			  let offsetY = (pinchCenter.y - collectionView.bounds.midY)
			  
			  // Update layout with new scale
			  updateLayout(with: newScale, animated: false)
			  
			  // Adjust content offset to maintain pinch center
			  let newContentOffset = CGPoint(
				  x: collectionView.contentOffset.x + offsetX * (gesture.scale - 1),
				  y: collectionView.contentOffset.y + offsetY * (gesture.scale - 1)
			  )
			  
			  collectionView.setContentOffset(newContentOffset, animated: false)
			  lastPinchCenter = pinchCenter
			  
		  case .ended, .cancelled:
			  let finalScale = snapToNearestColumnCount(scale: currentScale * gesture.scale)
			  updateLayout(with: finalScale, animated: true)
			  currentScale = finalScale
			  
			  // Reset zoom state
			  initialPinchPoint = nil
			  lastPinchCenter = nil
			  
			  // Reload visible cells with proper resolution
			  isAdjustingAfterZoom = true
			  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
				  self?.isAdjustingAfterZoom = false
				  self?.reloadVisibleCells()
				  self?.updateCachedAssets()
			  }
			  
		  default:
			  break
		  }
	  }
	
	private func snapToNearestColumnCount(scale: CGFloat) -> CGFloat {
		let baseColumns = defaultColumnsCount
		let currentColumns = baseColumns / scale
		let roundedColumns = round(currentColumns)
		return baseColumns / roundedColumns
	}
	

	// MARK: - Layout Updates
 private func updateLayout(with scale: CGFloat, animated: Bool = false) {
	 guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
	 
	 let availableWidth = view.bounds.width - (collectionView.contentInset.left + collectionView.contentInset.right)
	 let numberOfColumns = Int(round(defaultColumnsCount / scale))
	 let totalSpacing = cellSpacing * (CGFloat(numberOfColumns) - 1)
	 let itemWidth = (availableWidth - totalSpacing) / CGFloat(numberOfColumns)
	 
	 if numberOfColumns != previousColumnCount {
		 thumbnailSize = CGSize(
			 width: itemWidth * UIScreen.main.scale,
			 height: itemWidth * UIScreen.main.scale
		 )
		 
		 selectionFeedback.selectionChanged()
		 impactFeedback.impactOccurred(intensity: 0.7)
		 previousColumnCount = numberOfColumns
	 }
	 
	 layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
	 
	 if animated {
		 UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
			 layout.invalidateLayout()
			 self.collectionView.layoutIfNeeded()
		 }
	 } else {
		 layout.invalidateLayout()
	 }
 }
	
	private func reloadVisibleCells() {
		guard let visibleCells = collectionView.visibleCells as? [PhotoCell] else { return }
		let visibleIndexPaths = collectionView.indexPathsForVisibleItems
		
		for (cell, indexPath) in zip(visibleCells, visibleIndexPaths) {
			guard indexPath.item < assets.count else { continue }
			Task {
				await cell.configure(with: assets[indexPath.item],
									 imageManager: imageManager,
									 targetSize: thumbnailSize,
									 imageLoadingManager: imageLoadingManager)
			}
		}
	}
}

// MARK: - PhotoGridViewController+CollectionView.swift
extension PhotoGridViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return assets.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else {
			return UICollectionViewCell()
		}
		
		Task {
			await cell.configure(with: assets[indexPath.item],
								 imageManager: imageManager,
								 targetSize: thumbnailSize,
								 imageLoadingManager: imageLoadingManager)
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		delegate?.didSelectAsset(assets[indexPath.item])
	}
	
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		let assetsToCache = indexPaths.compactMap { indexPath -> PHAsset? in
			guard indexPath.item < assets.count else { return nil }
			return assets[indexPath.item]
		}
		
		imageManager.startCachingImages(for: assetsToCache,
										targetSize: thumbnailSize,
										contentMode: .aspectFill,
										options: nil)
	}
	
	func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		let assetsToStopCaching = indexPaths.compactMap { indexPath -> PHAsset? in
			guard indexPath.item < assets.count else { return nil }
			return assets[indexPath.item]
		}
		
		imageManager.stopCachingImages(for: assetsToStopCaching,
									   targetSize: thumbnailSize,
									   contentMode: .aspectFill,
									   options: nil)
	}
}

extension UICollectionView {
	func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
		let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) ?? []
		return allLayoutAttributes.map { $0.indexPath }
	}
}

// MARK: - UIGestureRecognizerDelegate
extension PhotoGridViewController: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
						  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		// Allow simultaneous pan and pinch gestures
		return true
	}
}

// MARK: - UICollectionViewDelegate
extension PhotoGridViewController: UIScrollViewDelegate {
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if !isAdjustingAfterZoom {
			reloadVisibleCells()
			updateCachedAssets()
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate && !isAdjustingAfterZoom {
			reloadVisibleCells()
			updateCachedAssets()
		}
	}
}
