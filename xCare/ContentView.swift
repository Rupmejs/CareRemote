import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Laipni lūdzam manā appā 🚀")
                    .font(.title)
                    .padding()

                NavigationLink(destination: secondview()) {
                    Text("Ej uz nākamo ekrānu ➡️")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Sākums")
        }
    }
}

