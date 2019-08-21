//
//  User.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/15.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

struct UserStatus: Decodable, QueryResponseValueKey {
    let isSignedIn: Bool
    let username: String
    let realName: String
    
    static var key: QueryResponseKey {
        QueryResponseKey(stringValue: "userStatus")!
    }
}

