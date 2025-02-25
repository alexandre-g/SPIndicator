// The MIT License (MIT)
// Copyright © 2021 Ivan Vorobei (hello@ivanvorobei.io)
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

import UIKit

#if os(iOS)

/**
 SPIndicator: Main view. Can be customisable if need.
 
 For change duration, check method `present` and pass duration and other specific property if need customise.
 
 Here available set window on which shoud be present.
 If you have some windows, you shoud configure it. Check property `presentWindow`.
 
 For disable dismiss by drag, check property `.dismissByDrag`.
 
 Recomended call `SPIndicator` and choose style func.
 */
@available(iOSApplicationExtension, unavailable)
open class SPIndicatorView: UIView {
    
    // MARK: - UIAppearance

    @objc dynamic open var duration: TimeInterval = 1.5
    
    // MARK: - Properties
    
    /**
     SPIndicator: Change it for set `top` or `bottom` present side.
     Shoud be change before present, instead of no effect.
     */
    open var presentSide: SPIndicatorPresentSide = .top
    
    /**
     SPIndicator: By default allow drag indicator for hide.
     While indicator is dragging, dismiss not work.
     This behaviar can be disabled.
     */
    open var dismissByDrag: Bool = true {
        didSet {
            setGesture()
        }
    }
    
    /**
     SPIndicator: Completion call after hide indicator.
     */
    open var completion: (() -> Void)? = nil
    
    // MARK: - Views
    
    open var titleLabel: UILabel?
    open var subtitleLabel: UILabel?
    open var iconView: UIView?
    
    private lazy var backgroundView: UIVisualEffectView = {
        let view: UIVisualEffectView = {
            if #available(iOS 13.0, *) {
                return UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
            } else {
                return UIVisualEffectView(effect: UIBlurEffect(style: .light))
            }
        }()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    weak open var presentWindow: UIWindow?
    
    // MARK: - Init
    
    public init(title: String, message: String? = nil, preset: SPIndicatorIconPreset) {
        super.init(frame: CGRect.zero)
        commonInit()
        layout = SPIndicatorLayout(for: preset)
        setTitle(title)
        if let message = message {
            setMessage(message)
        }
        setIcon(for: preset)
    }
    
    public init(title: String, message: String?) {
        super.init(frame: CGRect.zero)
        titleAreaFactor = 1.8
        minimumAreaWidth = 100
        commonInit()
        layout = SPIndicatorLayout.message()
        setTitle(title)
        if let message = message {
            setMessage(message)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.presentSide = .top
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        preservesSuperviewLayoutMargins = false
        if #available(iOS 11.0, *) {
            insetsLayoutMarginsFromSafeArea = false
        }
        
        backgroundColor = .clear
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)
        
