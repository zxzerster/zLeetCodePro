//
//  QueryResponse.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/20.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

protocol QueryResponseValueKey {
    static var key: QueryResponseKey { get }
}

struct QueryResponseKey: CodingKey {
    var stringValue: String
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        return nil
    }
    
    static let wrapper = QueryResponseKey(stringValue: "data")!
}

struct QueryResponse<Type>: Decodable where Type: Decodable & QueryResponseValueKey {
    let value: Type
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: QueryResponseKey.self)
        let nest = try container.nestedContainer(keyedBy: QueryResponseKey.self, forKey: .wrapper)
        
        value = try nest.decode(Type.self, forKey: Type.key)
    }
}
