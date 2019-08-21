//
//  Resource+Utils.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/12.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

// MARK: - Request methods: GET / POST
enum requestMethod<Body> {
    case get
    case post(Body)
    
    var string: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
}

// MARK: - GraphQL query / mutation
struct GraphQLObject: Encodable {
    let operation: String = ""
    let variables: [String] = []
    let query: String
    
    func body() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

// MARK: - Util for contructing post form body
struct PostForm {
    private let boundary:String = {
        return "--zLeetcodeFormBoundary\(UUID().uuidString)"
    }()
    
    private let pairs: [String: Any]
    
    init(_ pairs: [String: Any]) {
        self.pairs = pairs
    }
    
    var data: Data? {
        var form = ""
        for (key, value) in pairs {
            let data = "\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)"
            form += data
        }
        form += "\r\n--\(boundary)--\r\n"

        return form.data(using: .utf8)
    }
    
    var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }
}

// MARK: - Shortcut for contructing kinds of Resource Request
extension URLRequest {
    // for post form
    init?(url: URL, form: PostForm) {
        guard let data = form.data else { return nil }
        
        self.init(url: url)
        
        httpMethod = "POST"
        httpBody = data
        addValue(form.contentType, forHTTPHeaderField: "Content-Type")
    }
    
    // for graphql query
    init?(graph: GraphQLObject) {
        guard let body = graph.body() else { return nil }
        
        self.init(url: URL(string: "https://leetcode.com/graphql/")!)
        
        httpMethod = "POST"
        httpBody = body
        addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}

// MAKR: - Equtable for APIError
func ==(l: APIError, r: APIError) -> Bool {
    switch (l, r) {
    case (.empty, .empty), (.decode, .decode), (.invalidResponse, .invalidResponse),
         (.badGraphQuery, .badGraphQuery), (.interrupted, .interrupted), (.invalidQuery, .invalidQuery),
         (.invalidCredential, .invalidCredential):
        return true
    case let (.requestError(n), .requestError(m)):
        return m == n
    case let (.error(e1), .error(e2)):
        return e1.localizedDescription == e2.localizedDescription
    default:
        return false
    }
}
