import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    var selectionLimit: Int = 5
    let onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit
        let pc = PHPickerViewController(configuration: config)
        pc.delegate = context.coordinator
        return pc
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onComplete: onComplete)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        let onComplete: ([UIImage]) -> Void

        init(_ parent: PhotoPicker, onComplete: @escaping ([UIImage]) -> Void) {
            self.parent = parent
            self.onComplete = onComplete
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else {
                onComplete([])
                return
            }

            var images: [UIImage] = []
            let group = DispatchGroup()

            for res in results {
                group.enter()
                let item = res.itemProvider
                if item.canLoadObject(ofClass: UIImage.self) {
                    item.loadObject(ofClass: UIImage.self) { reading, _ in
                        defer { group.leave() }
                        if let image = reading as? UIImage {
                            images.append(image)
                        }
                    }
                } else {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.onComplete(images)
            }
        }
    }
}

