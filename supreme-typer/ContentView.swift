//
//  ContentView.swift
//  s-type
//
//  Created by Afzal on 2/8/26.
//

import SwiftUI

struct ContentView: View {
    @State private var text = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("S-Type Keyboard Test")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Type something...", text: $text)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
