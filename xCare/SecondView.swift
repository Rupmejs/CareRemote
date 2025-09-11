import SwiftUI

struct SecondView: View {
    @State private var counter = 0 // skaitītājs

    var body: some View {
        VStack(spacing: 25) {
            Text("Šis ir otrais ekrāns 🎉")
                .font(.largeTitle)

            Text("Skaitītājs: \(counter)")
                .font(.title2)

            Button(action: { counter += 1 }) {
                Text("Pievienot +1")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: { counter = 0 }) {
                Text("Reset")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Otrais ekrāns")
    }
}

