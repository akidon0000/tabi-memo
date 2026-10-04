import Domain
import MapKit
import SwiftUI

/// 地図をタップして、写真の場所にピンを置く。最初は前後の写真の付近を映す。
struct LocationPinPicker: View {
    var onSelect: (Coordinate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pin: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition

    init(initialCenter: Coordinate, current: Coordinate?, onSelect: @escaping (Coordinate) -> Void) {
        self.onSelect = onSelect
        _pin = State(initialValue: current?.clLocationCoordinate)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: (current ?? initialCenter).clLocationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $position) {
                    if let pin { Marker("この場所", coordinate: pin) }
                }
                .mapStyle(.hybrid())
                .onTapGesture { point in
                    if let coordinate = proxy.convert(point, from: .local) { pin = coordinate }
                }
            }
            .navigationTitle("場所を指定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("決定") {
                        if let pin { onSelect(Coordinate(pin)) }
                        dismiss()
                    }
                    .disabled(pin == nil)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(pin == nil ? "地図をタップしてピンを置きます" : "ピンは置き直せます")
                    .font(.footnote)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.bottom, 8)
            }
        }
    }
}
