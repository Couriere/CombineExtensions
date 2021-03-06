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

/// Describes a provider of reactive extensions.
///
/// - note: `ReactiveExtensionsProvider` does not indicate whether a type is
///         reactive. It is intended for extensions to types that are not owned
///         by the module in order to avoid name collisions and return type
///         ambiguities.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol ReactiveExtensionsProvider {}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension ReactiveExtensionsProvider {
	/// A proxy which hosts reactive extensions for `self`.
	var combine: Reactive<Self> {
		return Reactive(self)
	}

	/// A proxy which hosts static reactive extensions for the type of `self`.
	static var combine: Reactive<Self>.Type {
		return Reactive<Self>.self
	}
}

/// A proxy which hosts reactive extensions of `Base`.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct Reactive<Base> {
	/// The `Base` instance the extensions would be invoked with.
	public let base: Base

	/// Construct a proxy
	///
	/// - parameters:
	///   - base: The object to be proxied.
	fileprivate init(_ base: Base) {
		self.base = base
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: AnyObject {

	/// Creates a binding target which weakly references the object so that
	/// the supplied `action` is triggered only if the object has not deinitialized.
	///
	/// - parameters:
	///   - scheduler: An optional scheduler that the binding target uses. If it
	///                is not specified, a UI scheduler would be used.
	///   - action: The action to consume values from the bindings.
	///
	/// - returns: A binding target that holds no strong references to the
	///            object.
	func makeBindingTarget<U, S: Scheduler>(
		on scheduler: S,
		_ action: @escaping (Base, U) -> Void
	) -> BindingTarget<U> {
		return BindingTarget( on: scheduler, lifetime: Lifetime.of( base )) { [weak base = self.base] value in
			if let base = base {
				action(base, value)
			}
		}
	}

	/// Creates a binding target which weakly references the object so that
	/// the supplied `action` is triggered only if the object has not deinitialized.
	/// `action` is triggered on the main thread.
	///
	/// - parameters:
	///   - action: The action to consume values from the bindings.
	///
	/// - returns: A binding target that holds no strong references to the
	///            object.
	@inline( __always )
	func makeBindingTarget<U>( _ action: @escaping (Base, U) -> Void ) -> BindingTarget<U> {
		makeBindingTarget( on: UIScheduler(), action )
	}
}
