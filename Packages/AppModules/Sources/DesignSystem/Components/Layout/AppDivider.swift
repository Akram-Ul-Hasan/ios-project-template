import SwiftUI

/// A hairline separator in the divider colour.
public struct AppDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: AppSize.borderWidth)
            .accessibilityHidden(true)
    }
}
