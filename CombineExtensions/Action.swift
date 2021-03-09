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

/// Typealias for compatibility with UI controls control events properties.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias CocoaAction = Action<Void, Void, Never>

/// Possible errors from invoking execute()
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public enum ActionError<Failure: Error>: Error {
    case notEnabled
    case failure( Failure )
}

/**
Represents a value that accepts a workFactory which takes some Observable<Input> as its input
and produces an Observable<Element> as its output.

When this excuted via execute() or inputs subject, it passes its parameter to this closure and subscribes to the work.
*/
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public final class Action<Input, Output, Failure: Error> {
    public typealias WorkFactory = (Input) -> AnyPublisher<Output, Failure>

    public let workFactory: WorkFactory

    /// Bindable sink for inputs that triggers execution of action.
    public let inputs: PassthroughSubject<Input, Never>

	/// Whether or not we're currently executing.
	/// Delivered on whatever scheduler they were sent from.
	public let values: AnyPublisher<Output, Never>

    /// Errors aggrevated from invocations of execute().
    /// Delivered on whatever scheduler they were sent from.
	public let errors: AnyPublisher<Failure, Never>

	/// A signal of all failed attempts to start a unit of work of the `Action`.
	/// Delivered on whatever scheduler they were sent from.
	public let disabledErrors: AnyPublisher<Void, Never>

    /// Whether or not we're currently executing.
    public let isExecuting: Property<Bool>

    /// Observables returned by the workFactory.
    /// Useful for sending results back from work being completed
    /// e.g. response from a network call.
    public let executionObservables: AnyPublisher<AnyPublisher<Output, Failure>, Never>

    /// Whether or not we're enabled. Value of this property
    /// based on enabledIf initializer and if we're currently executing.
	public let isEnabled: Property<Bool>

	public convenience init<PublisherType: Publisher>(
		enabledIf: CurrentValueSubject<Bool, Never> = .init( true ),
        workFactory: @escaping (Input) -> PublisherType
	) where Output == PublisherType.Output, Failure == PublisherType.Failure {
        self.init( enabledIf: enabledIf ) {
            workFactory( $0 ).eraseToAnyPublisher()
        }
    }

    public init(
		enabledIf: CurrentValueSubject<Bool, Never> = .init( true ),
        workFactory: @escaping WorkFactory
	) {

        self.workFactory = workFactory

		let _isEnabled = CurrentValueSubject<Bool, Never>( true )
		isEnabled = Property( _isEnabled )

		let errorsSubject = PassthroughSubject<ActionError<Failure>, Never>()
		errors = errorsSubject.compactMap { $0.failure }.eraseToAnyPublisher()
		disabledErrors = errorsSubject.filter { $0.isDisabled }.map { _ in () }.eraseToAnyPublisher()

        let inputsSubject = PassthroughSubject<Input, Never>()
        inputs = inputsSubject

        executionObservables = inputsSubject
			.withLatest( from: _isEnabled ) { input, enabled in (input, enabled) }
            .flatMap { input, enabled -> AnyPublisher<AnyPublisher<Output, Failure>, Never> in
                if enabled {
					return Just<AnyPublisher<Output, Failure>>(
						workFactory( input )
							.handleEvents( receiveCompletion: {
								if case let .failure( error ) = $0 {
									errorsSubject.send( .failure( error ))
								}
							} )
							.share()
							.eraseToAnyPublisher()
						)
						.eraseToAnyPublisher()
                } else {
					errorsSubject.send( .notEnabled )
					return Empty<AnyPublisher<Output, Failure>, Never>()
						.eraseToAnyPublisher()
                }
            }
            .share()
			.eraseToAnyPublisher()

		values = executionObservables
			.flatMap { $0.catch { _ in Empty( completeImmediately: false ) } }
			.eraseToAnyPublisher()

		let _isExecuting = executionObservables
			.flatMap { execution -> AnyPublisher<Bool, Never> in
				let execution = execution
					.flatMap { _ in Empty<Bool, Failure>() }
					.catch { _ in Empty<Bool, Never>() }

				return execution
					.prepend( true )
					.append( false )
					.eraseToAnyPublisher()
		}

		isExecuting = Property( initial: false, then: _isExecuting )

		cancellables += _isEnabled <~ Publishers.CombineLatest( isExecuting.prepend( false ), enabledIf )
			.map { !$0 && $1 }
    }

	private var cancellables: Set<AnyCancellable> = []
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Action: BindingTargetProvider {
	public var bindingTarget: BindingTarget<Input> {
		return BindingTarget( lifetime: Lifetime.of( self )) { [weak self] in self?.inputs.send( $0 ) }
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
private extension ActionError {
	var failure: Failure? { if case .failure( let failure ) = self { return failure }; return nil }
	var isDisabled: Bool { if case .notEnabled = self { return true }; return false }
}
