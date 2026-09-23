import Foundation

/// Role: App. Simulator-only demo payload. Yesterday already sealed a two-line cento,
/// today has a growing board, and one clash mark sits in the rail. Paste can still land.
enum DemoSeed {
    static let paperHoursID = VolumeID(fixed("11111111-1111-1111-1111-111111111111"))
    static let lentSpineID = VolumeID(fixed("22222222-2222-2222-2222-222222222222"))
    static let culledMarginID = VolumeID(fixed("33333333-3333-3333-3333-333333333333"))
    static let soldLightID = VolumeID(fixed("44444444-4444-4444-4444-444444444444"))

    static let boardCuttingID = CuttingID(fixed("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"))
    static let drawerLentID = CuttingID(fixed("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"))
    static let drawerCulledID = CuttingID(fixed("cccccccc-cccc-cccc-cccc-cccccccccccc"))
    static let drawerSoldID = CuttingID(fixed("dddddddd-dddd-dddd-dddd-dddddddddddd"))
    static let extraLentID = CuttingID(fixed("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"))
    static let sealedHoursID = CuttingID(fixed("aaaaaaaa-bbbb-cccc-dddd-aaaaaaaaaaaa"))
    static let sealedSpineID = CuttingID(fixed("bbbbbbbb-cccc-dddd-eeee-bbbbbbbbbbbb"))
    static let clashRefusedID = CuttingID(fixed("cccccccc-dddd-eeee-ffff-cccccccccccc"))
    static let clashMarkID = fixed("ffffffff-ffff-ffff-ffff-ffffffffffff")

    static func root(now: Date, calendar: Calendar) -> StoreRoot {
        let today = Daykey.of(now, calendar: calendar)
        let yesterday = today.previous(calendar: calendar) ?? today
        let goneDay = calendar.date(byAdding: .day, value: -12, to: now) ?? now
        let volumes = [
            Volume(
                id: paperHoursID,
                title: "Paper Hours",
                maker: "North Binding",
                isbn: "9780306406157",
                currentPage: 42,
                totalPages: 216,
                gone: GoneMark(reason: .sold, date: goneDay)
            ),
            Volume(
                id: lentSpineID,
                title: "The Lent Spine",
                maker: "Harbor Press",
                currentPage: 18,
                totalPages: 180
            ),
            Volume(
                id: culledMarginID,
                title: "Culled Margin",
                maker: "Kiln & Quire",
                currentPage: 64,
                totalPages: 240
            ),
            Volume(
                id: soldLightID,
                title: "Sold Light",
                maker: "Deckled House",
                currentPage: 9,
                totalPages: 128
            ),
        ]
        let cuttings = [
            Cutting(
                id: sealedHoursID,
                volumeID: paperHoursID,
                text: "A sold volume still leaves the line that outlived it.",
                page: 17,
                state: .spent,
                reread: false
            ),
            Cutting(
                id: sealedSpineID,
                volumeID: lentSpineID,
                text: "The shelf can forget. The cento keeps the sentence.",
                page: 44,
                state: .spent,
                reread: true
            ),
            Cutting(
                id: boardCuttingID,
                volumeID: paperHoursID,
                text: "The line outlives the binding that first held it.",
                page: 42,
                state: .pasted,
                reread: false
            ),
            Cutting(
                id: drawerLentID,
                volumeID: lentSpineID,
                text: "Keep the sentence. The shelf can go.",
                page: 18,
                state: .pasted,
                reread: false
            ),
            Cutting(
                id: drawerCulledID,
                volumeID: culledMarginID,
                text: "I cut the page I needed and let the rest travel on.",
                page: 64,
                state: .pasted,
                reread: false
            ),
            Cutting(
                id: extraLentID,
                volumeID: lentSpineID,
                text: "A borrowed copy still leaves a mark in the hand.",
                page: 91,
                state: .fresh,
                reread: true
            ),
            Cutting(
                id: drawerSoldID,
                volumeID: soldLightID,
                text: "Tomorrow the board is bare. Today it still takes a paste.",
                page: 9,
                state: .fresh,
                reread: false
            ),
            Cutting(
                id: clashRefusedID,
                volumeID: culledMarginID,
                text: "Two lines from one volume cannot sit together.",
                page: 88,
                state: .fresh,
                reread: false
            ),
        ]
        let sealed = Cento(
            daykey: yesterday,
            cuttingIDs: [sealedHoursID, sealedSpineID],
            seal: .sealed
        )
        let open = Cento(daykey: today, cuttingIDs: [boardCuttingID, drawerLentID, drawerCulledID], seal: .open)
        let clash = ClashMark(
            id: clashMarkID,
            daykey: today,
            refusedID: clashRefusedID,
            footID: drawerCulledID
        )
        return StoreRoot(
            schemaVersion: StoreCodec.currentSchema,
            volumes: volumes,
            cuttings: cuttings,
            centos: [open, sealed],
            clashMarks: [clash],
            latches: [
                VolumeLatch(
                    isbn: "9780306406157",
                    title: "Paper Hours",
                    maker: "North Binding",
                    pageCount: 216
                ),
            ],
            onboardingComplete: true
        )
    }

    /// Programmer constant. The UUID literal is fixed in this file.
    private static func fixed(_ string: String) -> UUID {
        guard let id = UUID(uuidString: string) else {
            preconditionFailure("DemoSeed UUID must be a valid literal.")
        }
        return id
    }
}
