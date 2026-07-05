import Foundation
import UIKit

enum ImageError: LocalizedError {
    case invalidData
    case saveFailed(String)
    case readFailed

    var errorDescription: String? {
        switch self {
        case .invalidData: return "Los datos de la imagen no son válidos"
        case .saveFailed(let msg): return "Error al guardar la imagen: \(msg)"
        case .readFailed: return "Error al leer la imagen"
        }
    }
}

final class LocalImageService: ImageServiceProtocol {
    private let fileManager: FileManager
    private let imagesDir: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        imagesDir = appSupport.appendingPathComponent("Images", isDirectory: true)
        try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    }

    func prepareImageData(_ data: Data, mealLogId: UUID) async throws -> PreparedMealImage {
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }

        let filename = mealLogId.uuidString
        let fullURL = imagesDir.appendingPathComponent("\(filename).jpg")
        let thumbURL = imagesDir.appendingPathComponent("\(filename)_thumb.jpg")

        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.invalidData
        }
        try jpegData.write(to: fullURL)

        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnailImage = image.preparingThumbnail(of: thumbnailSize) ?? image
        guard let thumbData = thumbnailImage.jpegData(compressionQuality: 0.6) else {
            throw ImageError.invalidData
        }
        try thumbData.write(to: thumbURL)

        return PreparedMealImage(
            localPath: fullURL.path,
            thumbnailPath: thumbURL.path
        )
    }

    func loadImage(at path: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(at path: String) {
        try? fileManager.removeItem(at: URL(fileURLWithPath: path))
        let thumbPath = path.replacingOccurrences(of: ".jpg", with: "_thumb.jpg")
        try? fileManager.removeItem(at: URL(fileURLWithPath: thumbPath))
    }
}
