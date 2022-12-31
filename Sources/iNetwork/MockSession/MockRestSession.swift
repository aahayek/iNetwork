//
//  MockRestSession.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import Combine


public final class MocKRestSession: RestURLSession {
    public static let mockRequestCompletion = "mockRequestCompletion"
    public static let httpHeaderFieldForMockCode = "mock_code"
    public func restDataTaskPublisher(for request: URLRequest) -> any RestDataPublisher {
        DataTaskPublisher(urlSession: self, request: request)
    }

    public init() { }

    class DataTaskSubsription<S: Subscriber>: Subscription where S.Failure == URLError, S.Input == (data: Data, response: URLResponse)  {
        private var urlSession: MocKRestSession!
        private var request: URLRequest!

        private var subscriber: S?

        init(urlSession: MocKRestSession, request: URLRequest, subscriber: S) {
            self.urlSession = urlSession
            self.request = request
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            guard request.value(forHTTPHeaderField: mockRequestCompletion) == nil else {
                subscriber?.receive(completion: .finished)
                return
            }
            guard let fileUrl = mockFile(from: request), fileUrl.isFileURL else {
                subscriber?.receive(completion: .failure(.init(.badURL)))
                return
            }
            
            /// open file
            _ = fileUrl.startAccessingSecurityScopedResource()
             
            /// close file at the end
             defer {
                 fileUrl.stopAccessingSecurityScopedResource()
             }
             
             do {
                 let code = getCodeFromRequest(request)
                 let data = Data(referencing: try NSData(contentsOf: fileUrl, options: .mappedIfSafe))
                 let urlResponse: URLResponse = HTTPURLResponse(url: fileUrl, statusCode: code,
                                                   httpVersion: request.httpMethod,
                                                                headerFields: request.allHTTPHeaderFields) ??
                     .init(url: fileUrl, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
                 _ = subscriber?.receive((data: data, response: urlResponse))
                 subscriber?.receive(completion: .finished)
    
             } catch {
                 subscriber?.receive(completion: .failure(.init(.cannotDecodeContentData)))
             }
        }
        
        func cancel() {
            subscriber = nil
            request = nil
            urlSession = nil
        }
    }

    public struct DataTaskPublisher: RestDataPublisher {
        private let urlSession: MocKRestSession
        private let request: URLRequest
        
        init(urlSession: MocKRestSession, request: URLRequest) {
            self.urlSession = urlSession
            self.request = request
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == URLError, S.Input == (data: Data, response: URLResponse) {
            subscriber.receive(subscription: DataTaskSubsription(urlSession: urlSession, request: request, subscriber: subscriber))
        }
    }
}

/// defaults to 200 when there's no mock_code field
private func getCodeFromRequest(_ request: URLRequest) -> Int {
    Int(request.value(forHTTPHeaderField: MocKRestSession.httpHeaderFieldForMockCode) ?? "200") ?? 200
}

func mockFile(from req: URLRequest) -> URL? {
    let code = getCodeFromRequest(req)
    let urlPath = req.url?.absoluteString.split(whereSeparator: { $0 == "/"})
    let fileName = urlPath?.joined(separator: "_") ?? ""
     
    guard let decumentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    return decumentDirectory.appendingPathExtension("mock_\(fileName)_\(code)")
}
