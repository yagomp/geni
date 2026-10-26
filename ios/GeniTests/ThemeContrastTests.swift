import SwiftUI
import Testing
@testable import Geni

struct ThemeContrastTests {
    @Test func saturatedFeedbackFillsUseWhiteText() {
        for fill in [GeniColor.green, GeniColor.blue, GeniColor.pinkDeep] {
            #expect(fill.readableText == .white)
        }
    }

    @Test func lightFeedbackAndSelectionFillsUseDarkText() {
        for fill in [Color.white, GeniColor.yellow, GeniColor.lightGray,
                     GeniColor.pink.soft(0.3), GeniColor.green.soft(0.15),
                     GeniColor.green.soft(0.3), GeniColor.yellow.soft(0.35)] {
            #expect(fill.readableText == GeniColor.border)
        }
    }
}
