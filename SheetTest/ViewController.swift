//
//  ViewController.swift
//  SheetTest
//
//  Created by hemenisapp on 12.06.2020.
//  Copyright © 2020 hemenisapp. All rights reserved.
//


import UIKit

final class SheetModalPresentationController: UIPresentationController {
            
    // MARK: Private Properties
    
    private let height: CGFloat
    private let interactor = UIPercentDrivenInteractiveTransition()
    private let dimmingView = UIView()
    private var propertyAnimator: UIViewPropertyAnimator!
    private var isInteractive = false
    private let cornerRadius: CGFloat = 15
    
    // MARK: Initializers
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, height: CGFloat) {
        //self.height = min(height, presentedViewController.view.frame.height)
        self.height = height
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    // MARK: Function Overrides
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerBounds = containerView?.bounds else { return .zero }
        
        // Calculate the frame for the presented view controller using the passed in height.
        var frame = containerBounds
        //frame.size.height = height + cornerRadius
        frame.origin.y = containerBounds.height - self.height
        
        return frame
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerBounds = containerView?.bounds else { return }
        
        // Add a pan gesture recognizer for pull to dismiss.
        presentedView?.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        // Round the the presented view controller's corners.
        presentedView?.layer.cornerRadius = cornerRadius
        
        // Add a dimming view below the presented view controller, and a tap gesture recognizer to it for dismissal.
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        dimmingView.backgroundColor = .black
        dimmingView.frame = containerBounds
        dimmingView.alpha = 0
        containerView?.insertSubview(dimmingView, at: 0)
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.1
        })
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }
    
    // MARK: Private Functions
    
    @objc private func dismiss() {
        presentedViewController.dismiss(animated: true)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view else { return }
            
        let translationY = gesture.translation(in: gestureView).y
        
        // Make sure we only recognize downward gestures.
        guard translationY >= 0  else { return }
        
        let percent = translationY / self.height
        let velocity = gesture.velocity(in: gestureView).y

        switch gesture.state {
        case .began:
            isInteractive = true
            presentedViewController.dismiss(animated: true, completion: nil)
        case .changed:
            interactor.update(percent)
            //presentedView?.frame.origin.y = UIScreen.main.bounds.height - self.height + gesture.translation(in: containerView).y * 0.3
            break
        case .cancelled:
            interactor.cancel()
            isInteractive = false
        case .ended:
                        // Finish the animation if the user flicked the modal quickly (i.e. high velocity), or dragged it more than 50% down.
            if percent > 0.3 || velocity > 1600 {
                // Multiply the animation duration by the velocity, to make sure the modal dismisses as fast as the user swiped.
                // If the user pulled down slowly though, we want to use the default duration, hence the max().
                interactor.completionSpeed = max(1, velocity / (gestureView.frame.height * (1 / interactor.duration)))
                interactor.finish()
            } else {
                interactor.cancel()
            }
            isInteractive = false
        default:
            break
        }
    }

}

// MARK: UIViewControllerAnimatedTransitioning
extension SheetModalPresentationController: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        propertyAnimator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                                  timingParameters: UICubicTimingParameters())
        propertyAnimator.addAnimations {
            // Move the view down.
            transitionContext.view(forKey: .from)?.frame.origin.y = transitionContext.containerView.frame.maxY
        }
        propertyAnimator.addCompletion { [weak transitionContext] _ in
            guard let transitionContext = transitionContext else { return }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        return propertyAnimator
    }
    
}

// MARK: UIViewControllerTransitioningDelegate
extension SheetModalPresentationController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        isInteractive ? interactor : nil
    }

}

// MARK: UIViewController Extension
extension UIViewController {
    
    func presentAsSheet(_ vc: UIViewController, height: CGFloat) {
        let presentationController = SheetModalPresentationController(presentedViewController: vc,
                                                                      presenting: self,
                                                                      height: height)
        vc.transitioningDelegate = presentationController
        vc.modalPresentationStyle = .custom
        present(vc, animated: true)
    }
    
}

// Example usage:
final class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentPressed)))
    }
    
    @objc private func presentPressed() {
        presentAsSheet(ModalViewController(), height: 300)
    }

}


final class ModalViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .blue
    }
    
}

