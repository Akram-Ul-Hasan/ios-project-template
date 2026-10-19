import Testing

@testable import DesignSystem

@Suite("BadgeView")
@MainActor
struct BadgeViewTests {
    @Test("Hidden for nil or zero, capped at 99+")
    func display() {
        #expect(BadgeView.display(nil) == nil)
        #expect(BadgeView.display(0) == nil)
        #expect(BadgeView.display(5)?.value == 5)
        #expect(BadgeView.display(5)?.overflow == false)
        #expect(BadgeView.display(150)?.value == 99)
        #expect(BadgeView.display(150)?.overflow == true)
    }
}
