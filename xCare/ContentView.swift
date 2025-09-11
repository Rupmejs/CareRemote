import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Sveiks iPhone lietotāj!") // Sveiciena teksts
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()

                NavigationLink(destination: SecondView()) {
                    Text("Ej uz nākamo ekrānu ➡️")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Sākums")
        }
    }
}

