//
//  PhotoViewerViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-24.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import QuartzCore
import Alamofire

class PhotoViewerViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, UIActionSheetDelegate {
  var photoID: Int = 0
  
  let scrollView = UIScrollView()
  let imageView = UIImageView()
  let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
  
  var photoInfo: PhotoInfo?
  
  // MARK: Life-Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupView()
    loadPhoto()
    
  }
    func downloadImage() {
         }
  
    func loadPhoto() {
      Alamofire.request(Five100px.Router.PhotoInfo(self.photoID, .Large)).validate().responseObject() { //<#completionHandler: (NSURLRequest, NSHTTPURLResponse?, T?, NSError?) -> Void##(NSURLRequest, NSHTTPURLResponse?, T?, NSError?) -> Void#>
            //(_, _, photoInfo: PhotoInfo?, error) in是响应序列化方法的参数。刚开始的两个下划线"_"意味着我们忽略了前两个参数，我们无需明确地将它们明确命名为request和response。
            //第三个参数明确被声明为了我们的PhotoInfo实例，因此通用序列化方法将自行初始化，并返回该类型的一个对象，其包含有图片 URL。第二个 Alamofire 请求使用您先前创建过的图片序列化方法，将NSData转化为UIImage，以便之后我们在图片视图中显示它。
            (_, _, photoInfo: PhotoInfo?, error) in
            
            //注意：我们不在这里使用路由，因为我们已经有了图片的绝对 URL 地址，我们无需自行构造 URL。
            

            
            if error == nil {
                self.photoInfo = photoInfo
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.addButtomBar()
                    self.title = photoInfo?.name
                })
            }
            
            Alamofire.request( .GET, photoInfo!.url).validate().responseImage() {
                (_, _, image, error) in
                if error == nil && image != nil {
                    self.imageView.image = image
                    self.imageView.frame = self.centerFrameFromImage(image)
                    
                    self.spinner.stopAnimating()
                    self.centerScrollViewContents()
                }
            }
            
            
        }
    }
    
  func setupView() {
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    spinner.center = CGPoint(x: view.center.x, y: view.center.y - view.bounds.origin.y / 2.0)
    spinner.hidesWhenStopped = true
    spinner.startAnimating()
    view.addSubview(spinner)
    
    scrollView.frame = view.bounds
    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 3.0
    scrollView.zoomScale = 1.0
    view.addSubview(scrollView)
    
    imageView.contentMode = .ScaleAspectFill
    scrollView.addSubview(imageView)
    
    let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
    doubleTapRecognizer.numberOfTapsRequired = 2
    doubleTapRecognizer.numberOfTouchesRequired = 1
    scrollView.addGestureRecognizer(doubleTapRecognizer)
    
    let singleTapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
    singleTapRecognizer.numberOfTapsRequired = 1
    singleTapRecognizer.numberOfTouchesRequired = 1
    singleTapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
    scrollView.addGestureRecognizer(singleTapRecognizer)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if photoInfo != nil {
      navigationController?.setToolbarHidden(false, animated: true)
    }
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setToolbarHidden(true, animated: true)
  }
  
  // MARK: Bottom Bar
  
  func addButtomBar() {
    var items = [UIBarButtonItem]()
    
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    
    items.append(barButtonItemWithImageNamed("hamburger", title: nil, action: "showDetails"))
    
    if photoInfo?.commentsCount > 0 {
      items.append(barButtonItemWithImageNamed("bubble", title: "\(photoInfo?.commentsCount ?? 0)", action: "showComments"))
    }
    
    items.append(flexibleSpace)
    items.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "showActions"))
    items.append(flexibleSpace)
    
    items.append(barButtonItemWithImageNamed("like", title: "\(photoInfo?.votesCount ?? 0)"))
    items.append(barButtonItemWithImageNamed("heart", title: "\(photoInfo?.favoritesCount ?? 0)"))
    
    self.setToolbarItems(items, animated: true)
    navigationController?.setToolbarHidden(false, animated: true)
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: userInfoViewForPhotoInfo(photoInfo!))
  }
  
  func userInfoViewForPhotoInfo(photoInfo: PhotoInfo) -> UIView {
    let userProfileImageView = UIImageView(frame: CGRect(x: 0, y: 10.0, width: 30.0, height: 30.0))
    userProfileImageView.layer.cornerRadius = 3.0
    userProfileImageView.layer.masksToBounds = true
    
    return userProfileImageView
  }

  func showDetails() {
    let photoDetailsViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetails") as? PhotoDetailsViewController
    photoDetailsViewController?.modalPresentationStyle = .OverCurrentContext
    photoDetailsViewController?.modalTransitionStyle = .CoverVertical
    photoDetailsViewController?.photoInfo = photoInfo
    
    presentViewController(photoDetailsViewController!, animated: true, completion: nil)
  }
  
  func showComments() {
    let photoCommentsViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoComments") as? PhotoCommentsViewController
    photoCommentsViewController?.modalPresentationStyle = .Popover
    photoCommentsViewController?.modalTransitionStyle = .CoverVertical
    photoCommentsViewController?.photoID = photoID
    photoCommentsViewController?.popoverPresentationController?.delegate = self
    presentViewController(photoCommentsViewController!, animated: true, completion: nil)
  }
  
  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
    return UIModalPresentationStyle.OverCurrentContext
  }
  
  func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
    let navController = UINavigationController(rootViewController: controller.presentedViewController)
    
    return navController
  }
  
  func barButtonItemWithImageNamed(imageName: String?, title: String?, action: Selector? = nil) -> UIBarButtonItem {
    let button = UIButton.buttonWithType(.Custom) as! UIButton
    
    if imageName != nil {
      button.setImage(UIImage(named: imageName!)!.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
    
    if title != nil {
      button.setTitle(title, forState: .Normal)
      button.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 0.0)
      
      let font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
      button.titleLabel?.font = font
    }
    
    let size = button.sizeThatFits(CGSize(width: 90.0, height: 30.0))
    button.frame.size = CGSize(width: min(size.width + 10.0, 60), height: size.height)
    
    if action != nil {
      button.addTarget(self, action: action!, forControlEvents: .TouchUpInside)
    }
    
    let barButton = UIBarButtonItem(customView: button)
    
    return barButton
  }
  
  // MARK: Download Photo
  
  func showActions() {
    let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Download Photo")
    actionSheet.showFromToolbar(navigationController?.toolbar)
  }
  
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    if buttonIndex == 1 {
      downloadPhoto()
    }
  }
  
  func downloadPhoto() {
    
//    Alamofire.request(<#method: Method#>, <#URLString: URLStringConvertible#>, parameters: <#[String : AnyObject]?#>, encoding: <#ParameterEncoding#>)
    
    //1 You first request a new PhotoInfo, only this time asking for an XLarge size image.
    Alamofire.request(Five100px.Router.PhotoInfo(photoInfo!.id, .XLarge)).validate().responseObject() {
        (_, _, photoInfo: PhotoInfo?, error) in
        
        if error == nil && photoInfo != nil {
//            let jsonDictionary = JSON as! NSDictionary
//            let imageURL = jsonDictionary.valueForKeyPath("photo.image_url") as! String
            let imageURL = photoInfo!.url
            
            //2 Get the default location on disk to which to save your files — this will be a subdirectory in the Documents directory of your app. The name of the file on disk will be the same as the name that the server suggests. destination is a closure in disguise — more on that in just a moment.
            //                let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory , domain:  .UserDomainMask)
            let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
                (temporaryURL, response) in
                if let direcoryURL = NSFileManager.defaultManager().URLsForDirectory( .DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                    return direcoryURL.URLByAppendingPathComponent("\(self.photoInfo?.id).\(response.suggestedFilename)")
                }
                return temporaryURL
            }
            
            //3 Alamofire.download(_:_:_) is a bit different than Alamofire.request(_:_) in that it doesn’t need a response handler or a serializer in order to perform an operation on the data, as it already knows what to do with it — save it to disk! The destination closure returns the location of the saved image.
            
            //                Alamofire.download(.GET, imageURL, destination)
            // 4
            let progressIndicatorView = UIProgressView(frame: CGRect(x: 0.0, y: 80.0, width: self.view.bounds.width, height: 10.0))
            progressIndicatorView.tintColor = UIColor.redColor()
            self.view.addSubview(progressIndicatorView)
            
            // 5
            Alamofire.download(.GET, imageURL, destination).progress {
                (_, totalBytesRead, totalBytesExpectedToRead) in
                
                dispatch_async(dispatch_get_main_queue()) {
                    // 6
                    progressIndicatorView.setProgress(Float(totalBytesRead) / Float(totalBytesExpectedToRead), animated: true)
                    println("progress: \(Float(totalBytesRead) / Float(totalBytesExpectedToRead))")
                    
                    // 7
                    if totalBytesRead == totalBytesExpectedToRead {
                        progressIndicatorView.removeFromSuperview()
                    }
                }
            }
            
        }
    }
    

    
  }
  
  // MARK: Gesture Recognizers
  
  func handleDoubleTap(recognizer: UITapGestureRecognizer!) {
    let pointInView = recognizer.locationInView(self.imageView)
    self.zoomInZoomOut(pointInView)
  }
  
  func handleSingleTap(recognizer: UITapGestureRecognizer!) {
    let hidden = navigationController?.navigationBar.hidden ?? false
    navigationController?.setNavigationBarHidden(!hidden, animated: true)
    navigationController?.setToolbarHidden(!hidden, animated: true)
    UIApplication.sharedApplication().setStatusBarHidden(!hidden, withAnimation: .Slide)
  }
  
  // MARK: ScrollView
  
  func centerFrameFromImage(image: UIImage?) -> CGRect {
    if image == nil {
      return CGRectZero
    }
    
    let scaleFactor = scrollView.frame.size.width / image!.size.width
    let newHeight = image!.size.height * scaleFactor
    
    var newImageSize = CGSize(width: scrollView.frame.size.width, height: newHeight)
    
    newImageSize.height = min(scrollView.frame.size.height, newImageSize.height)
    
    let centerFrame = CGRect(x: 0.0, y: scrollView.frame.size.height/2 - newImageSize.height/2, width: newImageSize.width, height: newImageSize.height)
    
    return centerFrame
  }
  
  func scrollViewDidZoom(scrollView: UIScrollView) {
    self.centerScrollViewContents()
  }
  
  func centerScrollViewContents() {
    let boundsSize = scrollView.frame
    var contentsFrame = self.imageView.frame
    
    if contentsFrame.size.width < boundsSize.width {
      contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
    } else {
      contentsFrame.origin.x = 0.0
    }
    
    if contentsFrame.size.height < boundsSize.height {
      contentsFrame.origin.y = (boundsSize.height - scrollView.scrollIndicatorInsets.top - scrollView.scrollIndicatorInsets.bottom - contentsFrame.size.height) / 2.0
    } else {
      contentsFrame.origin.y = 0.0
    }
    
    self.imageView.frame = contentsFrame
  }
  
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return self.imageView
  }
  
  func zoomInZoomOut(point: CGPoint!) {
    let newZoomScale = self.scrollView.zoomScale > (self.scrollView.maximumZoomScale/2) ? self.scrollView.minimumZoomScale : self.scrollView.maximumZoomScale
    
    let scrollViewSize = self.scrollView.bounds.size
    
    let width = scrollViewSize.width / newZoomScale
    let height = scrollViewSize.height / newZoomScale
    let x = point.x - (width / 2.0)
    let y = point.y - (height / 2.0)
    
    let rectToZoom = CGRect(x: x, y: y, width: width, height: height)
    
    self.scrollView.zoomToRect(rectToZoom, animated: true)
  }
}
