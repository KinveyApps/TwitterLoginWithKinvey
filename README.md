# Twitter Login with Kinvey

*Before you run the project:*

Remeber to:

* Run [CocoaPods](https://cocoapods.org) in Terminal with the command `pod install`
* Change the `AppDelegate.swift` file with your own `appKey` and `appSecret`, for example:

```
Kinvey.sharedClient.initialize(appKey: "my app key", appSecret: "my app secret")
```

This project is using [Accounts](https://developer.apple.com/reference/accounts) and [Social](https://developer.apple.com/reference/social) frameworks to get the user account already setup in the device. Those frameworks also allow login with other social networks like Facebook and LinkedIn, but the HTTP requests are different in each case.
