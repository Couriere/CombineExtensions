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

	var isUserInteractionEnabled: BindingTarget<Bool> {
		return makeUIBindingTarget { $0.isUserInteractionEnabled = $1 }
	}

	var isHidden: BindingTarget<Bool> {
		return makeUIBindingTarget { $0.isHidden = $1 }
	}

	var alpha: BindingTarget<CGFloat> {
		return makeUIBindingTarget { $0.alpha = $1 }
	}
}
#endif
