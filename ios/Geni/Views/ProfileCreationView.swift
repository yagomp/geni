import SwiftUI

/// Creates a profile in three steps, or edits one on a single form when `editingProfile` is set.
struct ProfileCreationView: View {
    let onComplete: (ChildProfile) -> Void
    var existingNames: [String] = []
    var editingProfile: ChildProfile? = nil
    var onBack: (() -> Void)? = nil

    var body: some View {
        if let editingProfile {
            ProfileEditForm(profile: editingProfile, existingNames: existingNames, onComplete: onComplete, onBack: onBack)
        } else {
            ProfileOnboardingFlow(existingNames: existingNames, onComplete: onComplete, onBack: onBack)
        }
    }
}
