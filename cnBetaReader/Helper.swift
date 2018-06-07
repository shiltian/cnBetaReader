//
//  Helper.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2018/6/8.
//  Copyright © 2018 TSL. All rights reserved.
//

import UIKit

func presentAlertView(message: String, present: @escaping (_ viewControllerToPresent: UIViewController, _ flag: Bool, _ completion: (() -> Void)?)->Void) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    present(alert, true, nil)
}
