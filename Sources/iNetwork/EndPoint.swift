//
//  EndPoint.swift
//  
//
//  Created by Ahmad Alhayek on 2/20/23.
//

import Foundation
public enum HttpMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case HEAD
    case COPY
    case LINK
}

public struct EndPoint {
    private let url: URL

    private var queries: [URLQueryItem]

    private var httpBody: Data?

    private var httpMethod: HttpMethod = .GET

    private var _decoder: JSONDecoder?
    var decoder: JSONDecoder {
        _decoder ?? JSONDecoder()
    }

    public init( url: URL, queries: [URLQueryItem] = [], body: Data? = nil) {
        self.url = url
        self.queries = queries
        self.httpBody = body
    }

    @discardableResult
    public mutating func add(_ query: URLQueryItem...) -> EndPoint {
        queries.append(contentsOf: query)
        return self
    }
   
    @discardableResult
    public mutating func body(_ data: Data) -> EndPoint {
        httpBody = data
        return self
    }

    @discardableResult
    public mutating func body(_ encodable: some Encodable) throws -> EndPoint {
        httpBody = try JSONEncoder().encode(encodable)
        return self
    }

    @discardableResult
    public mutating func body(_ any: Any) throws -> EndPoint {
        httpBody = try JSONSerialization.data(withJSONObject: any)
        return self
    }

    @discardableResult
    public mutating func method(_ method: HttpMethod) -> EndPoint {
        httpMethod = method
        return self
    }

    @discardableResult
    public mutating func decode(using decoder: JSONDecoder) -> EndPoint {
        self._decoder = decoder
        return self
    }

    var request: URLRequest {
        var url = url
        url.append(queryItems: queries)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = httpBody
        return urlRequest
    }
}
