//
//  AnyPublisher+Pipe.swift
//
//  Created by Vladimir Kazantsev on 10.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//
import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension AnyPublisher {

	/// Create a `Publisher` that will be controlled by sending events to an
	/// subscriber.
	///
	/// - parameters:
	///   - disposable: An optional disposable to associate with the signal, and
	///                 to be disposed of when the signal terminates.
	///
	/// - returns: A 2-tuple of the output end of the pipe as `AnyPublisher`,
	/// and the input end of the pipe as `AnyPublisher.Subscriber`.
	///
	/// - note: On `subscriber` deinit completion event sent to publisher.
	///
	static func pipe() -> ( publisher: AnyPublisher<Output, Failure>, subscriber: AnySubscriber<Output, Failure> ) {

		let subscriber = Publishers.PipePublisher<Output, Failure>.Subscriber()
		let publisher = Publishers.PipePublisher<Output, Failure>( subscriber: subscriber )

		return ( publisher.eraseToAnyPublisher(), AnySubscriber( subscriber ))
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.PipePublisher {

	final class Subscriber: Combine.Subscriber {

		public func receive( subscription: Combine.Subscription ) {
			fatalError()
		}

		public func receive( _ input: Output ) -> Subscribers.Demand {
			subscriptions.forEach { $0.value?.send( input ) }
			return .unlimited
		}

		public func receive( completion: Subscribers.Completion<Failure> ) {
			subscriptions.forEach { $0.value?.send( completion: completion ) }
		}

		fileprivate init() {}
		deinit {
			receiveCompletion()
		}

		fileprivate func add( subscription:	SubscriptionType ) {
			subscriptions.append( WeakBox( subscription ) )
		}

		/// Holding weak list of subscribers of the `PipePublisher`.
		private struct WeakBox<Object: AnyObject> {
			weak var value: Object?
			init( _ value: Object ) { self.value = value }
		}
		private var subscriptions = [ WeakBox<SubscriptionType> ]()

		fileprivate typealias SubscriptionType =
			Publishers.PipePublisher<Output, Failure>.PipePublisherSubscription
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	struct PipePublisher<Output, Failure>: Publisher where Failure: Error {

		fileprivate init( subscriber: Subscriber ) {
			self.subscriber = subscriber
		}

		public func receive<SubscriberType>( subscriber: SubscriberType ) where
			SubscriberType : Combine.Subscriber,
			PipePublisher.Failure == SubscriberType.Failure,
			PipePublisher.Output == SubscriberType.Input {
				let subscription = PipePublisherSubscription( subscriber: AnySubscriber( subscriber ))
				self.subscriber?.add( subscription: subscription )
				subscriber.receive( subscription: subscription )
		}

		private weak var subscriber: Subscriber?
	}
}



@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.PipePublisher {

	final class PipePublisherSubscription: Combine.Subscription {

		init( subscriber: AnySubscriber<Output, Failure> ) {
			self.subscriber = subscriber
		}

		public func request( _ demand: Subscribers.Demand ) {
			// Ignore demand.
		}

		public func cancel() {
			self.subscriber = nil
		}

		fileprivate func send( _ value: Output ) {
			_ = subscriber?.receive( value )
		}
		fileprivate func send( completion: Subscribers.Completion<Failure> ) {
			subscriber?.receive( completion: completion )
		}

		private var subscriber: AnySubscriber<Output, Failure>?
	}
}
