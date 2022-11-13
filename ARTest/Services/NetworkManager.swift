//
//  NetworkManager.swift
//  ARTest
//
//  Created by Vladimir Izmaylov on 13.11.2022.
//

import Foundation
import UIKit

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private init() {}
    
    func loadImageFrom(url: URL, completionHandler:@escaping(UIImage)->()) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        print("Image loaded");
                        completionHandler(image);
                    }
                }
            }
        }
    }
    
    
}
