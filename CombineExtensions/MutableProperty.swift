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

import Combine
import Foundation

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
@propertyWrapper
public class MutableProperty<Output> {

	public typealias Failure = Never

	public var value: Output {
		get { underlyingSubject.value }
		set { underlyingSubject.value = newValue }
	}

	public var wrappedValue: Output {
		get { underlyingSubject.value }
		set { underlyingSubject.value = newValue }
	}

	public var projectedValue: MutableProperty<Output> { self }

	public let underlyingSubject: CurrentValueSubject<Output, Never>

	public init( _ initialValue: Output ) {
		self.underlyingSubject = CurrentValueSubject( initialValue )
	}

	public convenience init( wrappedValue: Output ) {
		self.init( wrappedValue )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MutableProperty: BindingTargetProvider {

	public var bindingTarget: BindingTarget<Output> {
		return BindingTarget( lifetime: Lifetime.of( self )) { self.underlyingSubject.value = $0 }
	}
}
