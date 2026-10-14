import Domain
import Foundation
import Observation
import SharedUI

/// トリップ一覧の状態。一覧に出すトリップと、削除したトリップを持ち、作成・名前変更・削除・復元を行う。
@MainActor
@Observable
public final class TripListViewModel {
    private(set) var trips: [Trip] = []
    private(set) var removedTrips: [Trip] = []
    /// 保存先から最初の値を受け取ったら true。それまでは「トリップがありません」を出さない。
    private(set) var hasLoaded = false

    private var hasPurged = false
    private let observeTrips: ObserveTripsUseCase
    private let createTrip: CreateTripUseCase
    private let renameTrip: RenameTripUseCase
    private let removeTrip: RemoveTripUseCase
    private let restoreTrip: RestoreTripUseCase
    private let deleteTripPermanently: DeleteTripPermanentlyUseCase
    private let purgeExpiredTrips: PurgeExpiredTripsUseCase

    public init(
        observeTrips: ObserveTripsUseCase,
        createTrip: CreateTripUseCase,
        renameTrip: RenameTripUseCase,
        removeTrip: RemoveTripUseCase,
        restoreTrip: RestoreTripUseCase,
        deleteTripPermanently: DeleteTripPermanentlyUseCase,
        purgeExpiredTrips: PurgeExpiredTripsUseCase
    ) {
        self.observeTrips = observeTrips
        self.createTrip = createTrip
        self.renameTrip = renameTrip
        self.removeTrip = removeTrip
        self.restoreTrip = restoreTrip
        self.deleteTripPermanently = deleteTripPermanently
        self.purgeExpiredTrips = purgeExpiredTrips
    }

    /// 画面が出ている間、一覧の最新の内容を受け取り続ける。最初の1回だけ、保持期間を過ぎた削除済みのトリップを消す。
    func start() async {
        for await (active, removed) in observeTrips.execute() {
            trips = active
            removedTrips = removed
            hasLoaded = true
            if !hasPurged {
                hasPurged = true
                try? purgeExpiredTrips.execute(in: removed)
            }
        }
    }

    /// 並び順に従った一覧。同じ値のときは、作った日の新しい順に並べる。
    func sortedTrips(_ order: TripListOrder) -> [Trip] {
        switch order {
        case .newest: trips.sorted { $0.startedAt > $1.startedAt }
        case .period: trips.sorted { ($0.period.upperBound, $0.startedAt) > ($1.period.upperBound, $1.startedAt) }
        case .name: trips.sorted { ($0.name, $1.startedAt) < ($1.name, $0.startedAt) }
        }
    }

    /// 新しいトリップを作る。作れたら、そのトリップの ID。
    func create(name: String) -> Trip.ID? {
        try? createTrip.execute(name: name)
    }

    func rename(_ trip: Trip, to name: String) {
        try? renameTrip.execute(tripID: trip.id, name: name)
    }

    func remove(_ trip: Trip) {
        try? removeTrip.execute(tripID: trip.id)
    }

    func restore(_ trip: Trip) {
        try? restoreTrip.execute(tripID: trip.id)
    }

    func deletePermanently(_ trip: Trip) {
        try? deleteTripPermanently.execute(tripID: trip.id)
    }
}
