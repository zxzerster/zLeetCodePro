//
//  User.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/15.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

struct User: Decodable {
    let signedIn: Bool
    let userName: String
    let realName: String
    
    enum CodingKeys: String, CodingKey {
        case signedIn = "isSignedIn"
        case userName = "username"
        case realName
    }
}

struct UserWrapper: Decodable {
    struct Data: Decodable {
        let userStatus: User
    }
    
    let data: Data
    
    var value: User {
        data.userStatus
    }
}

