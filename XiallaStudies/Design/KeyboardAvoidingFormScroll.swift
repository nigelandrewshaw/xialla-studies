import Combine
import SwiftUI
import UIKit

/// Scroll form that lifts for the keyboard and scrolls the primary action (e.g. Save) into view.
/// Use for instrument sheets so long content (IIEF-5 × 5) and text editors never clip behind chrome/keyboard.
struct KeyboardAvoidingFormScroll<Content: View>: View {
    /// `ScrollViewReader` id on the primary button / bottom action.
    var actionAnchorId: String = "form-primary-action"
    @ViewBuilder var content: () -> Content

    @State private var keyboardOverlap: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Extra space so Save / Done clears the keyboard when scrolled to the anchor.
                        .padding(.bottom, max(keyboardOverlap, 32))
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
                    updateKeyboardOverlap(from: note, in: geo)
                    if keyboardOverlap > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(actionAnchorId, anchor: .bottom)
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        keyboardOverlap = 0
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func updateKeyboardOverlap(from note: Notification, in geo: GeometryProxy) {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        else {
            keyboardOverlap = 0
            return
        }

        let frameInWindow = window.convert(frame, from: nil)
        let viewFrame = geo.frame(in: .global)
        let overlap = max(0, viewFrame.maxY - frameInWindow.minY)
        withAnimation(.easeOut(duration: 0.25)) {
            keyboardOverlap = overlap
        }
    }
}

extension View {
    /// Marks the primary form action for keyboard-aware scroll-into-view.
    func formPrimaryActionAnchor(_ id: String = "form-primary-action") -> some View {
        self.id(id)
    }
}
