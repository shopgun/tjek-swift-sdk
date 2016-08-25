//
//  _____ _           _____
// |   __| |_ ___ ___|   __|_ _ ___
// |__   |   | . | . |  |  | | |   |
// |_____|_|_|___|  _|_____|___|_|_|
//               |_|
//
//  Copyright (c) 2016 ShopGun. All rights reserved.

import UIKit


import AlamofireImage

@objc
public protocol PDFPublicationPageViewDelegate : class {
    
    optional func didConfigurePDFPublicationPage(pageView:PDFPublicationPageView, viewModel:PDFPublicationPageViewModelProtocol)
    
    optional func didLoadPDFPublicationPageImage(pageView:PDFPublicationPageView, imageURL:NSURL, fromCache:Bool)
    optional func didLoadPDFPublicationPageZoomImage(pageView:PDFPublicationPageView, imageURL:NSURL, fromCache:Bool)
    
    /// The user touched a location in the view. The location is as a percentage 0->1 of the width/height from the top-left
    optional func didTouchPDFPublicationPage(pageView:PDFPublicationPageView, location:CGPoint)
    /// The user tapped (touched then released) a location in the view. The location is as a percentage 0->1 of the width/height from the top-left
    optional func didTapPDFPublicationPage(pageView:PDFPublicationPageView, location:CGPoint)
    /// The user began longpressing a location in the view. The location is as a percentage 0->1 of the width/height from the top-left
    optional func didStartLongPressPDFPublicationPage(pageView:PDFPublicationPageView, location:CGPoint, duration:NSTimeInterval)
    /// The user finished longpressing a location in the view. The location is as a percentage 0->1 of the width/height from the top-left
    optional func didEndLongPressPDFPublicationPage(pageView:PDFPublicationPageView, location:CGPoint, duration:NSTimeInterval)
}


public class PDFPublicationPageView : VersoPageView, UIGestureRecognizerDelegate {

    public enum ImageLoadState {
        case NotLoaded
        case Loading
        case Loaded
        case Failed
    }
    
    public required init(frame: CGRect) {
        super.init(frame: frame)
        
        // listen for memory warnings and clear the zoomimage
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PDFPublicationPageView.memoryWarningNotification(_:)), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        
        // add subviews
        addSubview(pageLabel)
        addSubview(imageView)
        addSubview(zoomImageView)
        
//        backgroundColor = UIColor(red: 1, green: 1, blue: 0, alpha: 0.2)        
        
