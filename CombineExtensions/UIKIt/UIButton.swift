//
//  UIButton.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UIButton {

	/// Sets the title of the button for its normal state.
	var title: BindingTarget<String> {
		return makeUIBindingTarget { $0.setTitle( $1, for: .normal ) }
	}

	/// Sets the title of the button for the specified state.
	func title(for state: UIControl.State) -> BindingTarget<String> {
		return makeUIBindingTarget { $0.setTitle( $1, for: state ) }
	}

	/// Sets the attributed title of the button for the normal state.
	var attributedTitle: BindingTarget<NSAttributedString> {
		return makeBindingTarget { $0.setAttributedTitle( $1, for: .normal ) }
	}

	/// Sets the attributed title of the button for the specified state.
	func attributedTitle( for state: UIControl.State ) -> BindingTarget<NSAttributedString> {
		return makeUIBindingTarget { $0.setAttributedTitle( $1, for: state ) }
	}


	/// Sets the image of the button for the .normal state
	var image: BindingTarget<UIImage?> {
		return image( for: .normal )
	}

	/// Sets the image of the button for the specified state.
	func image(for state: UIControl.State) -> BindingTarget<UIImage?> {
		return makeUIBindingTarget { $0.setImage( $1, for: state ) }
	}

	/// Sets the background image of the button for the specified state.
	func backgroundImage( for state: UIControl.State ) -> BindingTarget<UIImage?> {
		return makeUIBindingTarget { $0.setBackgroundImage( $1, for: state ) }
	}
}
#endif
