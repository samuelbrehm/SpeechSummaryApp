//
//  HelloWorldViewModel.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class HelloWorldViewModel: ObservableObject {
    @Published var greeting: String = "Hello, World!"
    @Published var isAnimating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupGreetingAnimation()
    }
    
    func updateGreeting() {
        withAnimation(.spring()) {
            isAnimating = true
            greeting = generateRandomGreeting()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                self.isAnimating = false
            }
        }
    }
    
    private func setupGreetingAnimation() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateGreeting()
            }
            .store(in: &cancellables)
    }
    
    private func generateRandomGreeting() -> String {
        let greetings = [
            "Hello, World!",
            "Olá, Mundo!",
            "Hola, Mundo!",
            "Bonjour, Monde!",
            "Hallo, Welt!",
            "こんにちは、世界！"
        ]
        return greetings.randomElement() ?? "Hello, World!"
    }
}
