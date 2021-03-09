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
