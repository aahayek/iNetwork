//
//  File.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import OSLog

public let logger = Logger()


public enum ServiceError: ErrorDisplayble {
    case connectivityIssue(code: Int) // The Internet connection appears to be offline.
    case serverError(code: Int)
    case accessError(code: Int)
    case unauthorized(code: Int)
    case parseError(type: String, code: Int)
    case anyServerError(ErrorInfo, code: Int)
    
    public var errorInfo: ErrorInfo {
        switch self {
        case .connectivityIssue:
            return .init(title: "The Internet connection appears to be offline", description: "Please try again at a later time")
        case .serverError:
            return .init(title: "Server Error", description: "Please try again")
        case .parseError(let type, _):
            return .init(title: "Failed to parse payload \(type)", description: "Please try again")
        case .accessError:
            return .init(title: "Doesn't have access", description: "Please try again")
        case .unauthorized:
            return .init(title: "unauthorized", description: "auth failuer")
        case .anyServerError(let error, _):
            return error
        }
    }
}

extension ServiceError: Codable {
    private var codingDecription: String {
        switch self {
        case .connectivityIssue:
            return "connectivityIssue"
        case .serverError:
            return "serverError"
        case .accessError:
            return "accessError"
        case .unauthorized:
            return "unauthorized"
        case .parseError:
            return "parseError"
        case .anyServerError:
            return "anyServerError"
        }
    }
    
    init?(_ val: String, code: Int, type: String?) {
        switch val {
        case "connectivityIssue":
            self = .connectivityIssue(code: code)
        case "serverError":
            self = .serverError(code: code)
        case "accessError":
            self = .accessError(code: code)
        case "parseError":
            self = .parseError(type: type ?? "no type", code: code)
        case "anyServerError":
            self = .anyServerError(.init(title: "Mock", description: "Description"), code: code)
        default:
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case errorType
        case code
        case type
    }
    
    var code: Int {
        switch self {
        case .connectivityIssue(let code):
            return code
        case .serverError(let code):
            return code
        case .accessError(let code):
            return code
        case .unauthorized(let code):
            return code
        case .parseError(_, let code):
            return code
        case .anyServerError(_, let code):
            return code
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .parseError(let type, let code):
            try container.encode(code, forKey: .code)
            try container.encode(type, forKey: .type)
        default:
            try container.encode(code, forKey: .code)
        }
        
        try container.encode(codingDecription, forKey: .errorType)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)
        let code = try container.decode(Int.self, forKey: .code)
        let decription = try container.decode(String.self, forKey: .errorType)
        
        self = .init(decription, code: code, type: type) ?? .parseError(type: "Faield to decode service error", code: 200)
    }
}

public protocol ErrorDisplayble: LocalizedError {
    var errorInfo: ErrorInfo { get }
}

public struct ErrorInfo {
    public let title: String
    public let description: String
    
    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}

extension ErrorDisplayble {
    public var errorDescription: String? {
        return NSLocalizedString(self.errorInfo.title, comment: self.errorInfo.description)
    }
}
