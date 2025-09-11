import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            NavigationLink("Go to SecondView", destination: SecondView())
                .padding()
        }
    }
}
