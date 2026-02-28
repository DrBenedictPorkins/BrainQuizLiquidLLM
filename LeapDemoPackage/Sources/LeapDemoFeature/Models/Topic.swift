import Foundation

struct Topic: Identifiable, Hashable, Sendable {
    let id: UUID
    let displayName: String
    let emoji: String
    let subcategories: [Subcategory]

    struct Subcategory: Identifiable, Hashable, Sendable {
        let id: UUID
        let displayName: String

        init(displayName: String) {
            self.id = UUID()
            self.displayName = displayName
        }
    }

    init(displayName: String, emoji: String, subcategories: [String]) {
        self.id = UUID()
        self.displayName = displayName
        self.emoji = emoji
        self.subcategories = subcategories.map { Subcategory(displayName: $0) }
    }
}

enum TopicSelection: Equatable, Sendable {
    case preset(topic: Topic, subcategory: Topic.Subcategory?)
    case custom(String)
    case random

    var promptString: String {
        switch self {
        case .preset(let topic, let sub):
            if let sub {
                return "\(sub.displayName) (\(topic.displayName))"
            }
            return topic.displayName
        case .custom(let text):
            return text
        case .random:
            return "a surprising mix of random topics — pick anything interesting across science, history, culture, nature, or pop culture"
        }
    }
}

extension Topic {
    static let presets: [Topic] = [
        Topic(displayName: "History", emoji: "🏛️", subcategories: [
            "All History", "Ancient Civilizations", "World Wars", "American History", "European History", "Asian History"
        ]),
        Topic(displayName: "Science", emoji: "🔬", subcategories: [
            "All Science", "Biology", "Chemistry", "Physics", "Earth Science", "Human Body"
        ]),
        Topic(displayName: "Geography", emoji: "🌍", subcategories: [
            "All Geography", "Countries & Capitals", "Flags", "Mountains & Rivers", "US States", "World Landmarks"
        ]),
        Topic(displayName: "Math", emoji: "➗", subcategories: [
            "All Math", "Arithmetic", "Geometry", "Algebra", "Famous Mathematicians", "Math in Nature"
        ]),
        Topic(displayName: "Literature", emoji: "📚", subcategories: [
            "All Literature", "Classic Novels", "Poetry", "Shakespeare", "Mythology", "Children's Books"
        ]),
        Topic(displayName: "Sports", emoji: "⚽", subcategories: [
            "All Sports", "Football", "Basketball", "Soccer", "Olympics", "Tennis", "Formula 1"
        ]),
        Topic(displayName: "Animals", emoji: "🦁", subcategories: [
            "All Animals", "Mammals", "Ocean Life", "Birds", "Insects", "Endangered Species"
        ]),
        Topic(displayName: "Space", emoji: "🚀", subcategories: [
            "All Space", "Solar System", "Famous Astronauts", "Space Missions", "Stars & Galaxies", "Black Holes"
        ]),
        Topic(displayName: "Food & Cooking", emoji: "🍳", subcategories: [
            "All Food & Cooking", "World Cuisines", "Ingredients", "Famous Chefs", "Baking", "Street Food"
        ]),
        Topic(displayName: "Movies & TV", emoji: "🎬", subcategories: [
            "All Movies & TV", "Action & Adventure", "Sci-Fi", "Horror", "Comedy", "Animation",
            "Christopher Nolan", "Marvel / MCU", "Star Wars", "James Bond", "Harry Potter",
            "80s Classics", "90s Movies", "Sitcoms", "Animated Shows"
        ]),
        Topic(displayName: "Music", emoji: "🎵", subcategories: [
            "All Music", "Rock", "Pop", "Classical", "Hip Hop", "Famous Artists", "Music Theory"
        ]),
        Topic(displayName: "Technology", emoji: "💻", subcategories: [
            "All Technology", "Inventions", "Programming", "Artificial Intelligence", "Social Media", "Video Games"
        ]),
    ]
}
