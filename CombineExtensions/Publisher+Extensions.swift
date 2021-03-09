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
public extension Publisher {

	/// Forward events from `self` with history: values of the returned signal
	/// are a tuples whose first member is the previous value and whose second member
	/// is the current value. `initial` is supplied as the first member when `self`
	/// sends its first value.
	///
	/// - parameters:
	///   - initial: A value that will be combined with the first value sent by
	///              `self`.
	///
	/// - returns: A signal that sends tuples that contain previous and current
	///            sent values of `self`.
	func combinePrevious( initial: Output ) ->  Publishers.Scan<Self, ( Output, Output )> {
		return self.scan( ( initial, initial ) ) { ( $0.1, $1 ) }
	}

	/// Attaches a subscriber with closure-based behavior.
	///
	/// Use ``Publisher/sink(receiveError:receiveValue:)`` to observe values received by the publisher and process them using a closure you specify.
	///
	/// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
	/// Completion.finished events are discarded.
	/// The return value should be held, otherwise the stream will be canceled.
	///
	/// - parameter receiveError: The closure to execute on error.
	/// - parameter receiveValue: The closure to execute on receipt of a value.
	/// - Returns: A cancellable instance, which you use when you end assignment of the received value. Deallocation of the result will tear down the subscription stream.
	func sinkReceiveError( _ receiveError: @escaping ((Self.Failure) -> Void), receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
		self.sink(
			receiveCompletion: {
				guard case .failure( let error ) = $0 else { return }
				receiveError( error )
			},
			receiveValue: receiveValue
		)
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publisher where Self.Failure == Never {
	/// Assigns each element from a Publisher to a property on an object.
	///
	/// - Parameters:
	///   - keyPath: The key path of the property to assign.
	///   - object: The object on which to assign the value.
	/// - returns: A cancellable instance; used when you end assignment of the received value.
	/// Deallocation of the result will tear down the subscription stream.
	/// - note: Unlike `assign(to:on:)` object captured weakly, allowing it to deallocate
	/// without needing to cancel cancellable instance.
	func assignUnretained<Root: AnyObject>( to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
												   on object: Root ) -> AnyCancellable {
		self.sink { [weak object] in object?[ keyPath: keyPath ] = $0 }
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	/// A publisher created by applying the zip function to an array of upstream publishers.
	struct Zip<Element, Failure: Error>: Publisher {
		public typealias Output = [ Element ]
		public typealias Failure = Failure

		private let upstreams: [ AnyPublisher<Element, Failure> ]

		public init( _ upstreams: [ AnyPublisher<Element, Failure> ] ) {
			self.upstreams = upstreams
		}

		public func receive<S: Subscriber>( subscriber: S ) where Self.Failure == S.Failure, Self.Output == S.Input {
			let initial = Just<[Element]>([])
				.setFailureType( to: Failure.self )
				.eraseToAnyPublisher()

			let zipped = upstreams
				.reduce( initial ) { result, upstream in
					result
						.zip( upstream ) { $0 + [ $1 ] }
						.eraseToAnyPublisher()
			}

			zipped.subscribe( subscriber )
		}
	}
}
