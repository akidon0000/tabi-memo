import SwiftUI

/// 見た目の案を切り替える画面。トリップ一覧の「…」から開く。
public struct AppearanceSettingsView: View {
    @AppStorage(AppearanceKey.tripListStyle) private var tripListStyle = TripListStyle.list
    @AppStorage(AppearanceKey.tripListOrder) private var tripListOrder = TripListOrder.newest
    @AppStorage(AppearanceKey.backButton) private var backButton = BackButtonPlacement.topLeading
    @AppStorage(AppearanceKey.addChoice) private var addChoice = AddChoiceStyle.actionSheet
    @AppStorage(AppearanceKey.shutter) private var shutter = ShutterStyle.classic
    @AppStorage(AppearanceKey.doneButton) private var doneButton = DoneButtonPlacement.bottomTrailing
    @AppStorage(AppearanceKey.captureCount) private var captureCount = CaptureCountStyle.thumbnail
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("トリップ一覧") {
                    Picker("見た目", selection: $tripListStyle) { options(TripListStyle.allCases, \.title) }
                    Picker("並び順", selection: $tripListOrder) { options(TripListOrder.allCases, \.title) }
                }
                Section("地図") {
                    Picker("一覧へ戻るボタン", selection: $backButton) { options(BackButtonPlacement.allCases, \.title) }
                    Picker("「+」を押したときの選び方", selection: $addChoice) { options(AddChoiceStyle.allCases, \.title) }
                }
                Section("カメラ") {
                    Picker("シャッター", selection: $shutter) { options(ShutterStyle.allCases, \.title) }
                    Picker("完了ボタン", selection: $doneButton) { options(DoneButtonPlacement.allCases, \.title) }
                    Picker("撮った枚数の見せ方", selection: $captureCount) { options(CaptureCountStyle.allCases, \.title) }
                }
            }
            .navigationTitle("見た目の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("完了") { dismiss() } }
            }
        }
    }

    private func options<Option: Identifiable & Hashable>(_ all: [Option], _ title: KeyPath<Option, String>) -> some View {
        ForEach(all) { Text($0[keyPath: title]).tag($0) }
    }
}
