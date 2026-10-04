import CoreLocation
import SwiftData
import SwiftUI

/// 写真の日時・場所・タイトル・メモをまとめて編集するシート。追加するときの詳細入力と同じ項目。
struct EditPhotoView: View {
    @Bindable var photo: TripPhoto
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var takenAt: Date
    @State private var coordinate: CLLocationCoordinate2D
    @State private var isLocationManual: Bool
    @State private var title: String
    @State private var memo: String
    @State private var showLocationPicker = false

    init(photo: TripPhoto) {
        self.photo = photo
        _takenAt = State(initialValue: photo.takenAt)
        _coordinate = State(initialValue: photo.coordinate)
        _isLocationManual = State(initialValue: photo.isLocationManuallyPlaced)
        _title = State(initialValue: photo.title)
        _memo = State(initialValue: photo.memo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    photo.image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    DatePicker("日時", selection: $takenAt)
                    Button { showLocationPicker = true } label: {
                        HStack {
                            Label("場所", systemImage: "mappin.and.ellipse")
                            Spacer()
                            Text(isLocationManual ? "地図で指定済み" : "写真の位置情報")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Section("タイトル") {
                    TextField("タイトル", text: $title)
                }
                Section("メモ") {
                    TextField("メモを書く", text: $memo, axis: .vertical)
                        .lineLimit(4...)
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPinPicker(initialCenter: coordinate, current: coordinate) {
                    coordinate = $0
                    isLocationManual = true
                }
            }
        }
    }

    private func save() {
        photo.takenAt = takenAt
        photo.latitude = coordinate.latitude
        photo.longitude = coordinate.longitude
        photo.isLocationManuallyPlaced = isLocationManual
        photo.title = title
        photo.memo = memo
        try? modelContext.save()
        dismiss()
    }
}
