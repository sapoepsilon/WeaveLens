//
//  AdjustmentValueIndicatorView.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/18/24.
//
import SwiftUI

struct AdjustmentValueIndicator: View {
	@Binding var value: Double
	var screenWidth: CGFloat
	@State private var dragOffset: CGFloat = 0
	@State private var lastValue: Double = 0
	let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
	
	var body: some View {
		HStack(spacing: 5) {
			ForEach(0..<80) { index in
				Rectangle()
					.fill(index < Int((value + 0.5) * 80) ? Color.white : Color.gray)
					.frame(width: 1, height: index == 40 ? 12 : 8)
			}
		}
		.frame(width: screenWidth)
		.gesture(
			DragGesture(minimumDistance: 0)
				.onChanged { gesture in
					let delta = (gesture.translation.width - dragOffset) / screenWidth
					let newValue = min(max(lastValue + Double(delta), 0), 1)
					
					if abs(value - newValue) >= 0.0125 {
						feedbackGenerator.impactOccurred()
						value = newValue
					}
					
					dragOffset = gesture.translation.width
				}
				.onEnded { _ in
					lastValue = value
					dragOffset = 0
				}
		)
		.onAppear {
			lastValue = value
			feedbackGenerator.prepare()
		}
	}
}
