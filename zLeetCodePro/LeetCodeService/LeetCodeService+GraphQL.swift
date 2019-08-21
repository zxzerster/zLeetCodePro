//
//  LeetCodeService+GraphQL.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/21.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

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
