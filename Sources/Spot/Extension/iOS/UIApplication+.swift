//
//  UIApplication+.swift
//  Spot iOS
//
//  Created by Shawn Clovie on 16/1/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

#if canImport(UIKit)
import UIKit

private var networkActivityIndicatorVisibleCount = SynchronizableValue(0)

extension Suffix where Base: UIApplication {
	
	// MARK: - NetworkActivityIndicator
	public var isNetworkActivityIndicatorVisible: Bool {
		networkActivityIndicatorVisibleCount.get() > 0
	}
	
	public func set(networkActivityIndicatorVisible visible: Bool) {
		let count = networkActivityIndicatorVisibleCount.get() + (visible ? 1 : -1)
		if count >= 0 {
			networkActivityIndicatorVisibleCount.waitAndSet(count)
			DispatchQueue.main.async {
				self.base.isNetworkActivityIndicatorVisible = count > 0
			}
		}
	}
	
	// MARK: - UserNotification
	
	/// Present UserNotification request dialog, it would only worked once.
	public func requestUserNotificationAuthorization() {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
				if granted {
					self.requestDeviceToken()
				}
			}
		} else {
			let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
			UIApplication.shared.registerUserNotificationSettings(settings)
		}
	}
	
	public func requestDeviceToken() {
		#if !(arch(i386) || arch(x86_64))
		DispatchQueue.main.async {
			UIApplication.shared.registerForRemoteNotifications()
		}
		#endif
	}

	// MARK: -
	
	public func open(_ url: URL, options: [String: Any] = [:], completion: ((Bool)->Void)? = nil) {
		if #available(iOS 10.0, *) {
			var opts: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
			for it in options {
				opts[.init(rawValue: it.key)] = it.value
			}
			base.open(url, options: opts, completionHandler: completion)
		} else {
			let opened = base.openURL(url)
			if let fn = completion {
				DispatchQueue.main.spot.async(opened, fn)
			}
		}
	}
	
	public func beginBackgroundTask(invocation: (@escaping ()->Void)->Void) {
		func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
			base.endBackgroundTask(task)
			task = .invalid
		}
		var bgTask = UIBackgroundTaskIdentifier.invalid
		bgTask = base.beginBackgroundTask(expirationHandler: {
			endBackgroundTask(&bgTask)
		})
		invocation {
			endBackgroundTask(&bgTask)
		}
	}
}
#endif
