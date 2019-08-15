//
//  Problem.swift
//  zLeetCodePro
//
//  Created by 周向真 on 2019/8/15.
//  Copyright © 2019 周向真. All rights reserved.
//

import Foundation

struct Problem: Decodable {
    let title: String
    let titleSlug: String
    let difficulty: String
    let questionId: String
    let status: String?
    let likes: Int
    let dislikes: Int
    let isPaidOnly: Bool
    let topicTags: [TopicTag]
}

struct TopicTag: Decodable {
    let name: String
    let id: String
    let slug: String
    let isEnabled: Bool
}

struct AllProblemsWrapper: Decodable {
    struct Data: Decodable {
        let allQuestions: [Problem]
    }
    
    let data: Data
    
    var value: [Problem] {
        data.allQuestions
    }
}
