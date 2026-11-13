import PencilKit
import SwiftUI
import UIKit

/// Finger / Apple Pencil signature capture via PencilKit.
struct SignaturePadView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var inkColor: UIColor = UIColor(BrandTheme.ink)
    var onChanged: ((PKDrawing) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: 2.5)
        canvas.isScrollEnabled = false
        // Do not becomeFirstResponder here — that steals keyboard focus from name fields in Simulator.
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: 2.5)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignaturePadView

        init(parent: SignaturePadView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onChanged?(canvasView.drawing)
        }
    }
}

extension PKDrawing {
    var hasInk: Bool { !strokes.isEmpty }

    /// Renders the signature into a PNG suitable for local consent storage.
    func pngData(padSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> Data? {
        let bounds = CGRect(origin: .zero, size: padSize)
        let image = image(from: bounds, scale: scale)
        return image.pngData()
    }
}
