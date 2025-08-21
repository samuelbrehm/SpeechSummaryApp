//
//  TranscriptionDisplayView.swift
//  SpeechSummaryApp
//
//  Created by Samuel on 21/08/25.
//

import SwiftUI

struct TranscriptionDisplayView: View {
    let text: String
    let isRecording: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transcrição")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .opacity(0.8)
                            .scaleEffect(isRecording ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                        
                        Text("Gravando...")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            ScrollView {
                Text(text.isEmpty ? "Toque no botão para começar a gravar..." : text)
                    .font(.body)
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .frame(minHeight: 120, maxHeight: 200)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}