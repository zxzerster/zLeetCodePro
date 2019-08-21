//
//  LeetCodeService+Account.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/21.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

extension LeetCodeService {
    func login(name: String, password: String, completionHandler: @escaping (Result<Session, APIError>) -> Void) {
        let url = URL(string: base)!.appendingPathComponent("accounts/login/")
        let _get = Resource<String>(get: url) { (data, response) -> String? in
            guard let token = HTTPCookie.cookie(name: "csrftoken", from: response) else {
                throw APIError.invalidCredential
            }
            
            self.updateSession(withHeaders: ["X-csrftoken": token])
            
            return token
        }
        
        let login = _get.combinable.next { (token: String?) -> combined<Session> in
            guard let token = token else {
                return combined.asInterrupt(.failure(.invalidCredential))
            }
            
            let form = PostForm([
                "password": password, "login": name, "csrfmiddlewaretoken": token
            ])
            let request = URLRequest(url: url, form: form)!
            let _post = Resource<Session>(request: request) { (data, resp) -> Session? in
                guard resp.statusCode == 200 else {
                    throw APIError.invalidCredential
                }
                
                guard let token = HTTPCookieStorage.shared.cookie(name: self.TOKEN_KEY, for: url),
                    let session = HTTPCookieStorage.shared.cookie(name: self.SESSION_KEY, for: url) else {
                        throw APIError.invalidCredential
                }
                
                self.updateSession(withHeaders: ["X-csrftoken": token])
                return Session(token: token, session: session)
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
    
    func logout(completionHandler: ((Bool) -> Void)? = nil) {
        let url = URL(string: base)!.appendingPathComponent("accounts/logout/")
        let _get = Resource<Bool>(get: url) { (_, resp) -> Bool? in
            return resp.statusCode == 200
        }
        
        session.request(from: _get) { result in
            switch result {
            case .failure:
                completionHandler?(false)
            case .success(let loggedOut):
                HTTPCookieStorage.shared.deleteCookie(name: "csrftoken", for: url)
                HTTPCookieStorage.shared.deleteCookie(name: "LEETCODE_SESSION", for: url)
                completionHandler?(loggedOut)
            }
        }
    }
    
    func signup(name: String, password: String, email: String, completionHandler: @escaping (Result<Session, APIError>) -> Void) {
        let url = URL(string: base)!.appendingPathComponent("accounts/signup/")
        
        let _get = Resource<String>(get: url) { (data, response) -> String? in
            guard let token = HTTPCookie.cookie(name: "csrftoken", from: response) else {
                throw APIError.invalidCredential
            }
            
            self.updateSession(withHeaders: ["X-csrftoken": token])
            
            return token
        }
        
        let login = _get.combinable.next { (token: String?) -> combined<Session> in
            guard let token = token else {
                return combined.asInterrupt(.failure(.invalidResponse))
            }
            
            let form = PostForm([
                "csrfmiddlewaretoken": token, "username": name, "password1": password, "password2": password, "email": email
            ])
            let request = URLRequest(url: url, form: form)!
            let _post = Resource<Session>(request: request) { (data, resp) -> Session? in
                guard resp.statusCode == 200 else {
                    throw APIError.invalidResponse
                }
                
                guard let token = HTTPCookieStorage.shared.cookie(name: self.TOKEN_KEY, for: url),
                    let session = HTTPCookieStorage.shared.cookie(name: self.SESSION_KEY, for: url) else {
                        throw APIError.invalidCredential
                }
                
                self.updateSession(withHeaders: ["X-csrftoken": token])
                return Session(token: token, session: session)
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
