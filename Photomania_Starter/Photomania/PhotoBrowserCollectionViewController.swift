//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var photos = NSMutableOrderedSet()
    
    let refreshControl = UIRefreshControl()
    var populationPhotos = false
    var currentPage = 1
    let imageCache = NSCache()
    
    
    
    let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
    
    // MARK: Life-cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        populatePhotos()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: CollectionView
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
        let imageUrl = (photos.objectAtIndex(indexPath.row) as! PhotoInfo).url
        //    Alamofire.request(.GET, imageUrl).response() {
        //        (_, _, data, _) in
        //        let image = UIImage(data: data! as! NSData)
        //        cell.imageView.image = image
        //    }
        //way2
//        cell.imageView.image = nil
//        cell.request = Alamofire.request(.GET, imageUrl).responseImage() {
//            //{ (<#NSURLRequest#>, <#NSHTTPURLResponse?#>, <#UIImage?#>, <#NSError?#>) -> Void in
//            (request, _, image, error) in
//            if error == nil && image != nil {
//                if request.URLString == cell.request?.request.URLString {
//                    cell.imageView.image = image
//                }
//            }
//        }
        //cache version
        //1 the dequeued cell may already have an Alamofire request attached to it. You can simply cancel it because it’s no longer valid for this new cell.
        cell.request?.cancel()
        //2 Use optional binding to check if you have a cached version of this photo. If so, use the cached version instead of downloading it again.
        if let image = self.imageCache.objectForKey(imageUrl) as? UIImage {
            cell.imageView.image = image
        } else {
            //3 If you don’t have a cached version of the photo, download it. However, the the dequeued cell may be already showing another image; in this case, set it to nil so that the cell is blank while the requested photo is downloaded.
            cell.imageView.image = nil
            //4  Download the image from the server, but this time validate the content-type of the returned response. If it’s not an image, error will contain a value and therefore you won’t do anything with the potentially invalid image response. The key here is that you you store the Alamofire request object in the cell, for use when your asynchronous network call returns.
            cell.request = Alamofire.request(.GET, imageUrl).validate(contentType: ["image/*"]).responseImage() {
                (request, _, image, error) in
                if error == nil && image != nil {
                    //5 If you did not receive an error and you downloaded a proper photo, cache it for later.
                    self.imageCache.setObject(image!, forKey: request.URLString)
                    //6 Set the cell’s image accordingly.
                    cell.imageView.image = image
                } else {
                    /*
                    If the cell went off-screen before the image was downloaded, we cancel it and
                    an NSURLErrorDomain (-999: cancelled) is returned. This is a normal behavior.
                    */
                }
            }
        }
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowPhoto", sender: (self.photos.objectAtIndex(indexPath.item) as! PhotoInfo).id)
    }
    
    // MARK: Helper
    
    
    func setupView() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (view.bounds.size.width - 2) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
        
        collectionView!.collectionViewLayout = layout
        
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 60.0, height: 30.0))
        titleLabel.text = "Photomania"
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        navigationItem.titleView = titleLabel
        
        collectionView!.registerClass(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
        collectionView!.registerClass(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
        
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: "handleRefresh", forControlEvents: .ValueChanged)
        collectionView!.addSubview(refreshControl)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPhoto" {
            (segue.destinationViewController as! PhotoViewerViewController).photoID = sender!.integerValue
            (segue.destinationViewController as! PhotoViewerViewController).hidesBottomBarWhenPushed = true
        }
    }
    //MARK -
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        // 一旦您滚动超过了 80% 的页面，那么scrollViewDidScroll()方法将会加载更多的图片。
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
            populatePhotos()
        }
    }
    
    
    func handleRefresh() {
        
        refreshControl.beginRefreshing()
        self.photos.removeAllObjects()
        self.currentPage = 1
        self.collectionView?.reloadData()
        populatePhotos()
        refreshControl.endRefreshing()
    }
    
    func populatePhotos() {
        //2.populatePhotos()方法在currentPage当中加载图片，并且使用populatingPhotos作为标记，以防止还在加载当前界面时加载下一个页面。
        if populationPhotos {
            return
        }
        populationPhotos = true
        
        //        Alamofire.request( .GET, "https://api.500px.com/v1/photos", parameters:["consumer_key" : "pdGG0ze5dXKbNXOtlqFKAoBCf8azKNn8dqF47q6M"]).responseJSON() /*当网络请求完毕后，responseJSON()方法会调用我们所提供的闭包, 在这里我们只是简单的将经过解析的 JSON 输出到控制台中*/ {
        //            //        (req, response, object, error) in
        //            (_, _, JSON, error) in
        //            println(JSON)
        //            if error != nil {
        //                return;
        //            }
        //
        //            let photoInfos = ((JSON as! NSDictionary).valueForKey("photos") as! [NSDictionary]).filter({ ($0["nsfw"] as! Bool) == false }).map { PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String) }
        //
        //            self.photos.addObjectsFromArray(photoInfos)
        //            self.collectionView?.reloadData()
        //        }
        //这里我们首次使用了我们创建的路由。只需将页数传递进去，它将为该页面构造 URL 字符串。500px.com 网站在每次 API 调用后返回大约50张图片，因此您需要为下一批照片的显示再次调用路由。
        Alamofire.request(Five100px.Router.PopularPhotos(self.currentPage)).responseJSON() {
            (_, _, JSON, error) in
            println(JSON)
            
            if error == nil {
                // 要注意，.responseJSON()后面的代码块：completion handler(完成处理方法)必须在主线程运行。如果您正在执行其他的长期运行操作，比如说调用 API，那么您必须使用 GCD 来将您的代码调度到另一个队列运行。在本示例中，我们使用`DISPATCH_QUEUE_PRIORITY_HIGH`来运行这个操作。
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    // 您可能会关心 JSON 数据中的photos关键字，其位于数组中的字典中。每个字典都包含有一张图片的信息。
                    // 我们使用 Swift 的filter函数来过滤掉 NSFW 图片（Not Safe For Work）
                    //map函数接收了一个闭包，然后返回一个PhotoInfo对象的数组。这个类是在Five100px.swift当中定义的。如果您查看这个类的源码，那么就可以看到它重写了isEqual和hash这两个方法。这两个方法都是用一个整型的id属性，因此排序和唯一化（uniquing）PhotoInfo对象仍会是一个比较快的操作
                    let photoInfos = ((JSON as! NSDictionary).valueForKey("photos") as! [NSDictionary]).filter( {
                        ($0["nsfw"] as! Bool) == false } ).map {
                            PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String)
                    }
                    //接下来我们会在添加新的数据前存储图片的当前数量，使用它来更新collectionView.
                    let lastItem = self.photos.count
                    //如果有人在我们滚动前向 500px.com 网站上传了新的图片，那么您所获得的新的一批照片将可能会包含一部分已下载的图片。这就是为什么我们定义var photos = NSMutableOrderedSet()为一个组。由于组内的项目必须唯一，因此重复的图片不会再次出现
                    self.photos.addObjectsFromArray(photoInfos)
                    //这里我们创建了一个NSIndexPath对象的数组，并将其插入到collectionView.
                    let indexPath = (lastItem..<self.photos.count).map {NSIndexPath(forItem: $0, inSection: 0)}
                    //在集合视图中插入项目，请在主队列中完成该操作，因为所有的 UIKit 操作都必须运行在主队列中
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView?.insertItemsAtIndexPaths(indexPath)
                    }
                    self.currentPage++
                }
            }
            self.populationPhotos = false
        }
        
    }
    
    
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    var request:  Alamofire.Request?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        imageView.frame = bounds
        addSubview(imageView)
        
    }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        spinner.startAnimating()
        spinner.center = self.center
        addSubview(spinner)
    }
}
