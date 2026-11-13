import Combine
import SwiftUI
import UIKit

/// Form layout: scrolling content + optional sticky bottom action.
/// Avoids `GeometryReader` (it was preventing IIEF-5 finger-scroll / clipping Q4–Q5).
struct KeyboardAvoidingFormScroll<Content: View, Action: View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var stickyAction: () -> Action

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            // Sticky footer (Save / Continue) — always visible below the scroll region.
            VStack(spacing: 0) {
                stickyAction()
            }
            .padding(.horizontal, BrandTheme.contentInset)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(BrandTheme.canvas.opacity(0.97))
        }
        // Lift scroll + sticky Save together when the keyboard is up (no GeometryReader).
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            keyboardHeight = Self.overlapHeight(from: note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                keyboardHeight = 0
            }
        }
    }

    private static func overlapHeight(from note: Notification) -> CGFloat {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else {
            return 0
        }
        let frameInWindow = window.convert(frame, from: nil)
        // Distance the keyboard covers from the bottom of the key window.
        return max(0, window.bounds.maxY - frameInWindow.minY - window.safeAreaInsets.bottom)
    }
}

extension KeyboardAvoidingFormScroll where Action == EmptyView {
    /// Content-only scroll (no sticky footer).
    init(@ViewBuilder content: @escaping () -> Content) {
        self.init(content: content, stickyAction: { EmptyView() })
    }
}

extension View {
    /// Marks the primary form action for keyboard-aware scroll-into-view (legacy id helper).
    func formPrimaryActionAnchor(_ id: String = "form-primary-action") -> some View {
        self.id(id)
    }
}
