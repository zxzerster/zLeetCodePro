//
//  LeetCodeService.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/12.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

class LeetCodeService {
    static let shared = LeetCodeService()
    
    let TOKEN_KEY = "csrftoken"
    let SESSION_KEY = "LEETCODE_SESSION"
    
    let base = "https://leetcode.com/"
    
    private var session: URLSession
    
    init() {
        let configuration = URLSession.shared.configuration
        configuration.httpAdditionalHeaders = [
            "Referer": base,
            "Origin": base,
            "X-Requested-With": "XMLHttpRequest",  // No redirect
        ]
        
        session = URLSession(configuration: configuration)
    }
    
    private func updateSession(withHeaders headers: [String: String]) {
        let newConfig = session.configuration
        for (key, value) in headers {
            newConfig.httpAdditionalHeaders?[key] = value
        }
        
        session = URLSession(configuration: newConfig)
    }
}

// MARK: - Leetcode: login related
extension LeetCodeService {
    func login(name: String, password: String, completionHandler: @escaping (Result<LeetCodeSession, APIError>) -> Void) {
        let url = URL(string: base)!.appendingPathComponent("accounts/login/")
        let _get = Resource<String>(get: url) { (_, response) -> String? in
            guard let token = HTTPCookie.cookie(name: "csrftoken", from: response) else {
                return nil
            }
            
            self.updateSession(withHeaders: ["X-csrftoken": token])
            
            return token
        }
        
        let login = _get.combinable.next { (token: String?) -> combined<LeetCodeSession> in
            guard let token = token else {
                return combined.asInterrupt(.failure(.invalidResponse))
            }
            
            let form = PostForm([
                "password": password, "login": name, "csrfmiddlewaretoken": token
            ])
            let request = URLRequest(url: url, form: form)!
            let _post = Resource<LeetCodeSession>(request: request) { (_, _) -> LeetCodeSession? in
                guard let token = HTTPCookieStorage.shared.cookie(name: self.TOKEN_KEY, for: url),
                    let session = HTTPCookieStorage.shared.cookie(name: self.SESSION_KEY, for: url) else {
                        return nil
                }
                
                self.updateSession(withHeaders: ["X-csrftoken": token])
                return LeetCodeSession(token: token, session: session)
            }
            
            return _post.combinable
        }
        
        session.request(from: login) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let r):
                completionHandler(.success(r))
            }
        }
    }
}

extension LeetCodeService {
    func graphQLQuery<Type: Decodable>(query: GraphQLObject, completionHandler: @escaping (Result<Type, APIError>) -> Void) {
        guard let request = URLRequest(graph: query) else {
            completionHandler(.failure(.invalidQuery))
            return
        }
        
        let resource = Resource<Type>(request: request)
        session.request(from: resource) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let r):
                completionHandler(.success(r))
            }
        }
    }
}
