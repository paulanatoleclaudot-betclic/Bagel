//
//  File.swift
//  
//
//  Created by pac on 23/06/2021.
//

import Foundation

protocol BagelBaseModelProtocol {
    func toJSON() -> [String: Any]
    init(json: [String: Any])
}
