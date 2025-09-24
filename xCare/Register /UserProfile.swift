import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var userType: String   // "nanny" or "parent"
    var email: String
    var name: String
    var age: Int
    var description: String
    var imageFileNames: [String]

    init(userType: String, email: String, name: String, age: Int, description: String, imageFileNames: [String] = []) {
        self.id = UUID()
        self.userType = userType
        self.email = email
        self.name = name
        self.age = age
        self.description = description
        self.imageFileNames = imageFileNames
    }
}
