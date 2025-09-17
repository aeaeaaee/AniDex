import SwiftUI

struct AniDexScreen: View {
    @Binding var selectedTab: MenuTab

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("AniDex")
                    .font(.largeTitle.bold())

                Text("Your identified animals and plants will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
        }
    }
}

#Preview {
    AniDexScreen(selectedTab: .constant(.anidex))
}
