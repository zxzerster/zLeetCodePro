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
    
    internal var session: URLSession
    
    init() {
        let configuration = URLSession.shared.configuration
        configuration.httpAdditionalHeaders = [
            "Referer": base,
            "Origin": base,
            "X-Requested-With": "XMLHttpRequest",  // No redirect
        ]
        
        session = URLSession(configuration: configuration)
    }
    
    internal func updateSession(withHeaders headers: [String: String]) {
        let newConfig = session.configuration
        for (key, value) in headers {
            newConfig.httpAdditionalHeaders?[key] = value
        }
        
        session = URLSession(configuration: newConfig)
    }
}
