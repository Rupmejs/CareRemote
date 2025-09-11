//import SwiftUI

struct SecondView: View {
    @State private var counter = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Šis ir otrais ekrāns 🎉")
                .font(.largeTitle)

            Text("Skaitītājs: \(counter)")
                .font(.title2)

            Button(action: {
                counter += 1
            }) {
                Text("Pievienot +1")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                counter = 0
            }) {
                Text("Reset")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Otrais ekrāns")
    }
}

//  secondview.swift
//  xCare
//
//  Created by Kristaps on 11/09/2025.
//

