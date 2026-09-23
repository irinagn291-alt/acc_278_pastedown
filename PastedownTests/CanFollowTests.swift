import XCTest
@testable import Pastedown

final class CanFollowTests: XCTestCase {
    func test_blankBoardAcceptsFreshCutting() {
        let next = Cutting(volumeID: VolumeID(), text: "A line.", page: 3, state: .fresh)
        XCTAssertTrue(CentoEngine.canFollow(foot: nil, next: next))
    }

    func test_sameVolumeIsRefused() {
        let volume = VolumeID()
        let foot = Cutting(volumeID: volume, text: "Foot.", page: 2, state: .pasted)
        let next = Cutting(volumeID: volume, text: "Clash.", page: 8, state: .fresh)
        XCTAssertFalse(CentoEngine.canFollow(foot: foot, next: next))
    }

    func test_otherVolumeIsAccepted() {
        let foot = Cutting(volumeID: VolumeID(), text: "Foot.", page: 2, state: .pasted)
        let next = Cutting(volumeID: VolumeID(), text: "Next.", page: 8, state: .fresh)
        XCTAssertTrue(CentoEngine.canFollow(foot: foot, next: next))
    }

    func test_spentIsRefusedEvenFromAnotherVolume() {
        let foot = Cutting(volumeID: VolumeID(), text: "Foot.", page: 2, state: .pasted)
        let next = Cutting(volumeID: VolumeID(), text: "Spent.", page: 8, state: .spent)
        XCTAssertFalse(CentoEngine.canFollow(foot: foot, next: next))
    }
}