        _initializeGestureRecognizers()
    }
    
    public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    
    
    
    
    // MARK: - Public
    
    weak public var delegate:PDFPublicationPageViewDelegate?
    
    public private(set) var imageLoadState:ImageLoadState = .NotLoaded
    public private(set) var zoomImageLoadState:ImageLoadState = .NotLoaded
    
    
    public func startLoadingZoomImageFromURL(zoomImageURL:NSURL) {
        
        zoomImageLoadState = .Loading
        zoomImageView.image = nil
        zoomImageView.hidden = false
        
        zoomImageView.af_setImageWithURL(zoomImageURL, imageTransition: .CrossDissolve(0.3), runImageTransitionIfCached: true) { [weak self] response in
            guard self != nil else {
                return
            }
            
            if response.result.isSuccess {
                
                self!.zoomImageLoadState = .Loaded
                
                self!.delegate?.didLoadPDFPublicationPageZoomImage?(self!, imageURL:zoomImageURL, fromCache:(response.response == nil))
            }
            else {
                self!.zoomImageView.hidden = true
                
                if let error = response.result.error {
                    if error.code == NSURLErrorCancelled {
                        self!.zoomImageLoadState = .NotLoaded
                        return // image load cancelled
                    }
                }
                // TODO: handle failed image load
                // tell delegate? show error? retry?
                // maybe cache failed image urls to re-fail quickly?
                self!.zoomImageLoadState = .Failed
            }
        }
    }
    
    public func startLoadingImageFromURL(imageURL:NSURL) {
        
        imageLoadState = .Loading
        
        // load the image from the url
        // TODO: allow for non-AlamoFire image loader
        // TODO: move image-loading to Publication?
        imageView.af_setImageWithURL(imageURL, imageTransition: .CrossDissolve(0.1), runImageTransitionIfCached: false) { [weak self] response in
            guard self != nil else {
                return
            }
            
            if response.result.isSuccess {
                // Update the aspect ratio based on the actual loaded image.
                if let image = response.result.value
                    where image.size.width > 0 && image.size.height > 0 {
                    
                    let newAspectRatio = image.size.width / image.size.height
                    
                    if newAspectRatio != self!.aspectRatio {
                        self!.aspectRatio = newAspectRatio
                        // TODO: this will only affect future uses of this page. Somehow trigger a re-layout from the verso. Maybe in the delegate?
                    }
                }
                
                self!.imageLoadState = .Loaded
                
                self!.delegate?.didLoadPDFPublicationPageImage?(self!, imageURL:imageURL, fromCache:(response.response == nil))
            }
            else {
                
                if let error = response.result.error {
                    if error.code == NSURLErrorCancelled {
                        self!.imageLoadState = .NotLoaded
                        return // image load cancelled
                    }
                }
                // TODO: handle failed image load
                // tell delegate? show error? retry?
                // maybe cache failed image urls to re-fail quickly?
                print("image load failed", response.result.error?.localizedDescription, response.result.error?.code)
                
                self!.imageLoadState = .Failed
            }
        }
    }
    
    public func clearZoomImage(animated animated:Bool) {
        zoomImageView.af_cancelImageRequest()
        zoomImageLoadState = .NotLoaded
        
        if animated {
            UIView.transitionWithView(zoomImageView, duration: 0.3, options: [.TransitionCrossDissolve], animations: { [weak self] in
                self?.zoomImageView.image = nil
                self?.zoomImageView.hidden = true
                }, completion: nil)
        }
        else {
            zoomImageView.image = nil
            zoomImageView.hidden = true
        }
    }
    
    public func configure(viewModel: PDFPublicationPageViewModelProtocol) {
        
        reset()
        
        // cancel any previous image loads
        
        aspectRatio = CGFloat(viewModel.aspectRatio)
        
        pageLabel.text = viewModel.pageTitle
        
        
        if let imageURL = viewModel.defaultImageURL {
            startLoadingImageFromURL(imageURL)
        }
        
        delegate?.didConfigurePDFPublicationPage?(self, viewModel: viewModel)
    }

    

    
    // MARK: - Private
    
    private var aspectRatio:CGFloat = 0

    private func reset() {
        imageView.af_cancelImageRequest()
        imageView.image = nil
        imageLoadState = .NotLoaded
        
        zoomImageView.af_cancelImageRequest()
        zoomImageView.image = nil
        zoomImageView.hidden = true
        zoomImageLoadState = .NotLoaded
        
        pageLabel.text = nil
        aspectRatio = 0
    }
    
    
    
    
    // MARK: - Subviews
    
    private var pageLabel:UILabel = {
        
        let view = UILabel(frame: CGRectZero)
        view.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
        view.textAlignment = .Center
        
        return view
    }()
    
    private var imageView:UIImageView = {
        let view = UIImageView(frame: CGRectZero)
        
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.contentMode = .ScaleAspectFit
        
        return view
    }()
    
    private var zoomImageView:UIImageView = {
        let view = UIImageView(frame: CGRectZero)
        
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.contentMode = .ScaleAspectFit
        
        return view
    }()
    
    
    
    
    
    
    
    // MARK: - UIView subclass
    
    // size based on aspect ratio
    override public func sizeThatFits(size: CGSize) -> CGSize {
        guard size.width > 0 && size.height > 0 else {
            return size
        }
        
        var newSize = size
        
        let containerAspectRatio = size.width / size.height
        
        if aspectRatio < containerAspectRatio {
            newSize.width = newSize.height * aspectRatio
        }
        else if aspectRatio > containerAspectRatio {
            newSize.height = newSize.width / aspectRatio
        }
        
        return newSize
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // position label in the middle
        var labelFrame = pageLabel.frame
        labelFrame.size = pageLabel.sizeThatFits(frame.size)
        labelFrame.origin = CGPoint(x:round(bounds.size.width/2 - labelFrame.size.width/2), y:round(bounds.size.height/2 - labelFrame.size.height/2))
        
        pageLabel.frame = labelFrame
        
        imageView.frame = bounds
        zoomImageView.frame = bounds
    }
    
    
    
    // MARK: - Notifications
    
    func memoryWarningNotification(notification:NSNotification) {
        clearZoomImage(animated:true)
    }
    
    
    
    // MARK: - Gestures
    
    private var touchGesture:UILongPressGestureRecognizer?
    private var tapGesture:UITapGestureRecognizer?
    private var longPressGesture:UILongPressGestureRecognizer?
    private var longPressStartDate:NSDate?
    
    private func _initializeGestureRecognizers() {
        
        touchGesture = UILongPressGestureRecognizer(target: self, action:#selector(PDFPublicationPageView.didTouch(_:)))
        touchGesture!.minimumPressDuration = 0.01
        touchGesture!.cancelsTouchesInView = false
        touchGesture!.delaysTouchesBegan = false
        touchGesture!.delaysTouchesEnded = false
        touchGesture!.delegate = self
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(PDFPublicationPageView.didTap(_:)))
        tapGesture!.delegate = self
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action:#selector(PDFPublicationPageView.didLongPress(_:)))
        longPressGesture!.delegate = self
        
        
        addGestureRecognizer(longPressGesture!)
        addGestureRecognizer(tapGesture!)
        addGestureRecognizer(touchGesture!)
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture ||
            gestureRecognizer == touchGesture ||
            gestureRecognizer == longPressGesture {
            return true
        }
        else {
            return false
        }
    }
    
    
    
    func didTouch(touch:UILongPressGestureRecognizer) {
        guard touch.state == .Began else {
            return
        }
        guard bounds.size.width > 0 && bounds.size.height > 0 else {
            return
        }
        
        
        var location = touch.locationInView(self)
        location.x = location.x / bounds.size.width
        location.y = location.y / bounds.size.height
        
        delegate?.didTouchPDFPublicationPage?(self, location: location)
    }
    
    func didTap(tap:UITapGestureRecognizer) {
        guard bounds.size.width > 0 && bounds.size.height > 0 else {
            return
        }
        
        var location = tap.locationInView(self)
        location.x = location.x / bounds.size.width
        location.y = location.y / bounds.size.height
        
        delegate?.didTapPDFPublicationPage?(self, location: location)
    }
    
    func didLongPress(press:UILongPressGestureRecognizer) {
        guard bounds.size.width > 0 && bounds.size.height > 0 else {
            return
        }
        
        var location = press.locationInView(self)
        location.x = location.x / bounds.size.width
        location.y = location.y / bounds.size.height
        
        if press.state == .Began {
            longPressStartDate = NSDate()
            delegate?.didStartLongPressPDFPublicationPage?(self, location: location, duration:press.minimumPressDuration)
        }
        else if press.state == .Ended {
            var duration = longPressStartDate?.timeIntervalSinceNow ?? 0
            duration = -duration + press.minimumPressDuration
            delegate?.didEndLongPressPDFPublicationPage?(self, location: location, duration:duration)
        }
    }

}