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
public extension Reactive where Base: UIButton {

	/// Sets the title of the button for its normal state.
	var title: BindingTarget<String> {
		return makeBindingTarget { $0.setTitle( $1, for: .normal ) }
	}

	/// Sets the title of the button for the specified state.
	func title(for state: UIControl.State) -> BindingTarget<String> {
		return makeBindingTarget { $0.setTitle( $1, for: state ) }
	}

	/// Sets the attributed title of the button for the normal state.
	var attributedTitle: BindingTarget<NSAttributedString> {
		return makeBindingTarget { $0.setAttributedTitle( $1, for: .normal ) }
	}

	/// Sets the attributed title of the button for the specified state.
	func attributedTitle( for state: UIControl.State ) -> BindingTarget<NSAttributedString> {
		return makeBindingTarget { $0.setAttributedTitle( $1, for: state ) }
	}


	/// Sets the image of the button for the .normal state
	var image: BindingTarget<UIImage?> {
		return image( for: .normal )
	}

	/// Sets the image of the button for the specified state.
	func image(for state: UIControl.State) -> BindingTarget<UIImage?> {
		return makeBindingTarget { $0.setImage( $1, for: state ) }
	}

	/// Sets the background image of the button for the specified state.
	func backgroundImage( for state: UIControl.State ) -> BindingTarget<UIImage?> {
		return makeBindingTarget { $0.setBackgroundImage( $1, for: state ) }
	}
}
#endif
