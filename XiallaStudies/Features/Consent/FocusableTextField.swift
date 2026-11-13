import SwiftUI
import UIKit

/// UIKit-backed text field so Simulator / hardware keyboard focus is reliable.
struct FocusableTextField: UIViewRepresentable {
    enum Field: Hashable {
        case firstName
        case lastName
    }

    let placeholder: String
    @Binding var text: String
    var field: Field
    var focusedField: Binding<Field?>
    var textContentType: UITextContentType?
    var returnKeyType: UIReturnKeyType = .next
    var onSubmit: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.delegate = context.coordinator
        field.placeholder = placeholder
        field.text = text
        field.font = UIFont(name: BrandTheme.fieldworkRegularName, size: 16)
            ?? .systemFont(ofSize: 16)
        field.textColor = UIColor(BrandTheme.ink)
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.clearButtonMode = .whileEditing
        field.returnKeyType = returnKeyType
        field.textContentType = textContentType
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
        uiView.placeholder = placeholder
        uiView.returnKeyType = returnKeyType
        uiView.textContentType = textContentType

        let shouldFocus = focusedField.wrappedValue == field
        if shouldFocus, !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !shouldFocus, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusableTextField

        init(parent: FocusableTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.focusedField.wrappedValue = parent.field
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.focusedField.wrappedValue == parent.field {
                parent.focusedField.wrappedValue = nil
            }
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            let value = textField.text ?? ""
            if parent.text != value {
                parent.text = value
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit?()
            return true
        }
    }
}
