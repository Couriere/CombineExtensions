//
//  UIImageView.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UIImageView {
	/// Sets the image of the image view.
	var image: BindingTarget<UIImage?> {
		return makeBindingTarget { $0.image = $1 }
	}

	/// Sets the image of the image view for its highlighted state.
	var highlightedImage: BindingTarget<UIImage?> {
		return makeBindingTarget { $0.highlightedImage = $1 }
	}
}
#endif
