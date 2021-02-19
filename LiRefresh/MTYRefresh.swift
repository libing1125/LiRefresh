//
//  MTYRefresh.swift
//  LiRefresh
//
//  Created by bli on 2021/2/19.
//  Copyright © 2021 bli. All rights reserved.
//

import Foundation
import Lottie

class MTYPullDownRefreshView: UIView {

    var loadingTips: [String] = [""]

    weak var scrollView: UIScrollView? {
        didSet {
            if let oldScrollView = oldValue {
                oldScrollView.removeObserver(self, forKeyPath: #keyPath(UICollectionView.contentOffset))
                removeFromSuperview()
                NSLayoutConstraint.deactivate(constraints)
                oldScrollView.panGestureRecognizer.removeTarget(self, action: #selector(scrollViewPanDidChange(_:)))
            }
            if let scrollView = scrollView {
                scrollView.addObserver(self, forKeyPath: #keyPath(UICollectionView.contentOffset), options: .new, context: nil)
                scrollView.addSubview(self)
                NSLayoutConstraint.activate([
                    leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                    widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                    bottomAnchor.constraint(equalTo: scrollView.topAnchor),
                    heightAnchor.constraint(equalToConstant: 60.0)
                ])
                scrollView.panGestureRecognizer.addTarget(self, action: #selector(scrollViewPanDidChange(_:)))
            }
        }
    }
    var originContentInsetTop: CGFloat = 0.0
    var actionHandler: (() -> Void)?

    func loadingFinished() {
        scrollView?.contentInset = UIEdgeInsets(top: originContentInsetTop, left: 0.0, bottom: 0.0, right: 0.0)
        scrollView?.setContentOffset(CGPoint(x: 0, y: -originContentInsetTop), animated: true)
        state = .idle
    }

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(0x909592)
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    private let loadingAnimationView: AnimationView = {
        let view = AnimationView(name: "mty_pull_down_refresh")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.loopMode = .loop
        return view
    }()

    private var loadingAnimationWidth: NSLayoutConstraint!
    private var loadingAnimationHeight: NSLayoutConstraint!

    private enum State {
        case loading
        case idle
    }

    private var state: State = .idle {
        didSet {
            switch state {
            case .loading:
                loadingAnimationWidth.constant = 30
                loadingAnimationHeight.constant = 30
                loadingAnimationView.isHidden = false
                loadingAnimationView.play()
            case .idle:
                loadingAnimationWidth.constant = 0
                loadingAnimationHeight.constant = 0
                loadingAnimationView.isHidden = true
                loadingAnimationView.stop()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        containerView.addSubview(label)
        containerView.addSubview(loadingAnimationView)

        loadingAnimationWidth = loadingAnimationView.widthAnchor.constraint(equalToConstant: 0)
        loadingAnimationHeight = loadingAnimationView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingAnimationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loadingAnimationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            loadingAnimationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: loadingAnimationView.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            loadingAnimationWidth,
            loadingAnimationHeight
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable block_based_kvo
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset", let object = object as? UIScrollView, object === scrollView {
            if state == .loading { return }
            if let offsetObject = change?[.newKey] as? NSValue {
                let offsetY = offsetObject.cgPointValue.y
                if offsetY <= -(60.0 + originContentInsetTop) {
                    label.text = "松手刷新"
                } else {
                    label.text = "下拉刷新"
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    @objc private func scrollViewPanDidChange(_ pan: UIGestureRecognizer) {
        if pan.state == .ended {
            guard let scrollView = scrollView, scrollView.contentOffset.y <= -(60.0 + originContentInsetTop) else { return }
            state = .loading
            label.text = randomLoadingTip()
            scrollView.setContentOffset(CGPoint(x: 0, y: -(60.0 + originContentInsetTop)), animated: false)
            scrollView.contentInset = UIEdgeInsets(top: (60.0 + originContentInsetTop), left: 0, bottom: 0.0, right: 0.0)
            actionHandler?()
        }
    }

    private func randomLoadingTip() -> String {
        let randomInt = Int.random(in: loadingTips.indices)
        return loadingTips[randomInt]
    }
}
