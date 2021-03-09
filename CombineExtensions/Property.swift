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
@propertyWrapper
public final class Property<Output>: Publisher {

	public typealias Failure = Never

	public var value: Output { underlyingSubject.value }

	public var wrappedValue: Output { return value }

	public var projectedValue: Property<Output> { return self }

	public init( value: Output ) {
		underlyingSubject = CurrentValueSubject<Output, Never>( value )
	}

	public init<PublisherType: Publisher>( initial: Output, then values: PublisherType )
		where PublisherType.Failure == Never, Output == PublisherType.Output  {
			underlyingSubject = CurrentValueSubject<Output, Never>( initial )
			thenPublisherCancellable = values.assign( to: \.value, on: underlyingSubject )
	}

	public init( _ subject: CurrentValueSubject<Output, Never> ) {
		underlyingSubject = CurrentValueSubject<Output, Never>( subject.value )
		thenPublisherCancellable = subject.assign( to: \.value, on: underlyingSubject )
	}

	public init( _ mutableProperty: MutableProperty<Output> ) {
		underlyingSubject = CurrentValueSubject<Output, Never>( mutableProperty.value )
		thenPublisherCancellable = mutableProperty
			.assign( to: \.value, on: underlyingSubject )
	}

	public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
		underlyingSubject.receive( subscriber: subscriber )
	}

	private var thenPublisherCancellable: AnyCancellable?
	private let underlyingSubject: CurrentValueSubject<Output, Never>
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Property: Equatable where Output: Equatable {
	public static func == ( lhs: Property<Output>, rhs: Property<Output> ) -> Bool {
		lhs.value == rhs.value
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Property: Hashable where Output: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine( value )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Property: Codable where Output: Codable {
	public convenience init(from decoder: Decoder) throws {
		self.init( value: try Output.init( from: decoder ))
	}

	public func encode(to encoder: Encoder) throws {
		try value.encode( to: encoder )
	}
}
