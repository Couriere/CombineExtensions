//
//  Property.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public class Property<Output>: Publisher {

	public typealias Failure = Never

	public var value: Output { underlyingSubject.value }

	public init( _ initialValue: Output ) {
		underlyingSubject = CurrentValueSubject<Output, Failure>( initialValue )
	}

	public init<PublisherType: Publisher>( initial: Output, then values: PublisherType )
		where PublisherType.Failure == Never, Output == PublisherType.Output  {
			underlyingSubject = CurrentValueSubject<Output, Failure>( initial )
			thenPublisherCancellable = values.assign( to: \.value, on: underlyingSubject )
	}

	public init( _ subject: CurrentValueSubject<Output, Never> ) {
		underlyingSubject = CurrentValueSubject<Output, Failure>( subject.value )
		thenPublisherCancellable = subject.assign( to: \.value, on: underlyingSubject )
	}

	public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
		underlyingSubject.receive( subscriber: subscriber )
	}

	private var thenPublisherCancellable: AnyCancellable?
	private let underlyingSubject: CurrentValueSubject<Output, Failure>
}
