//
//  WithLatestPublisher.swift
//
//  Created by Vladimir Kazantsev on 20.12.2019.
//  Copyright © 2019 MC2 Software. All rights reserved.
//

import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publisher {

	/// Forward the latest value from `samplee` with the value from `self` as a
	/// tuple, only when `self` sends a `value` event.
	///
	/// - note: If `self` fires before a value has been observed on `samplee`,
	///         nothing happens.
	///
	/// - parameters:
	///   - samplee: A signal whose latest value is sampled by `self`.
	///   - transform: Closure that receive current values from both publishers
	///   and returns result of their transformation.
	///
	/// - returns: A signal that will send values from `self` and `samplee`,
	///            sampled (possibly multiple times) by `self`, then terminate
	///            once `self` has terminated. **`samplee`'s terminated and error events
	///            are ignored**.
	func withLatest<Samplee: Publisher, Result>( from samplee: Samplee,
											     transform: @escaping (Output, Samplee.Output) -> Result)
		-> Publishers.WithLatestFrom<Self, Samplee, Result> {
			return .init( signalPublisher: self, valuePublisher: samplee, transform: transform )
	}

	///  Upon an emission from self, emit the latest value from the
	///  second publisher, if any exists.
	///
	///  - parameter samplee: Second observable source.
	///
	///  - returns: A publisher containing the latest value from the second publisher, if any.
	func withLatest<Samplee: Publisher>( from samplee: Samplee )
		-> Publishers.WithLatestFrom<Self, Samplee, Samplee.Output> {
			return .init( signalPublisher: self, valuePublisher: samplee ) { $1 }
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	struct WithLatestFrom<SignalPublisher: Publisher, ValuePublisher: Publisher, Output>: Publisher {
		public typealias Failure = SignalPublisher.Failure
		public typealias Transform = (SignalPublisher.Output, ValuePublisher.Output) -> Output

		private let signalPublisher: SignalPublisher
		private let valuePublisher: ValuePublisher
		private let transform: Transform

		init( signalPublisher: SignalPublisher, valuePublisher: ValuePublisher, transform: @escaping Transform ) {
			self.signalPublisher = signalPublisher
			self.valuePublisher = valuePublisher
			self.transform = transform
		}

		public func receive<S: Subscriber>( subscriber: S ) where Output == S.Input, Failure == S.Failure  {
			let downstream = WithLatestSubscription( signalPublisher: signalPublisher,
													 valuePublisher: valuePublisher,
													 transform: transform,
													 subscriber: subscriber )
			subscriber.receive( subscription: downstream )
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Publishers.WithLatestFrom {

	private class WithLatestSubscription<S: Subscriber>: Combine.Subscription where S.Input == Output, S.Failure == Failure {

		init( signalPublisher: SignalPublisher,
			  valuePublisher: ValuePublisher,
			  transform: @escaping Transform,
			  subscriber: S ) {

			self.signalPublisher = signalPublisher
			self.valuePublisher = valuePublisher
			self.transform = transform
			self.subscriber = subscriber
		}

		func request( _ demand: Subscribers.Demand ) {
			if subscriptions.isEmpty {
				bindStreams()
			}
		}

		func cancel() {
			subscriptions.removeAll()
			subscriber = nil
		}

		/// Binds input publishers to downstream
		private func bindStreams() {

			subscriptions += valuePublisher.sink( receiveCompletion: { completion in
			}, receiveValue: {
				self.lastValue = $0
			})

			subscriptions += signalPublisher.sink( receiveCompletion: { completion in
				self.subscriber?.receive( completion: completion )
				self.subscriptions.removeAll()
			}, receiveValue: { signal in
				guard let lastValue = self.lastValue else { return }
				_ = self.subscriber?.receive( self.transform( signal, lastValue ) )
			})
		}

		private var lastValue: ValuePublisher.Output?

		private let signalPublisher: SignalPublisher
		private let valuePublisher: ValuePublisher
		private let transform: Transform
		private var subscriber: S?

		private var subscriptions: Set<AnyCancellable> = []
	}
}
