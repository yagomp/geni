import SwiftUI

/// Home entry point (one profile). Kept for existing call sites; see `AvatarChooserSheet`.
struct AvatarPickerSheet: View {
    let viewModel: AppViewModel

    var body: some View {
        AvatarChooserSheet(viewModel: viewModel)
    }
}
