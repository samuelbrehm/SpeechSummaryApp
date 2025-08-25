//
//  BackgroundGradientView.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import SwiftUI

struct BackgroundGradientView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4),
                    Color.pink.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}