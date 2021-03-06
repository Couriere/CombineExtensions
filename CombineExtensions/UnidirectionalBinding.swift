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

precedencegroup BindingPrecedence {
	associativity: right

	// Binds tighter than assignment but looser than everything else
	higherThan: AssignmentPrecedence
}

infix operator <~ : BindingPrecedence


/// Describes an entity which be bond towards.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol BindingTargetProvider {
	associatedtype Input

	var bindingTarget: BindingTarget<Input> { get }
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension BindingTargetProvider {
	/// Binds a source to a target, updating the target's value to the latest
	/// value sent by the source.
	///
	/// ````
	/// let property = CurrentValueSubject<String, Never>( "" )
	/// let timePublisher = Timer.publish( every: 1, on: .main, in: .default ).autoconnect()
	/// 						 .map { $0.description }
	/// property <~ timePublisher
	/// ````
	///
	///
	/// - parameters:
	///   - target: A target to be bond to.
	///   - source: A source to bind.
	///
	/// - returns: A cancellable that can be used to terminate binding before the
	///            deinitialization of the target or the source's `completed`
	///            event.
	@discardableResult
	static func <~ <Source: Publisher>( provider: Self, source: Source ) -> AnyCancellable
		where Source.Output == Input, Source.Failure == Never
	{
		let cancellable = source
			.prefix( during: provider.bindingTarget.lifetime )
			.sink( receiveValue: provider.bindingTarget.action )

		provider.bindingTarget.lifetime += cancellable
		return cancellable
	}

	@discardableResult
	static func <~ <Source: Publisher>( provider: Self, source: Source ) -> AnyCancellable
		where Source.Output? == Input, Source.Failure == Never
	{
		let cancellable = source
			.prefix( during: provider.bindingTarget.lifetime )
			.sink( receiveValue: provider.bindingTarget.action )

		provider.bindingTarget.lifetime += cancellable
		return cancellable
	}
}

/// A binding target that can be used with the `<~` operator.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct BindingTarget<Output>: BindingTargetProvider {

	public let action: (Output) -> Void
	public let lifetime: Lifetime

	public var bindingTarget: BindingTarget<Output> {
		return self
	}

	/// Creates a binding target which consumes values on the specified scheduler.
	///
	/// If no scheduler is specified, the binding target would consume the value
	/// immediately.
	///
	/// - parameters:
	///   - lifetime: The expected lifetime of any bindings towards `self`.
	///   - action: The action to consume values.
	public init( lifetime: Lifetime, action: @escaping (Output) -> Void) {
		self.lifetime = lifetime
		self.action = action
	}

	/// Creates a binding target which consumes values on the specified scheduler.
	///
	/// If no scheduler is specified, the binding target would consume the value
	/// immediately.
	///
	/// - parameters:
	///   - scheduler: The scheduler on which the `action` consumes the values.
	///   - lifetime: The expected lifetime of any bindings towards `self`.
	///   - action: The action to consume values.
	public init<S: Scheduler>( on scheduler: S, lifetime: Lifetime, action: @escaping (Output) -> Void) {

		self.lifetime = lifetime
		self.action = { value in
			scheduler.schedule { action( value ) }
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Optional: BindingTargetProvider where Wrapped: BindingTargetProvider {
	public typealias Output = Wrapped.Input

	public var bindingTarget: BindingTarget<Wrapped.Input> {
		switch self {
		case let .some( provider ):
			return provider.bindingTarget
		case .none:
			return BindingTarget( lifetime: .empty, action: { _ in } )
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CurrentValueSubject: BindingTargetProvider where Failure == Never {
	public var bindingTarget: BindingTarget<Output> {
		return BindingTarget( lifetime: Lifetime.of( self )) { [weak self] in self?.value = $0 }
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension PassthroughSubject: BindingTargetProvider where Failure == Never {
	public var bindingTarget: BindingTarget<Output> {
		return BindingTarget( lifetime: Lifetime.of( self )) { [weak self] in self?.send( $0 ) }
	}
}

