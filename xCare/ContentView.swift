import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("neesi lohs!")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()

                NavigationLink(destination: SecondView()) {
                    Text("IRPRIEKTDIENA ➡️")
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
