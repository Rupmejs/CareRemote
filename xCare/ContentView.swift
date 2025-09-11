import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Sveiks iPhone lietotāj!")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()

                NavigationLink(destination: SecondView()) {
                    Text("Ej uz To-Do listu ➡️")
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

#Preview {
    ContentView()
}
