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

import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension AnyPublisher {

	/// Creates `AnyPublisher` that immediately terminates with the specified error.
	public init( error: Failure ) {
		self.init( Fail( error: error ))
	}

	/// Creates AnyPublisher that emits an output to each subscriber just once, and then finishes.
	public init( value: Output ) {
		self.init( Just( value ).setFailureType( to: Failure.self ))
	}

	/// Creates AnyPublisher that never publishes any values, and optionally finishes immediately.
	public init( completeImmediately: Bool ) {
		self.init( Empty( completeImmediately: completeImmediately ))
	}

	/// Creates AnyPublisher that eventually produces a single value and then finishes or fails.
	public init( future attemptToFulfill: @escaping ( @escaping Future<Output, Failure>.Promise ) -> Void ) {
		self.init( Future( attemptToFulfill ))
	}
}
