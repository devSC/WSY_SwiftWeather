//
//  Five100px.swift
//  Photomania
//
//  Created by Essan Parto on 2014-09-25.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire
/* 
将需要暴露给 Objective-C 使用的任何地方 (包括类，属性和方法等) 的声明前面加上 @objc 修饰符。注意这个步骤只需要对那些不是继承自 NSObject 的类型进行，如果你用 Swift 写的 class 是继承自 NSObject 的话，Swift 会默认自动为所有的非 private 的类和成员加上 @objc。这就是说，对一个 NSObject 的子类，你只需要导入相应的头文件就可以在 Objective-C 里使用这个类了。

@objc 修饰符的另一个作用是为 Objective-C 侧重新声明方法或者变量的名字。虽然绝大部分时候自动转换的方法名已经足够好用 (比如会将 Swift 中类似 init(name: String) 的方法转换成 -initWithName:(NSString *)name 这样)，但是有时候我们还是期望 Objective-C 里使用和 Swift 中不一样的方法名或者类的名字，比如 Swift 里这样的一个类：

class 我的类 {
func 打招呼(名字: String) {
println("哈喽，\(名字)")
}
}

我的类().打招呼("小明")
Objective-C 的话是无法使用中文来进行调用的，因此我们必须使用 @objc 将其转为 ASCII 才能在 Objective-C 里访问：

@objc(MyClass)
class 我的类 {
@objc(greeting:)
func 打招呼(名字: String) {
println("哈喽，\(名字)")
}
}
我们在 Objective-C 里就能调用 [[MyClass new] greeting:@"XiaoMing"] 这样的代码了 (虽然比起原来一点都不好玩了)。另外，正如上面所说的以及在 Selector 一节中所提到的，即使是 NSObject 的子类，Swift 也不会在被标记为 private 的方法或成员上自动加 @objc。如果我们需要使用这些内容的动态特性的话，我们需要手动给它们加上 @objc 修饰。

添加 @objc 修饰符并不意味着这个方法或者属性会变成动态派发，Swift 依然可能会将其优化为静态调用。如果你需要和 Objective-C 里动态调用时相同的运行时特性的话，你需要使用的修饰符是 dynamic。一般情况下在做 app 开发时应该用不上，但是在施展一些像动态替换方法或者运行时再决定实现这样的 "黑魔法" 的时候，我们就需要用到 dynamic 修饰符了。在之后的 KVO 一节中，我们还会提到一个关于使用 dynamic 的实例。
*/
//http://www.raywenderlich.com/87595/intermediate-alamofire-tutorial
//http://www.cocoachina.com/ios/20141203/10514.html
@objc public protocol ResponseCollectionSerializable {
    static func collection(#responser: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}
extension Alamofire.Request {
    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, [T]?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options:  .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if response != nil && JSON != nil {
                return (T.collection(responser: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        return response(serializer: serializer, completionHandler: { (request, response, object, error) -> Void in
            completionHandler(request, response, object as? [T], error)
        })
    }
}

@objc public protocol ResponseObjectSerializable {
    init(response: NSHTTPURLResponse, representation: AnyObject)
}
extension Alamofire.Request {
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, T?, NSError?) ->Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if response != nil && JSON != nil {
                return (T(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: {(request, response, object, error) in
            completionHandler(request, response, object as? T, error)
        })
    }
}


extension Alamofire.Request {
    class func imageResponseSerialize() -> Serializer {
        return {
            request, response, data in
            if data == nil {
                return (nil, nil)
            }
            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            return (image, nil)
        }
    }
    
    func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), serializer: Request.imageResponseSerialize(), completionHandler: { (request, response, image, error) -> Void in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
    
}
struct Five100px {
    enum Router: URLRequestConvertible {

        static let baseURLString = "https://api.500px.com/v1"
        static let consumerKey = "pdGG0ze5dXKbNXOtlqFKAoBCf8azKNn8dqF47q6M"
//        https://api.500px.com/v1/photos
        case PopularPhotos(Int)
        case PhotoInfo(Int, ImageSize)
        case Comments(Int, Int)
        var URLRequest: NSURLRequest {
            let (path: String, parameters: [String: AnyObject]) = {
                switch self {
                case .PopularPhotos (let page):
                    let params = ["consumer_key": Router.consumerKey, "page": "\(page)", "feature" : "popular", "rpp": "50", "include_store": "store_download", "include_states" : "votes"]
                    return ("/photos", params)
                case .PhotoInfo(let photoID, let ImageSize):
                    var params = ["consumer_key" : Router.consumerKey, "image_size": "\(ImageSize.rawValue)"]
                    return ("/photos/\(photoID)", params)
                case .Comments(let photoID, let commentsPage):
                    var params = ["consumer_key": Router.consumerKey, "comments": "1", "comments_page" : "\(commentsPage)"]
                    return ("/photos/\(photoID)/comments", params)
                }
            }()
            let URL = NSURL(string: Router.baseURLString)
            let URLRequest = NSURLRequest(URL: URL!.URLByAppendingPathComponent(path))
            let encoding = Alamofire.ParameterEncoding.URL
            return encoding.encode(URLRequest, parameters: parameters).0
        }
    }
    
  enum ImageSize: Int {
    case Tiny = 1
    case Small = 2
    case Medium = 3
    case Large = 4
    case XLarge = 5
  }
  
  enum Category: Int, Printable {
    case Uncategorized = 0, Celebrities, Film, Journalism, Nude, BlackAndWhite, StillLife, People, Landscapes, CityAndArchitecture, Abstract, Animals, Macro, Travel, Fashion, Commercial, Concert, Sport, Nature, PerformingArts, Family, Street, Underwater, Food, FineArt, Wedding, Transportation, UrbanExploration
    
    var description: String {
      get {
        switch self {
        case .Uncategorized: return "Uncategorized"
        case .Celebrities: return "Celebrities"
        case .Film: return "Film"
        case .Journalism: return "Journalism"
        case .Nude: return "Nude"
        case .BlackAndWhite: return "Black And White"
        case .StillLife: return "Still Life"
        case .People: return "People"
        case .Landscapes: return "Landscapes"
        case .CityAndArchitecture: return "City And Architecture"
        case .Abstract: return "Abstract"
        case .Animals: return "Animals"
        case .Macro: return "Macro"
        case .Travel: return "Travel"
        case .Fashion: return "Fashion"
        case .Commercial: return "Commercial"
        case .Concert: return "Concert"
        case .Sport: return "Sport"
        case .Nature: return "Nature"
        case .PerformingArts: return "Performing Arts"
        case .Family: return "Family"
        case .Street: return "Street"
        case .Underwater: return "Underwater"
        case .Food: return "Food"
        case .FineArt: return "Fine Art"
        case .Wedding: return "Wedding"
        case .Transportation: return "Transportation"
        case .UrbanExploration: return "Urban Exploration"
        }
      }
    }
  }
}

class PhotoInfo: NSObject, ResponseObjectSerializable {
  let id: Int
  let url: String
  
  var name: String?
  
  var favoritesCount: Int?
  var votesCount: Int?
  var commentsCount: Int?
  
  var highest: Float?
  var pulse: Float?
  var views: Int?
  var camera: String?
  var focalLength: String?
  var shutterSpeed: String?
  var aperture: String?
  var iso: String?
  var category: Five100px.Category?
  var taken: String?
  var uploaded: String?
  var desc: String?
  
  var username: String?
  var fullname: String?
  var userPictureURL: String?
  
  init(id: Int, url: String) {
    self.id = id
    self.url = url
  }
  
  required init(response: NSHTTPURLResponse, representation: AnyObject) {
    self.id = representation.valueForKeyPath("photo.id") as! Int
    self.url = representation.valueForKeyPath("photo.image_url") as! String
    
    self.favoritesCount = representation.valueForKeyPath("photo.favorites_count") as? Int
    self.votesCount = representation.valueForKeyPath("photo.votes_count") as? Int
    self.commentsCount = representation.valueForKeyPath("photo.comments_count") as? Int
    self.highest = representation.valueForKeyPath("photo.highest_rating") as? Float
    self.pulse = representation.valueForKeyPath("photo.rating") as? Float
    self.views = representation.valueForKeyPath("photo.times_viewed") as? Int
    self.camera = representation.valueForKeyPath("photo.camera") as? String
    self.focalLength = representation.valueForKeyPath("photo.focal_length") as? String
    self.shutterSpeed = representation.valueForKeyPath("photo.shutter_speed") as? String
    self.aperture = representation.valueForKeyPath("photo.aperture") as? String
    self.iso = representation.valueForKeyPath("photo.iso") as? String
    self.taken = representation.valueForKeyPath("photo.taken_at") as? String
    self.uploaded = representation.valueForKeyPath("photo.created_at") as? String
    self.desc = representation.valueForKeyPath("photo.description") as? String
    self.name = representation.valueForKeyPath("photo.name") as? String
    
    self.username = representation.valueForKeyPath("photo.user.username") as? String
    self.fullname = representation.valueForKeyPath("photo.user.fullname") as? String
    self.userPictureURL = representation.valueForKeyPath("photo.user.userpic_url") as? String
  }
  
  override func isEqual(object: AnyObject!) -> Bool {
    return (object as! PhotoInfo).id == self.id
  }
  
  override var hash: Int {
    return (self as PhotoInfo).id
  }
}

final class Comment: ResponseCollectionSerializable {
    @objc static func collection(#responser: NSHTTPURLResponse, representation: AnyObject) -> [Comment] {
        var comments = [Comment]()
        
        for comment in representation.valueForKeyPath("comments") as! [NSDictionary] {
            comments.append(Comment(JSON: comment))
        }
        
        return comments
    }

    let userFullname: String
    let userPictureURL: String
    let commentBody: String
    
    init(JSON: AnyObject) {
        userFullname = JSON.valueForKeyPath("user.fullname") as! String
        userPictureURL = JSON.valueForKeyPath("user.userpic_url") as! String
        commentBody = JSON.valueForKeyPath("body") as! String
    }
}