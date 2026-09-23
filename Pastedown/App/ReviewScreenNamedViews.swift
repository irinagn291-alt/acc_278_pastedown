import SwiftUI

/// Role: App. Named SwiftUI screens for live-driver coverage discovery.
/// The shipping app stays UIKit-first; these names mirror section 3.6 keys.
struct CentoView: View {
    var body: some View { ReviewScreenNamePlate(title: "Cento") }
}

struct CuttingsView: View {
    var body: some View { ReviewScreenNamePlate(title: "Cuttings") }
}

struct VolumesView: View {
    var body: some View { ReviewScreenNamePlate(title: "Volumes") }
}

struct GatheringView: View {
    var body: some View { ReviewScreenNamePlate(title: "Gathering") }
}

struct SettingsView: View {
    var body: some View { ReviewScreenNamePlate(title: "Settings") }
}

struct SoldView: View {
    var body: some View { ReviewScreenNamePlate(title: "Sold") }
}

struct LentView: View {
    var body: some View { ReviewScreenNamePlate(title: "Lent") }
}

struct LostView: View {
    var body: some View { ReviewScreenNamePlate(title: "Lost") }
}

private struct ReviewScreenNamePlate: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(TypeScale.title)
                .foregroundStyle(Palette.ink)
        }
        .padding(Space.n(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
    }
}
