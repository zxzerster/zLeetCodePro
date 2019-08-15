//
//  Resource.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/12.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

// MARK: - Errors for whole app
enum APIError: Error, Equatable {
    case error(Error)
    case requestError(Int)
    case invalidResponse
    case invalidQuery
    case decode(Error)
    case parse
    case empty
    case badGraphQuery
    case interrupted
}

// MARK: - Resource definition
struct Resource<Type> {
    let request: URLRequest
    let parse: (Data, HTTPURLResponse) throws -> Type?
}

// MARK: - Resource general functionalities
extension Resource {
    init(get: URL, parse: @escaping
        (Data, HTTPURLResponse) throws -> Type?) {
        var request = URLRequest(url: get)
        request.httpMethod = "GET"
        
        self.request = request
        self.parse = parse
    }
    
    func map<NewType>(_ transform: @escaping (Type) -> NewType) -> Resource<NewType> {
        return Resource<NewType>(request: self.request) { (data, response) -> NewType? in
            let parsed = try? self.parse(data, response)
            return parsed.flatMap(transform)
        }
    }
    
    var combinable: combined<Type> {
        return .single(self)
    }
}

// MARK: - Resource for codable type
extension Resource where Type: Decodable {
    init(request: URLRequest) {
        self.request = request
        self.parse = { (data, response) -> Type? in
            guard response.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(Type.self, from: data)
        }
    }
    
    init(get: URL) {
        var request = URLRequest(url: get)
        request.httpMethod = "GET"
        
        self.request = request
        self.parse = { (data, response) -> Type? in
            guard response.statusCode == 200 else { return nil }
            return try? JSONDecoder().decode(Type.self, from: data)
        }
    }
    
//    init(graphQLRequest: URLRequest) {
//        self.request = graphQLRequest
//        self.parse = { (data, response) -> Type? in
//            guard response.statusCode == 200 else { return nil }
//            
//            let result = try? JSONDecoder().decode([String:[String: Type]].self, from: data)
//            return result["data"]?["userStatus"]
//        }
//    }
}

// MARK: - Wrapper for resources working in combination: next / retry / interrupted in next or retry
indirect enum combined<Type> {
    case single(Resource<Type>)
    case _interrupt(Result<Type, APIError>)
    case _next(combined<Any>, _ transform: (Any) -> combined<Type>)
    case _retry(combined<Type>, _ transform: (Type?) -> combined<Type>)
    
    var any: combined<Any> {
        switch self {
        case .single(let r): return .single(r.map { $0 })
        case ._interrupt(let r):
            switch r {
            case .failure(let error): return ._interrupt(.failure(error))
            case .success(let r): return ._interrupt(.success(r as Any))
            }
        case ._next(let c, let transform):
            return ._next(c) { (data) -> combined<Any> in
                transform(data).any
            }
        case ._retry(let c, let transform):
            return ._retry(c.any) { (data) -> combined<Any> in
                transform(data as? Type).any
            }
        }
    }
    
    func next<NewType>(_ transform: @escaping (Type) -> combined<NewType>) -> combined<NewType> {
        return ._next(self.any) { (data) -> combined<NewType> in
            transform(data as! Type)
        }
    }
    
    func retryable(_ transform: @escaping (Type) -> combined<Type>) -> combined<Type> {
        switch self {
        case .single:
            return ._retry(self) { (data) -> combined<Type> in
                guard let data = data else {
                    return combined.asInterrupt(.failure(.empty))
                }
                
                let c = transform(data)
                switch c {
                case .single: return c.retryable(transform)
                case ._interrupt: return c
                default:
                    fatalError("You can only transform data to combined.signle or using combined.asInterrupt to end retrying!")
                }
            }
        default:
            fatalError("Invalide combined resource type! Only combined.single can be retryable!")
        }
    }
    
    static func asInterrupt(_ obj: Result<Type, APIError>) -> combined<Type> {
        return combined._interrupt(obj)
    }
}

