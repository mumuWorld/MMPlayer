//
//  AppDelegate.swift
//  MMPlayer
//
//  Created by mumu on 2019/8/13.
//  Copyright © 2019 Mumu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        let rootVC = MQTabbarController()
//        let navi = MMBaseNavigationViewController(rootViewController: rootVC)
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var openInPlace = false
        if let place = options[.openInPlace] as? Bool {
            openInPlace = place
        }
        var sourceApp = ""
        if let source = options[.sourceApplication] as? String {
            sourceApp = source
        }
        var annotation = ""
        if let ann = options[.annotation] as? String {
            annotation = ann
        }
        MMPrintLog(message: url.absoluteString + ",openInPlace->" + String(openInPlace) + ",source->" + sourceApp + ",annot->" + annotation)
        MMPrintLog(message: options)
        
        // 检查是否为自定义 URL scheme
        if url.scheme == "mmplayer" {
            return handleCustomURLScheme(url: url)
        }
        
        MMToastView.show(message:"收到文件" + url.lastPathComponent)
        MMHandleFileTool.handleOpenFile(url: url)
        
        return true
    }
    
    func handleCustomURLScheme(url: URL) -> Bool {
        guard let host = url.host, (host == "video" || host == "audio") else { return false }
        
        // 解析 URL 参数
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let queryItems = components?.queryItems,
              let pathItem = queryItems.first(where: { $0.name == "path" }),
              let mediaPath = pathItem.value,
              let mediaURL = URL(string: mediaPath) else {
            return false
        }
        
        let mediaType = host == "video" ? "视频" : "音频"
        MMToastView.show(message: "从扩展接收\(mediaType): \(mediaURL.lastPathComponent)")
        
        // 直接处理媒体文件
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            MMHandleFileTool.handleOpenFile(url: mediaURL)
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        MMPrintLog(message: "取消激活")
        application.beginReceivingRemoteControlEvents()
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        MMPrintLog(message: "已经进入后台")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

