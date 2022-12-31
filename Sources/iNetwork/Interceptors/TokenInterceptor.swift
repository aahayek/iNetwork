//
//  TokenInterceptor.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import Combine

public let coreTokenAuthinticationKey = "core-token-authintication-key"

public class TokenInterceptor: Interceptor {
    @UserDefault<String>(key: coreTokenAuthinticationKey) private var token
    private var lastToken: String?
    private var cancellables = Set<AnyCancellable>()

    public static let authHttpField = "Authorization"

    public static func generateBearerWithToken(_ token: String) -> String {
        "Bearer \(token)"
    }

    public init() {
        lastToken = token
        $token.sink { [weak self] newToken in
            self?.lastToken = newToken
        }.store(in: &cancellables)
    }

    
    public func intercept(chain: RestChain) -> RestChain {
        guard let lastToken else { return chain}
        let bearerToken = Self.generateBearerWithToken(lastToken)
        var request = chain.urlRequest
        request.addValue(bearerToken, forHTTPHeaderField: TokenInterceptor.authHttpField)
        var newChain = chain
        newChain.urlRequest = request
        return newChain
    }
}
