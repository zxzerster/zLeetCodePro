//
//  Querys.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/15.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

let USER_STATUS =
"""
    {
        userStatus {
            isSignedIn
            username
            realName
        }
    }
"""

let ALL_PROBLEMS =
"""
    {
        allQuestions {
            title
            titleSlug
            questionId
            difficulty
            status
            likes
            dislikes
            isPaidOnly
            topicTags {
                name
                id
                slug
                isEnabled
            }
        }
    }
"""
