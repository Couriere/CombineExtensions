//
//  UIView.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
extension UIView: ReactiveExtensionsProvider {}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UIView {

	/// Sets whether the view accepts user interactions.
	var isUserInteractionEnabled: BindingTarget<Bool> {
		return makeBindingTarget { $0.isUserInteractionEnabled = $1 }
	}

	/// Sets whether the view is hidden.
	var isHidden: BindingTarget<Bool> {
		return makeBindingTarget { $0.isHidden = $1 }
	}

	/// Sets the alpha value of the view.
	var alpha: BindingTarget<CGFloat> {
		return makeBindingTarget { $0.alpha = $1 }
	}

	/// Sets the background color of the view.
	var backgroundColor: BindingTarget<UIColor> {
		return makeBindingTarget { $0.backgroundColor = $1 }
	}

	/// Sets the tintColor of the view
	var tintColor: BindingTarget<UIColor> {
		return makeBindingTarget { $0.tintColor = $1 }
	}
}
#endif
