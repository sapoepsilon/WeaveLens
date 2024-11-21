//
//  CarouselControlsView.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/18/24.
//

import SwiftUI

struct CarouselControls: View {
	@Binding var selectedAdjustment: AdjustmentType?
	
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 24) {
				ForEach(AdjustmentType.allCases) { adjustment in
					Button {
						withAnimation {
							if selectedAdjustment == adjustment {
								selectedAdjustment = nil
							} else {
								selectedAdjustment = adjustment
								let generator = UIImpactFeedbackGenerator(style: .medium)
								generator.impactOccurred()
							}
						}
					} label: {
						VStack(spacing: 8) {
							Circle()
								.strokeBorder(.gray, lineWidth: 1)
								.frame(width: 60, height: 60)
								.overlay {
									Image(systemName: adjustment.icon)
										.font(.system(size: 24))
										.foregroundColor(selectedAdjustment == adjustment ? .orange : .gray)
								}
							
							Text(adjustment.name)
								.font(.caption)
								.foregroundColor(selectedAdjustment == adjustment ? .orange : .white)
						}
					}
				}
			}
			.padding(.horizontal)
		}
		.frame(height: 100)
	}
}
