//: Playground - noun: a place where people can play

import Cocoa

// Handy typealias for working with JSON
typealias JSON = AnyObject
typealias JSONArray = [JSON]
typealias JSONDictionary = [String: JSON]

enum JSONParseError: Error {
    /// Missing a required key while decoding
    case missingKey(String)
    
    /// Type mismatch on a value while decoding
    case valueTypeMismatch(String)
    
    /// Expecting a JSONDictionary but got something else (probably JSONArray or JSON)
    case expectedJSONDictionary
    
    /// Expecting a JSONArray but got something else (probably JSONDictionary or JSON)
    case expectedJSONArray
}

/// Conforming to this protocol enables gives access to convenient JSON parsing extensions
protocol ExpressibleByJSONDictionary {
    
    /// Init with JSONDictionary, throwing an error (likely JSONParseError) if the contents are invalid
    init(dictionary: JSONDictionary) throws
}

/// Extensions that provide bulk decoding and initing
extension ExpressibleByJSONDictionary {
    
    /// Creates an instance of `Self` where `data` contains a valid JSON representation of `Self`
    static func make(data: Data) throws -> Self {
        guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary else {
            throw JSONParseError.expectedJSONDictionary
        }
        
        return try Self.init(dictionary: object)
    }
    
    /// Creates instances of `Self` where `data` contains a valid JSON representation of an array of `Self`
    static func make(data: Data) throws -> [Self] {
        guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? [JSONDictionary] else {
            throw JSONParseError.expectedJSONArray
        }
        
        return try make(array: object)
    }
    
    /// Creates instances of `Self` where `array` contains valid JSON representations of `Self`
    static func make(array: [JSONDictionary]) throws -> [Self] {
        return try array.map { try Self.init(dictionary: $0) }
    }
}

/// Provides methods to decode values from a JSON dictionary that throw JSONParseError based on type
extension Dictionary where Key: ExpressibleByStringLiteral, Value: JSON {
    
    /// decode the value for `key` where `T` is not optional
    func decode<T>(_ key: Key) throws -> T {
        return try decodeNonOptionalValue(for: key)
    }
    
    /// decode the value for `key` where `T` can be optional. Being absent or NSNull is allowed
    func decode<T: ExpressibleByNilLiteral>(_ key: Key) throws -> T {
        let value = self[key]
        
        if value == nil {
            return nil
        } else {
            return try decodeNonOptionalValue(for: key)
        }
    }
    
    /// performs the work of decoding the value for `key` where `T` is not optional
    func decodeNonOptionalValue<T>(for key: Key) throws -> T {
        switch self[key] {
        case let value as T:
            return value
            
        case nil:
            throw JSONParseError.missingKey(String(describing: key))
            
        case .some:
            throw JSONParseError.valueTypeMismatch(String(describing: key))
        }
    }
}

// Example class conforming to our `ExpressibleByJSONDictionary` protocol
class Pokemon: ExpressibleByJSONDictionary {
    let name: String
    let id: Int
    let trainerId: Int?
    
    required init(dictionary: JSONDictionary) throws {
        
        // The decode methods will throw the correct error if the value for the given key
        // is either missing when required or the wrong type
        self.name = try dictionary.decode("name")
        self.id = try dictionary.decode("id")
        self.trainerId = try dictionary.decode("trainerId")
    }
}

// Let's create a Pokemon given a dictionary of JSON
do {
    let pikachu = try Pokemon(dictionary: ["name": "Pikachu" as NSString,
                                           "id": 25 as NSNumber,
                                           "trainerId": 0 as NSNumber])
} catch {
    print(error)
}
// No problems!


// We can leave out the "trainerId" key value pair because Pokemon's trainerId property is Optional
do {
    let pikachu = try Pokemon(dictionary: ["name": "Pikachu" as NSString,
                                           "id": 25 as NSNumber])
} catch {
    print(error)
}
// No problems!


// But if we leave out the required "id" field
do {
    let pikachu = try Pokemon(dictionary: ["name": "Pikachu" as NSString])
} catch {
    print(error)
}
// Missing key "id" is thrown


// If we use the wrong type for a property, say a string for id
do {
    let pikachu = try Pokemon(dictionary: ["name": "Pikachu" as NSString,
                                           "id": "25" as NSString,
                                           "trainerId": 0 as NSNumber])
} catch {
    print(error)
}
// value type mismatch "id" is thrown


// Sometimes we may want to import our objects in bulk from a JSON array
let pairOfPokemon: [JSONDictionary] = [
    ["name": "Pikachu" as NSString, "id": 25 as NSNumber],
    ["name": "Bulbasaur" as NSString, "id": 1 as NSNumber],
]

// Using our nice extensions it's really easy
do {
    let pokemon = try Pokemon.make(array: pairOfPokemon)
} catch {
    print(error)
}
// No problem!


// When working with URLSession we're getting back Data that we want to decode. Again
// using our nice extensions on ExpressibleByJSONDictionary, we don't have to do the
// JSON deserialization work ourselves
do {
    let pairOfPokemonData = try JSONSerialization.data(withJSONObject: pairOfPokemon, options: [])
    let pokemon: [Pokemon] = try Pokemon.make(data: pairOfPokemonData)
} catch {
    print(error)
}
// No problem!

