//
//  ContentView.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 20/08/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SpeechRecognitionView(
            viewModel: SpeechRecognitionViewModel(
                useCase: SpeechRecognitionUseCase(
                    speechService: SpeechService()
                )
            )
        )
    }
}

#Preview {
    ContentView()
}
