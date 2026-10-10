import SharedUI
import SwiftUI

/// 写真の日時・場所・タイトル・メモをまとめて編集するシート。追加するときの詳細入力と同じ項目。
public struct EditPhotoView: View {
    @State private var viewModel: EditPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showLocationPicker = false

    public init(viewModel: EditPhotoViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            form
                .navigationTitle("編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            viewModel.save()
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showLocationPicker) {
                    LocationPinPicker(
                        initialCenter: viewModel.edit.coordinate,
                        current: viewModel.edit.coordinate,
                        onSelect: viewModel.setLocation
                    )
                }
        }
    }

    private var form: some View {
        Form {
            Section {
                viewModel.photo.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                DatePicker("日時", selection: $viewModel.edit.takenAt)
                Button { showLocationPicker = true } label: {
                    HStack {
                        Label("場所", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text(viewModel.edit.isLocationManuallyPlaced ? "地図で指定済み" : "写真の位置情報")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            Section("タイトル") {
                TextField("タイトル", text: $viewModel.edit.title)
            }
            Section("メモ") {
                TextField("メモを書く", text: $viewModel.edit.memo, axis: .vertical)
                    .lineLimit(4...)
            }
        }
    }
}
