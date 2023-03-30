//
//  File.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import Combine

@propertyWrapper
public struct UserDefault<Value: Codable> where Value: Equatable {
    public var wrappedValue: Value? {
        get {
            userDefault.value(forKey: key) ?? defaultValue
        }
        set {
            NotificationCenter.default.post(name: .init(key), object: newValue)
            userDefault.setValue(newValue, forKey: key)
        }
    }

    let key: String
    let defaultValue: Value?
    let userDefault: UserDefaults

    public init(key: String, defaultValue: Value? = nil, suitName: String? = nil) {
        self.defaultValue = defaultValue
        self.key = key
        userDefault = UserDefaults(suiteName: suitName) ?? UserDefaults.standard
       
    }
    
    public var projectedValue: AnyPublisher<Value?, Never> {
        NotificationCenter.default.publisher(for: .init(key))
            .map { notification in
                notification.object as? Value ?? defaultValue
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

public extension UserDefaults {
    func value<T: Decodable>(forKey key: String) -> T? {
        if let data = self.object(forKey: key) as? Data {
            let decoder = JSONDecoder()
            if let object = try? decoder.decode(T.self, from: data) {
                return object
            }
        }
        return nil
    }

    func setValue<T: Encodable>(_ value: T?, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            self.set(encoded, forKey: key)
        }
    }
}
