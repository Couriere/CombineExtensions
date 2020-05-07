//
//  AnyPublisher+Closure.swift
//
//  Created by Vladimir Kazantsev on 05.02.2020.
//  Copyright © 2020 MC2Soft. All rights reserved.
//

import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension AnyPublisher {

	init( _ closure: @escaping ( AnySubscriber<Output, Failure>, Lifetime ) -> Void ) {
		let publisher = Publishers.ClosurePublisher( closure: closure )
		self.init( publisher )
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	struct ClosurePublisher<Output, Failure>: Publisher where Failure: Error {

		public typealias InitClosure = ( AnySubscriber<Output, Failure>, Lifetime ) -> Void

		private let closure: InitClosure

		public init( closure: @escaping InitClosure ) {
			self.closure = closure
		}

		public func receive<SubscriberType>( subscriber: SubscriberType ) where
			SubscriberType : Subscriber,
			ClosurePublisher.Failure == SubscriberType.Failure,
			ClosurePublisher.Output == SubscriberType.Input {
				let subscription = ClosurePublisherSubscription( subscriber: subscriber, closure: closure )
				subscriber.receive( subscription: subscription )
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.ClosurePublisher {

	final class ClosurePublisherSubscription<SubscriberType: Subscriber>: Combine.Subscription where
		SubscriberType.Input == Output, Failure == SubscriberType.Failure {

		init( subscriber: SubscriberType, closure: @escaping InitClosure ) {
			self.subscriber = subscriber
			let observer = AnySubscriber<Output, Failure>(
				receiveSubscription: nil,
				receiveValue: { [weak self] value in
					return self?.subscriber?.receive( value ) ?? .none },
				receiveCompletion: { [weak self] completion in
					self?.subscriber?.receive( completion: completion ) }
			)
			closure( observer, lifetime.lifetime )
		}

		public func request( _ demand: Subscribers.Demand ) {
			// Ignore demand.
		}

		public func cancel() {
			self.subscriber = nil
			lifetime.token.cancel()
		}

		private var subscriber: SubscriberType?
		private let lifetime = Lifetime.make()
	}
}
