//
//  HTTPCookieStorage+LeetCode.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/13.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

extension HTTPCookieStorage {
    func cookie(name: String, for url: URL) -> String? {
        guard let cookies = cookies(for: url) else { return nil }
        
        return cookies.filter { $0.name == name }.first?.value
    }
    
    func deleteCookie(name: String, for url: URL) {
        guard let cookies = cookies(for: url) else { return }
        
        let cookie = cookies.filter { $0.name == name }.first
        if let cookie = cookie {
            deleteCookie(cookie)
        }
    }
}

extension HTTPCookie {
    static func cookie(name: String, from response: HTTPURLResponse) -> String? {
        guard let allHeadersFields = response.allHeaderFields as? [String: String] else {
            return nil
        }
        
        guard let url = response.url else { return nil }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeadersFields, for: url)
        for cookie in cookies {
            if cookie.name == name {
                return cookie.value
            }
        }
        
        return nil
    }
}
