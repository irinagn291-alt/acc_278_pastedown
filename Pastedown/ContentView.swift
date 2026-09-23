import SwiftUI

struct ContentView: View {
    var body: some View {
        CentoRootHost()
            .ignoresSafeArea()
    }
}

private struct CentoRootHost: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CentoRootViewController {
        CentoRootViewController()
    }

    func updateUIViewController(_ uiViewController: CentoRootViewController, context: Context) {}
}

#Preview {
    ContentView()
}
