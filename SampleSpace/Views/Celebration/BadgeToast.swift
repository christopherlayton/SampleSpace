import SwiftUI

/// A banner for a badge earned mid-level (e.g. the first plot). Shows the oldest waiting badge
/// for a few seconds, then the next.
struct BadgeToast: View {
    @Environment(GameModel.self) private var model

    var body: some View {
        ZStack {
            if let badge = model.toasts.first {
                HStack(spacing: 12) {
                    BadgeIcon(badge: badge, earned: true, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Badge earned: \(badge.title)").font(.headline)
                        Text(badge.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThickMaterial, in: Capsule())
                .overlay(Capsule().stroke(Theme.gold.opacity(0.6)))
                .shadow(radius: 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .id(badge.id)
                .onTapGesture { dismiss() }
                .task(id: badge.id) {
                    try? await Task.sleep(for: .seconds(3.5))
                    dismiss()
                }
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.spring(duration: 0.4), value: model.toasts.first?.id)
        .padding(.bottom, 20)
    }

    private func dismiss() {
        if !model.toasts.isEmpty { model.toasts.removeFirst() }
    }
}
