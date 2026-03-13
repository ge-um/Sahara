//
//  Coordinator.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController? { get set }
    func start()
}
