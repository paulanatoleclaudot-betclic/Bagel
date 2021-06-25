//
//  File.swift
//  
//
//  Created by pac on 23/06/2021.
//

import Foundation
import UIKit

extension NSObject {
    class func swizzleClassMethod(originClass: AnyClass?, originSelector: Selector, newClass: AnyClass?, newSelector: Selector) -> Void
    {
        guard let originClass = originClass, let newClass = newClass else { return }
        let originMethod: Method? = class_getClassMethod(originClass, originSelector);
        let newMethod: Method? = class_getClassMethod(newClass, newSelector);
        if let originMethod = originMethod, let newMethod = newMethod {
            method_exchangeImplementations(originMethod, newMethod)
        }
    }
}
