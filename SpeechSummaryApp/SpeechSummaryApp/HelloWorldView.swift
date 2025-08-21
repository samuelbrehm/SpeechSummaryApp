//
//  HelloWorldView.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import SwiftUI

struct HelloWorldView: View {
    @StateObject private var viewModel = HelloWorldViewModel()
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 32) {
                greetingCard
                interactionButton
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.3),
                Color.purple.opacity(0.2),
                Color.black.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var greetingCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(viewModel.isAnimating ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.isAnimating)
            
            Text(viewModel.greeting)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .opacity(viewModel.isAnimating ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAnimating)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.2),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var interactionButton: some View {
        Button(action: {
            viewModel.updateGreeting()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Change Greeting")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .scaleEffect(viewModel.isAnimating ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isAnimating)
    }
}

#Preview {
    HelloWorldView()
}