//
//  UIColor.swift
//  ARTest
//
//  Created by Vladimir Izmaylov on 07.11.2022.
//

import UIKit

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1
        )
    }
}
