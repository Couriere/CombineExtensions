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

	/// Sets the text of the text field.
	var text: BindingTarget<String?> {
		return makeBindingTarget { $0.text = $1 }
	}

	/// Sets the attributed text of the text field.
	var attributedText: BindingTarget<NSAttributedString?> {
		return makeBindingTarget { $0.attributedText = $1 }
	}

	/// Sets the textColor of the text field.
	var textColor: BindingTarget<UIColor> {
		return makeBindingTarget { $0.textColor = $1 }
	}
}
#endif
