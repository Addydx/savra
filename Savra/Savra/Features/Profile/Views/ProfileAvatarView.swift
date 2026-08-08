import SwiftUI

struct ProfileAvatarView: View {
    let name: String
    let photoPath: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let photoPath, let uiImage = UIImage(contentsOfFile: photoPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.accentColor.opacity(0.2)
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initials: String {
        let words = name.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "?" : result
    }
}
