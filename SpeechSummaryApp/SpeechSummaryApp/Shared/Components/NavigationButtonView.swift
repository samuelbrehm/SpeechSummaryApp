//
//  NavigationButtonView.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import SwiftUI

struct NavigationButtonView: View {
    let text: String
    let onSummarize: () -> Void
    
    init(text: String, onSummarize: @escaping () -> Void = {}) {
        self.text = text
        self.onSummarize = onSummarize
    }
    
    var body: some View {
        Button(action: onSummarize) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                
                Text("Resumir Texto")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.title2)
            }
            .padding()
            .foregroundColor(.white)
            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            .opacity(text.isEmpty ? 0.5 : 1.0)
        }
        .disabled(text.isEmpty)
        .accessibilityLabel("Resumir texto transcrito")
        .accessibilityHint("Navegar para a tela de resumo do texto")
    }
}