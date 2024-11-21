//
//  PhotoDeniedAccessView.swift
//  WeaveLens
//
//  Created by Varkhuman Mac on 11/18/24.
//

import SwiftUI

struct PhotoAccessDeniedView: View {
	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "photo.fill")
				.font(.system(size: 60))
				.foregroundColor(.gray)
			
			Text("Photo Access Required")
				.font(.title2)
				.fontWeight(.bold)
			
			Text("Please allow access to your photos in Settings to use this feature.")
				.multilineTextAlignment(.center)
				.foregroundColor(.gray)
				.padding(.horizontal)
			
			Button("Open Settings") {
				if let url = URL(string: UIApplication.openSettingsURLString) {
					UIApplication.shared.open(url)
				}
			}
			.buttonStyle(.bordered)
		}
		.padding()
	}
}
