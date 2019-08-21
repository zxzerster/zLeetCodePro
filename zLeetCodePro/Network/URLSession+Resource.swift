//
//  URLSession+Resource.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/12.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

extension URLSession {
    func request<Type>(from resource: Resource<Type>, completionHandler: @escaping (Result<Type, APIError>) -> Void) {
        dataTask(with: resource.request) { (data, resp, error) in
            guard error == nil else {
                completionHandler(.failure(.error(error!)))
                return
            }
            
            guard let response = resp as? HTTPURLResponse else {
                completionHandler(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completionHandler(.failure(.empty))
                return
            }
            
            do {
                guard let parsed = try resource.parse(data, response) else {
                    completionHandler(.failure(.parse))
                    return
                }
                
                completionHandler(.success(parsed))
            } catch let error as APIError {
                completionHandler(.failure(error))
            } catch {
                fatalError("unexpected error: \(error)")
            }
        }.resume()
    }
    
    func request<Type>(from combinedResource: combined<Type>, completionHandler: @escaping (Result<Type, APIError>) -> Void) {
        switch combinedResource {
        case .single(let r): request(from: r, completionHandler: completionHandler)
        case ._interrupt(let r): completionHandler(r)
        case ._next(let c, let transform):
            request(from: c) { (result) in
                switch result {
                case .failure(let error): completionHandler(.failure(error))
                case .success(let data): self.request(from: transform(data), completionHandler: completionHandler)
                }
            }
        case ._retry(let c, let transform):
            request(from: c) { (result) in
                switch result {
                case .failure(let error): completionHandler(.failure(error))
                case .success(let data):self.request(from: transform(data), completionHandler: completionHandler)
                }
            }
        }
    }
}
