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

/// Type alias for CurrentValueSubjectProperty with Failure set to Never
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias MutableProperty<Output> = CurrentValueSubjectProperty<Output, Never>

/// A property wrapper for subject that wraps a single value and publishes a new element whenever the value changes.
/// Use CurrentValueSubject under the hood.
///
/// Unlike ``PassthroughSubject``, ``CurrentValueSubject`` maintains a buffer of the most recently published element.
///
/// Calling ``CurrentValueSubject/send(_:)`` on a ``CurrentValueSubject`` also updates the current value, making it equivalent to updating the ``CurrentValueSubject/value`` directly.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public final class CurrentValueSubjectProperty<Output, Failure> : Subject where Failure : Error {

	private let underlyingSubject: CurrentValueSubject<Output, Failure>

	/// The value wrapped by this subject, published as a new element whenever it changes.
	public var wrappedValue: Output {
		get { underlyingSubject.value }
		set { underlyingSubject.value = newValue }
	}

	public var projectedValue: CurrentValueSubject<Output, Failure> { underlyingSubject }

	/// The value wrapped by this subject, published as a new element whenever it changes.
	final public var value: Output {
		get { underlyingSubject.value }
		set { underlyingSubject.value = newValue }
	}

	/// Creates a current value subject with the given initial value.
	///
	/// - Parameter value: The initial value to publish.
	public init( _ value: Output ) {
		underlyingSubject = CurrentValueSubject( value )
	}

	public convenience init( wrappedValue: Output ) {
		self.init( wrappedValue )
	}

	/// Sends a subscription to the subscriber.
	///
	/// This call provides the ``Subject`` an opportunity to establish demand for any new upstream subscriptions.
	///
	/// - Parameter subscription: The subscription instance through which the subscriber can request elements.
	final public func send(subscription: Subscription) {
		underlyingSubject.send( subscription: subscription )
	}

	/// Attaches the specified subscriber to this publisher.
	///
	/// Implementations of ``Publisher`` must implement this method.
	///
	/// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
	///
	/// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
	final public func receive<S>(subscriber: S) where Output == S.Input, Failure == S.Failure, S : Subscriber {
		underlyingSubject.receive( subscriber: subscriber )
	}

	/// Sends a value to the subscriber.
	///
	/// - Parameter value: The value to send.
	final public func send(_ input: Output) {
		underlyingSubject.send( input )
	}

	/// Sends a completion signal to the subscriber.
	///
	/// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
	final public func send(completion: Subscribers.Completion<Failure>) {
		underlyingSubject.send( completion: completion )
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CurrentValueSubjectProperty: Equatable where Output: Equatable {
	public static func == (
		lhs: CurrentValueSubjectProperty<Output, Failure>,
		rhs: CurrentValueSubjectProperty<Output, Failure>
	) -> Bool {
		lhs.value == rhs.value
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CurrentValueSubjectProperty: Hashable where Output: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine( value )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CurrentValueSubjectProperty: Codable where Output: Codable {
	public convenience init(from decoder: Decoder) throws {
		self.init( try Output.init( from: decoder ))
	}

	public func encode(to encoder: Encoder) throws {
		try value.encode( to: encoder )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CurrentValueSubjectProperty: BindingTargetProvider {

	public var bindingTarget: BindingTarget<Output> {
		return BindingTarget( lifetime: Lifetime.of( self )) { [weak self] in self?.underlyingSubject.value = $0 }
	}
}
