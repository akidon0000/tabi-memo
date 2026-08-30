import SwiftUI

struct SettingsView: View {
    @AppStorage("replayPacingStyle") private var pacingStyleRaw = ReplayPacingStyle.timeBased.rawValue

    private var pacingStyle: Binding<ReplayPacingStyle> {
        Binding(
            get: { ReplayPacingStyle(rawValue: pacingStyleRaw) ?? .timeBased },
            set: { pacingStyleRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("リプレイのペーシング", selection: pacingStyle) {
                    ForEach(ReplayPacingStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            } footer: {
                Text("トリップのリプレイでカメラが軌跡をなぞる速さの決め方。すべてのトリップに共通で適用されます。")
            }
        }
        .navigationTitle("設定")
    }
}
