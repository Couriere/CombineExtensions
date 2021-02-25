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

	/// Sets the placeholder text of the text field.
	var placeholder: BindingTarget<String?> {
		return makeBindingTarget { $0.placeholder = $1 }
	}

	/// Sets the textColor of the text field.
	var textColor: BindingTarget<UIColor> {
		return makeBindingTarget { $0.textColor = $1 }
	}


	/// A signal of text values emitted by the text field upon end of editing.
	///
	/// - note: To observe text values that change on all editing events,
	///   see `continuousTextValues`.
	var textValues: AnyPublisher<String, Never> {
		return mapControlEvents([.editingDidEnd, .editingDidEndOnExit]) { $0.text ?? "" }
	}

	/// A signal of text values emitted by the text field upon any changes.
	///
	/// - note: To observe text values only when editing ends, see `textValues`.
	var continuousTextValues: AnyPublisher<String, Never> {
		return mapControlEvents(.allEditingEvents) { $0.text ?? "" }
	}

	/// A signal of attributed text values emitted by the text field upon end of editing.
	///
	/// - note: To observe attributed text values that change on all editing events,
	///   see `continuousAttributedTextValues`.
	var attributedTextValues: AnyPublisher<NSAttributedString, Never> {
		return mapControlEvents([.editingDidEnd, .editingDidEndOnExit]) {
			$0.attributedText ?? NSAttributedString()
		}
	}

	/// A signal of attributed text values emitted by the text field upon any changes.
	///
	/// - note: To observe attributed text values only when editing ends, see `attributedTextValues`.
	var continuousAttributedTextValues: AnyPublisher<NSAttributedString, Never> {
		return mapControlEvents(.allEditingEvents) { $0.attributedText ?? NSAttributedString() }
	}
}
#endif
