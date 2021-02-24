//
//  UITextField.swift

//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UITextField {

	/// Sets the text of the UITextField.
	var text: BindingTarget<String?> {
		return makeUIBindingTarget { $0.text = $1 }
	}

	/// Sets the attributed text of the UITextField.
	var attributedText: BindingTarget<NSAttributedString?> {
		return makeUIBindingTarget { $0.attributedText = $1 }
	}

	/// Sets the color of the text of the UITextField.
	var textColor: BindingTarget<UIColor> {
		return makeUIBindingTarget { $0.textColor = $1 }
	}
}
#endif
