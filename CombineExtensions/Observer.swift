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
public protocol Observer {
	/// The kind of values this observer sends.
	associatedtype Output

	/// The kind of errors this observer might send.
	///
	/// Use `Never` if this `Subscriber` cannot receive errors.
	associatedtype Failure : Error

	/// Sends a value to the subscriber.
	///
	/// - Parameter value: The value to send.
	func send( _ value: Output )

	/// Sends a completion signal to the subscriber.
	///
	/// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
	func send( completion: Subscribers.Completion<Failure>)
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Observer {

	/// Sends an error to the subscriber.
	public func send( _ error: Failure ) {
		send( completion: .failure( error ))
	}

	/// Sends a finished signal to the subscriber.
	public func sendFinished() {
		send( completion: .finished )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct AnyObserver<Output, Failure: Error>: Observer {

	private let sendValue: (Output) -> Void
	private let sendCompletion: (Subscribers.Completion<Failure>) -> Void

	public init(
		sendValue: @escaping (Output) -> Void,
		sendCompletion: @escaping (Subscribers.Completion<Failure>) -> Void
	) {
		self.sendValue = sendValue
		self.sendCompletion = sendCompletion
	}

	public func send( completion: Subscribers.Completion<Failure> ) {
		sendCompletion( completion )
	}

	public func send( _ value: Output ) {
		sendValue( value )
	}
}
