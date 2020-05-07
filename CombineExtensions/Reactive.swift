
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
	func makeBindingTarget<U, S: Scheduler>( on scheduler: S,
													_ action: @escaping (Base, U) -> Void) -> BindingTarget<U> {
		return BindingTarget( on: scheduler, lifetime: Lifetime.of( base )) { [weak base = self.base] value in
			if let base = base {
				action(base, value)
			}
		}
	}

	/// Creates a binding target which weakly references the object so that
	/// the supplied `action` is triggered only if the object has not deinitialized.
	///
	/// - parameters:
	///   - action: The action to consume values from the bindings.
	///
	/// - returns: A binding target that holds no strong references to the
	///            object.
	func makeBindingTarget<U>( _ action: @escaping (Base, U) -> Void) -> BindingTarget<U> {
		return BindingTarget( lifetime: Lifetime.of( base )) { [weak base = self.base] value in
			if let base = base {
				action(base, value)
			}
		}
	}

	/// Creates a binding target which weakly references the object so that
	/// the supplied `action` is triggered only if the object has not deinitialized.
	/// Action is guarantee to be executed on main thread.
	///
	/// - parameters:
	///   - action: The action to consume values from the bindings.
	///
	/// - returns: A binding target that holds no strong references to the
	///            object.
	func makeUIBindingTarget<U>( _ action: @escaping (Base, U) -> Void) -> BindingTarget<U> {
		return BindingTarget( on: DispatchQueue.main, lifetime: Lifetime.of( base )) { [weak base = self.base] value in
			if let base = base {
				action(base, value)
			}
		}
	}
}
