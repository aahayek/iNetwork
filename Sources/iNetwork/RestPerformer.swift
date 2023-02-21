//
//  RestPerformer.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import Combine

public struct RestChainImpl: RestChain {
    public var urlSession: RestURLSession
    public var urlRequest: URLRequest
}

public class RestPerformerImpl: RestPerformer {
    private let urlSession: RestURLSession
    private var interactors: [Interceptor]

    public init(urlSession: RestURLSession, interactor: [Interceptor] = []) {
        self.urlSession = urlSession
        self.interactors = interactor
    }

    public func addInteractor(_ interactor: any Interceptor) {
        interactors.append(interactor)
    }

    private func logError(_ error: DecodingError) {
        func contextString(_ context: DecodingError.Context) -> String {
            "\(context.debugDescription), at codingPath: \(context.codingPath)"
        }
        switch error {
        case .valueNotFound(let value, let context):
            logger.error("\(value)': value not found:, \(contextString(context))")
        case .keyNotFound(let key, let context):
            logger.error("\(key.stringValue)': key not found:, \(contextString(context))")
        case .dataCorrupted(let context):
            logger.error("Type 'Unknown' corrupted:, \(contextString(context))")
        case .typeMismatch(let type, let context):
            logger.error("Type '\(type)' mismatch:, \(contextString(context))")
        default:
            logger.error("Unhandled decode error path")
        }
    }

    public func response<T>(for endPoint: EndPoint) -> AnyPublisher<T, ServiceError> where T : Decodable {
        response(for: endPoint.request, using: endPoint.decoder)
    }
    
    public func response(for endPoint: EndPoint) -> AnyPublisher<Data, ServiceError> {
        response(for: endPoint.request)
    }

    public func response<T: Decodable>(for req: URLRequest) -> AnyPublisher<T, ServiceError> {
        response(for: req, using: JSONDecoder())
    }

    private func response<T>(for req: URLRequest, using decoder: JSONDecoder) -> AnyPublisher<T, ServiceError> where T: Decodable {
        response(for: req)
            .decode(type: T.self, decoder: decoder)
            .mapError { [weak self] anyError in
                switch anyError {
                case let serviceError as ServiceError:
                    return serviceError
                case let decodingError as DecodingError:
                    self?.logError(decodingError)
                    return .parseError(type: "Failed to retrieve data", code: NSURLErrorCannotDecodeRawData)
                default:
                    return .parseError(type: "\(anyError)", code: NSURLErrorCannotDecodeRawData)
                }
            }
            .eraseToAnyPublisher()
    }

    public func response(for req: URLRequest) -> AnyPublisher<Data, ServiceError> {
        let chain = interactors.reduce(RestChainImpl(urlSession: urlSession, urlRequest: req)) { partialResult, intercpter in
            intercpter.intercept(chain: partialResult)
        }
        return retryableResponse(for: chain)
    }

    private func retryableResponse(for request: RestChain) -> AnyPublisher<Data, ServiceError> {
        request.urlSession.restDataTaskPublisher(for: request.urlRequest)
            .mapToDataAndServiceError()
            .handleEvents(receiveOutput: { [weak self] data in
                self?.interactors.forEach {
                    $0.intercept(request: addCodeFieldToRequest(request.urlRequest, code: "200"), output: data, error: nil)
                }
            }, receiveCompletion: { [weak self] completion in
                if case let .failure(error)  = completion {
                    self?.interactors.forEach {
                        
                        $0.intercept(request: addCodeFieldToRequest(request.urlRequest, code: String(error.code)),
                                     output: nil, error: error)
                    }
                }
            })
            .eraseToAnyPublisher()
    }
}

private func addCodeFieldToRequest(_ request: URLRequest, code: String) -> URLRequest {
    var request = request
    request.addValue(MocKRestSession.httpHeaderFieldForMockCode, forHTTPHeaderField: code)
    return request
}

