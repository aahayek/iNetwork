//
//  ResponseRecorderInterceptor.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import Combine

public struct ResponseRecorderInterceptor: Interceptor {
    public init() { }

    public func intercept(request: URLRequest, output: Data?, error: ServiceError?)  {
        guard let fileUrl = mockFile(from: request) else {
            logger.error("fielUrl not found from \(request.description)")
            return
        }
        do {
            try output?.write(to: fileUrl)
            if let error, let errorData = try? JSONEncoder().encode(error) {
                try errorData.write(to: fileUrl)
            }
            
        } catch {
            logger.error("failed to write to mockFile response with \(error.localizedDescription)")
        }
    }
}

public struct RequestReaderInterceptor: Interceptor {
    let urlSession: RestURLSession
    public init (urlSession: RestURLSession = MocKRestSession()) {
        self.urlSession = urlSession
    }

    public func intercept(chain: RestChain) -> RestChain {
        RestChainImpl(urlSession: self.urlSession, urlRequest: chain.urlRequest)
    }
}
