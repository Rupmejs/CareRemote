import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var userType: String // "nanny" or "parent"
    var name: String
    var description: String
    var imageFileNames: [String]

    init(userType: String, name: String, description: String, imageFileNames: [String] = []) {
        self.id = UUID()
        self.userType = userType
        self.name = name
        self.description = description
        self.imageFileNames = imageFileNames
    }
}

