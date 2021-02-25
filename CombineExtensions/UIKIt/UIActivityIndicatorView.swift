//
//  UIActivityIndicatorView.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2Soft. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UIActivityIndicatorView {

	var isAnimating: BindingTarget<Bool> {
		return makeBindingTarget { $1 ? $0.startAnimating() : $0.stopAnimating() }
	}
}
#endif
