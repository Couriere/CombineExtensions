//
//  -=Combine Extensions=-
//
// MIT License
//
// Copyright (c) 2019-present Vladimir Kazantsev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
