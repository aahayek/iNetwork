//
//  RestSession.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import Combine

public protocol Interceptor {
    func intercept(chain: RestChain) -> RestChain

    func intercept(request: URLRequest, output: Data?, error: ServiceError?)
}
extension Interceptor {
    public func intercept(chain: RestChain) -> RestChain { chain }

    public func intercept(request: URLRequest, output: Data?, error: ServiceError?) { }
}

public protocol RestPerformer {
    func response(for req: URLRequest) -> AnyPublisher<Data, ServiceError>
    func response<T: Decodable>(for req: URLRequest) -> AnyPublisher<T, ServiceError>
    func addIntercapter(_ intercapter: any Interceptor)
}

public protocol RestChain {
    var urlSession: RestURLSession { get set }
    var urlRequest: URLRequest { get set }
}

public protocol RestDataPublisher: Publisher, Sendable where Output == (data: Data, response: URLResponse), Failure == URLError {
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == URLError, S.Input == (data: Data, response: URLResponse)
}

extension RestDataPublisher {
    func mapToDataAndServiceError() -> AnyPublisher<Data, ServiceError> {
        tryMap { data, response  in
            guard let httpResponse = response as? HTTPURLResponse else {
                 throw ServiceError.connectivityIssue(code: NSURLErrorNetworkConnectionLost)
            }

            guard httpResponse.statusCode != 403 else {
                throw ServiceError.accessError(code: 403)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw ServiceError.serverError(code: httpResponse.statusCode)
            }
            return data
        }
        .mapError { error -> ServiceError in
            switch error {
            case let serviceError as ServiceError:
                return serviceError
            default:
                return .connectivityIssue(code: NSURLErrorNetworkConnectionLost)
            }
        }
        .retry(3)
        .eraseToAnyPublisher()
    }
}

extension URLSession.DataTaskPublisher: RestDataPublisher {
    
}

public protocol RestURLSession: Sendable {
    func restDataTaskPublisher(for request: URLRequest) -> any RestDataPublisher
}

extension URLSession: RestURLSession {
    public func restDataTaskPublisher(for request: URLRequest) -> any RestDataPublisher {
        dataTaskPublisher(for: request)
    }
}
