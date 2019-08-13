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
    let base = "https://leetcode.com/"
    
    private var session: URLSession
    
    init() {
        let configuration = URLSession.shared.configuration
        configuration.httpAdditionalHeaders = [
            "Referer": base,
            "Origin": base,
            "X-Requested-With": "XMLHttpRequest",
        ]
        
        session = URLSession(configuration: configuration, delegate: SessionTaskDelegate.shared, delegateQueue: nil)
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
    func login(name: String, password: String, completionHandler: @escaping (Result<UserInfo, APIError>) -> Void) {
        let url = URL(string: base)!.appendingPathComponent("accounts/login/")
        let _get = Resource<(String?, Bool)>(get: url) { (_, response) -> (String?, Bool)? in
            if response.statusCode == 302 {
                return (nil, true)
            }
            
            guard let allHeadersFields = response.allHeaderFields as? [String: String] else {
                return (nil, false)
            }
            
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeadersFields, for: url)
            for cookie in cookies {
                if cookie.name == "csrftoken" {
                    let token = cookie.value
                    self.updateSession(withHeaders: ["X-csrftoken": token])
                    
                    return (token, false)
                }
            }
            
            return (nil, false)
        }
        
        let login = _get.combinable.next { (token, redirected) -> combined<UserInfo> in
            if redirected {
                // TODO: Handle redirect
                let userInfo = UserInfo(token: token, session: nil)
                return combined.asInterrupt(.success(userInfo))
            }
            
            guard let token = token else {
                return combined.asInterrupt(.failure(.empty))
            }
            
            let form = PostForm([
                "password": password, "login": name, "csrfmiddlewaretoken": token
            ])
            let request = URLRequest(url: url, form: form)!
            let _post = Resource<UserInfo>(request: request) { (_, _) -> UserInfo? in
                return self.readUserInfo(from: HTTPCookieStorage.shared.cookies(for: url))
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
    
    private func readUserInfo(from cookies: [HTTPCookie]?) -> UserInfo? {
        guard let cookies = cookies else { return nil }
        
        var token: String?, session: String?
        for c in cookies {
            if c.name == "csrftoken" {
                token = c.value
            }
            
            if c.name == "LEETCODE_SESSION" {
                session = c.value
            }
        }
        
        guard let t = token, let s = session else { return nil }
        
        return UserInfo(token: t, session: s)
    }
}

class SessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    static let shared = SessionTaskDelegate()
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