        setShadow()
        setGesture()
    }
    
    // MARK: - Configure
    
    private func setTitle(_ text: String) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .semibold)
        label.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.lineSpacing = 3
        label.attributedText = NSAttributedString(
            string: text, attributes: [.paragraphStyle: style]
        )
        label.textAlignment = .left
        label.textColor = UIColor.Compability.label.withAlphaComponent(0.6)
        titleLabel = label
        addSubview(label)
    }
    
    private func setMessage(_ text: String) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .semibold)
        label.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.lineSpacing = 2
        label.attributedText = NSAttributedString(
            string: text, attributes: [.paragraphStyle: style]
        )
        label.textAlignment = .left
        label.textColor = UIColor.Compability.label.withAlphaComponent(0.3)
        subtitleLabel = label
        addSubview(label)
    }
    
    private func setIcon(for preset: SPIndicatorIconPreset) {
        let view = preset.createView()
        self.iconView = view
        addSubview(view)
    }
    
    private func setShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowOffset = .init(width: 0, height: 7)
        layer.shadowRadius = 40
        
        // Not use render shadow becouse backgorund is visual effect.
        // If turn on it, background will hide.
        // layer.shouldRasterize = true
    }
    
    private func setGesture() {
        if dismissByDrag {
            let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            addGestureRecognizer(gestureRecognizer)
            self.gestureRecognizer = gestureRecognizer
        } else {
            self.gestureRecognizer = nil
        }
    }
    
    // MARK: - Present
    
    private var presentAndDismissDuration: TimeInterval = 0.6
    
    private var presentWithOpacity: Bool {
        if presentSide == .center { return true }
        return false
    }
    
    open func present(haptic: SPIndicatorHaptic = .success, completion: (() -> Void)? = nil) {
        present(duration: self.duration, haptic: haptic, completion: completion)
    }
    
    open func present(duration: TimeInterval, haptic: SPIndicatorHaptic = .success, completion: (() -> Void)? = nil) {
        
        if self.presentWindow == nil {
            self.presentWindow = UIApplication.shared.keyWindow
        }
        
        guard let window = self.presentWindow else { return }
        
        window.addSubview(self)
        
        // Prepare for present
        
        self.whenGestureEndShoudHide = false
        self.completion = completion
        
        isHidden = true
        sizeToFit()
        layoutSubviews()
        center.x = window.frame.midX
        toPresentPosition(.prepare(presentSide))
        
        self.alpha = presentWithOpacity ? 0 : 1
        
        // Present
        
        isHidden = false
        haptic.impact()
        UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.toPresentPosition(.visible(self.presentSide))
            if self.presentWithOpacity { self.alpha = 1 }
        }, completion: { finished in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                if self.gestureIsDragging {
                    self.whenGestureEndShoudHide = true
                } else {
                    self.dismiss()
                }
            }
        })
        
        if let iconView = self.iconView as? SPIndicatorIconAnimatable {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + presentAndDismissDuration / 3) {
                iconView.animate()
            }
        }
    }
    
    @objc open func dismiss() {
        UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            self.toPresentPosition(.prepare(self.presentSide))
            if self.presentWithOpacity { self.alpha = 0 }
        }, completion: { finished in
            self.removeFromSuperview()
            self.completion?()
        })
    }
    
    // MARK: - Internal
    
    private var minimumYTranslationForHideByGesture: CGFloat = -10
    private var maximumYTranslationByGesture: CGFloat = 60
    
    private var gestureRecognizer: UIPanGestureRecognizer?
    private var gestureIsDragging: Bool = false
    private var whenGestureEndShoudHide: Bool = false
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            self.gestureIsDragging = true
            let translation = gestureRecognizer.translation(in: self)
            let newTranslation: CGFloat = {
                switch presentSide {
                case .top:
                    if translation.y <= 0 {
                        return translation.y
                    } else {
                        return min(maximumYTranslationByGesture, translation.y.squareRoot())
                    }
                case .bottom:
                    if translation.y >= 0 {
                        return translation.y
                    } else {
                        let absolute = abs(translation.y)
                        return -min(maximumYTranslationByGesture, absolute.squareRoot())
                    }
                case .center:
                    let absolute = abs(translation.y).squareRoot()
                    let newValue = translation.y < 0 ? -absolute : absolute
                    return min(maximumYTranslationByGesture, newValue)
                }
            }()
            toPresentPosition(.fromVisible(newTranslation, from: (presentSide)))
        }
        
        if gestureRecognizer.state == .ended {
            gestureIsDragging = false
            
            var shoudDismissWhenEndAnimation: Bool = false
            
            UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
                if self.whenGestureEndShoudHide {
                    self.toPresentPosition(.prepare(self.presentSide))
                    shoudDismissWhenEndAnimation = true
                } else {
                    let translation = gestureRecognizer.translation(in: self)
                    if translation.y < self.minimumYTranslationForHideByGesture {
                        self.toPresentPosition(.prepare(self.presentSide))
                        shoudDismissWhenEndAnimation = true
                    } else {
                        self.toPresentPosition(.visible(self.presentSide))
                    }
                }
            }, completion: { _ in
                if shoudDismissWhenEndAnimation {
                    self.dismiss()
                }
            })
        }
    }
    
    private func toPresentPosition(_ position: PresentPosition) {
        
        let getPrepareTransform: ((_ side: SPIndicatorPresentSide) -> CGAffineTransform) = { [weak self] side in
            guard let self = self else { return .identity }
            guard let window = UIApplication.shared.windows.first else { return .identity }
            switch side {
            case .top:
                let topInset = window.safeAreaInsets.top
                let position = -(topInset + 50)
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .bottom:
                let height = window.frame.height
                let bottomInset = window.safeAreaInsets.bottom
                let position = height + bottomInset + 50
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .center:
                return CGAffineTransform.identity.translatedBy(x: 0, y: window.frame.height / 2 - self.frame.height / 2).scaledBy(x: 0.9, y: 0.9)
            }
        }
        
        let getVisibleTransform: ((_ side: SPIndicatorPresentSide) -> CGAffineTransform) = { [weak self] side in
            guard let self = self else { return .identity }
            guard let window = UIApplication.shared.windows.first else { return .identity }
            switch side {
            case .top:
                var topSafeAreaInsets = window.safeAreaInsets.top
                if topSafeAreaInsets < 20 { topSafeAreaInsets = 20 }
                let position = topSafeAreaInsets - 3 + self.offset
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .bottom:
                let height = window.frame.height
                var bottomSafeAreaInsets = window.safeAreaInsets.top
                if bottomSafeAreaInsets < 20 { bottomSafeAreaInsets = 20 }
                let position = height - bottomSafeAreaInsets - 3 - self.frame.height - self.offset
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .center:
                return CGAffineTransform.identity.translatedBy(x: 0, y: window.frame.height / 2 - self.frame.height / 2)
            }
        }
        
        switch position {
        case .prepare(let presentSide):
            transform = getPrepareTransform(presentSide)
        case .visible(let presentSide):
            transform = getVisibleTransform(presentSide)
        case .fromVisible(let translation, let presentSide):
            transform = getVisibleTransform(presentSide).translatedBy(x: 0, y: translation)
        }
    }
    
    // MARK: - Layout
    
    /**
     SPIndicator: Wraper of layout values.
     */
    open var layout: SPIndicatorLayout = .init()
    
    /**
     SPIndicator: Alert offset
     */
    open var offset: CGFloat = 0
    
    private var minimumAreaWidth: CGFloat = 196
    private var maximumAreaWidth: CGFloat = 260
    private var titleAreaFactor: CGFloat = 2.5
    private var spaceBetweenTitles: CGFloat = 1
    private var spaceBetweenTitlesAndImage: CGFloat = 16
    
    private var titlesCompactWidth: CGFloat {
        if let iconView = self.iconView {
            let space = iconView.frame.maxY + spaceBetweenTitlesAndImage
            return frame.width - space * 2
        } else {
            return frame.width - layoutMargins.left - layoutMargins.right
        }
    }
    
    private var titlesFullWidth: CGFloat {
        if let iconView = self.iconView {
            let space = iconView.frame.maxY + spaceBetweenTitlesAndImage
            return frame.width - space - layoutMargins.right - self.spaceBetweenTitlesAndImage
        } else {
            return frame.width - layoutMargins.left - layoutMargins.right
        }
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxWidth = maximumAreaWidth
        let textPadding: CGFloat = 8  // Added padding value for top and bottom
        
        // Account for icon width in text available width calculation
        let iconWidth = iconView != nil ? (layout.iconSize.width + spaceBetweenTitlesAndImage) : 0
        let textAvailableWidth = maxWidth - layoutMargins.left - layoutMargins.right - iconWidth

        // Calculate total text height (title + optional space + subtitle).
        var textHeight: CGFloat = 0

        if let title = titleLabel?.text, !title.isEmpty {
            let ts = titleLabel!.sizeThatFits(
                CGSize(width: textAvailableWidth, height: .greatestFiniteMagnitude)
            )
            textHeight += ts.height
        }

        if let subtitle = subtitleLabel?.text, !subtitle.isEmpty {
            if textHeight > 0 {
                textHeight += spaceBetweenTitles
            }
            let ss = subtitleLabel!.sizeThatFits(
                CGSize(width: textAvailableWidth, height: .greatestFiniteMagnitude)
            )
            textHeight += ss.height
        }

        // Add padding to text height
        textHeight += (textPadding * 2)  // Add padding to top and bottom

        // Icon height
        let iconHeight = iconView?.bounds.height ?? 0

        // Compute the total taking the maximum of icon vs. text area.
        let contentHeight = max(iconHeight, textHeight)

        // Add top & bottom margins
        let totalHeight = layoutMargins.top + contentHeight + layoutMargins.bottom

        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = layout.margins
        layer.cornerRadius = bounds.height / 2
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = layer.cornerRadius
        
        let iconSize = layout.iconSize
        let textXStart = layoutMargins.left
        let contentWidth = bounds.width - layoutMargins.left - layoutMargins.right

        // Calculate total text height.
        let maxTextWidth = contentWidth - (iconView != nil ? iconSize.width + spaceBetweenTitlesAndImage : 0)
        let titleSize = titleLabel?.sizeThatFits(CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)) ?? .zero
        let subtitleSize = subtitleLabel?.sizeThatFits(CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude)) ?? .zero

        var totalTextHeight: CGFloat = 0
        if titleSize.height > 0 {
            totalTextHeight += titleSize.height
        }
        if subtitleSize.height > 0 {
            // Add spaceBetweenTitles if we actually have a subtitle.
            totalTextHeight += subtitleSize.height + spaceBetweenTitles
        }

        // Overall content is the max of icon height vs. text height.
        let contentHeight = max(iconSize.height, totalTextHeight)
        let contentYStart = (bounds.height - contentHeight) / 2

        // Position the icon in the vertical center of the content.
        if let iconView = iconView {
            iconView.frame = CGRect(
                x: textXStart,
                y: contentYStart + (contentHeight - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
        }

        // Position the text to the right of the icon, also vertically centered.
        var currentTextY = contentYStart + (contentHeight - totalTextHeight) / 2
        let textX = textXStart + (iconView != nil ? iconSize.width + spaceBetweenTitlesAndImage : 0)

        // Layout the title label if present.
        if let titleLabel = titleLabel, titleSize.height > 0 {
            titleLabel.frame = CGRect(
                x: textX,
                y: currentTextY,
                width: maxTextWidth,
                height: titleSize.height
            )
            currentTextY += titleSize.height
        }

        // Layout the subtitle label if present.
        if let subtitleLabel = subtitleLabel, subtitleSize.height > 0 {
            currentTextY += spaceBetweenTitles
            subtitleLabel.frame = CGRect(
                x: textX,
                y: currentTextY,
                width: maxTextWidth,
                height: subtitleSize.height
            )
            currentTextY += subtitleSize.height
        }
    }
    
    // MARK: - Models
    
    enum PresentPosition {
        
        case prepare(_ from: SPIndicatorPresentSide)
        case visible(_ from: SPIndicatorPresentSide)
        case fromVisible(_ translation: CGFloat, from: SPIndicatorPresentSide)
    }
    
    enum LayoutGrid {
        
        case iconTitleMessageCentered
        case iconTitleMessageLeading
        case iconTitleCentered
        case iconTitleLeading
        case title
        case titleMessage
    }
}

#endif
