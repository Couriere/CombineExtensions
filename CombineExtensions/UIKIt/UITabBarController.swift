//
//  UITabBarController.swift
//  ATV.TVOS
//
//  Created by Vladimir Kazantsev on 18.02.2020.
//  Copyright © 2020 MC2Soft. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UITabBarController {

	/// Sets the selected tab index.
	var selectedIndex: BindingTarget<Int> {
		return makeBindingTarget { $0.selectedIndex = $1 }
	}

	/// Sets the selected view controller.
	var selectedViewController: BindingTarget<UIViewController?> {
		return makeBindingTarget { $0.selectedViewController = $1 }
	}
}

extension UITabBarController: ReactiveExtensionsProvider {}
#endif
