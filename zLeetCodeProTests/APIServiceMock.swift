//
//  APIServiceMock.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/12.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

let resp = HTTPURLResponse()

class APIServiceMock {
    static let shared = APIServiceMock()

    init() { }

    func load<Type>(from resource: Resource<Type>, completionHandler: (Result<Type, APIError>) -> Void) {
        sleep(1)
        
        do {
            guard let parsed = try resource.parse(Data(), resp) else {
                completionHandler(.failure(APIError.empty))
                return
            }
            
            completionHandler(.success(parsed))
        } catch {
            completionHandler(.failure(.decode))
        }
    }

    func load<Type>(from combined: combined<Type>, completionHandler: (Result<Type, APIError>) -> Void) {
        switch combined {
        case ._interrupt(let r):
            switch r {
            case .failure(let err):
                completionHandler(.failure(err))
            case .success(let val):
                completionHandler(.success(val))
            }
        case .single(let r): load(from: r, completionHandler: completionHandler)
        case ._next(let c, let transform):
            load(from: c) { (result) in
                switch result {
                case .failure(let error): completionHandler(.failure(error))
                case .success(let data):
                    load(from: transform(data), completionHandler: completionHandler)
                }
            }
        case let ._retry(c, transform):
            load(from: c) { (result) in
                switch result {
                case let .failure(error):
                    completionHandler(.failure(error))
                case let .success(data):
                    load(from: transform(data), completionHandler: completionHandler)
                }
            }
        }
    }
}
