//
//  ViewController.swift
//  TwitterLogin
//
//  Created by Victor Hugo on 2017-01-18.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import UIKit
import Accounts
import Social
import Kinvey

class ViewController: UIViewController {

    @IBOutlet weak var userLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func twitterAccount(handler: @escaping (Bool, [ACAccount]?) -> Void) {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)!
        
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { (granted, error) in
            if granted, let accounts = accountStore.accounts(with: accountType) as? [ACAccount] {
                DispatchQueue.main.async {
                    handler(granted, accounts)
                }
            } else {
                DispatchQueue.main.async {
                    handler(granted, nil)
                }
            }
        }
    }
    
    func requestToken(twitterAccount: ACAccount, completionHandler: @escaping User.UserHandler) {
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: .POST,
            url: URL(string: "https://api.twitter.com/oauth/request_token")!,
            parameters: [
                "x_auth_mode" : "reverse_auth"
            ]
        )!
        request.account = twitterAccount
        request.perform { data, response, error in
            if let response = response,
                response.statusCode == 200,
                let data = data,
                let signedReverseAuthSignature = String(data: data, encoding: .utf8),
                let regex = try? NSRegularExpression(pattern: "oauth_consumer_key=\"(.*)\""),
                let textCheckingResult = regex.firstMatch(in: signedReverseAuthSignature, range: NSMakeRange(0, signedReverseAuthSignature.characters.count)),
                textCheckingResult.numberOfRanges > 1
            {
                let range = textCheckingResult.rangeAt(1)
                let consumerKey = (signedReverseAuthSignature as NSString).substring(with: range)
                self.accessToken(twitterAccount: twitterAccount, consumerKey: consumerKey, signedReverseAuthSignature: signedReverseAuthSignature, completionHandler: completionHandler)
            }
        }
    }
    
    func accessToken(twitterAccount: ACAccount, consumerKey: String, signedReverseAuthSignature: String, completionHandler: @escaping User.UserHandler) {
        let request = SLRequest(
            forServiceType: SLServiceTypeTwitter,
            requestMethod: .POST,
            url: URL(string: "https://api.twitter.com/oauth/access_token")!,
            parameters: [
                "x_reverse_auth_target" : consumerKey,
                "x_reverse_auth_parameters" : signedReverseAuthSignature
            ]
        )!
        request.account = twitterAccount
        request.perform { (data, response, error) in
            if let response = response,
                response.statusCode == 200,
                let data = data,
                let string = String(data: data, encoding: .utf8),
                let regex = try? NSRegularExpression(pattern: "([^=&]*)=([^&]*)")
            {
                var authData = [String : String]()
                for textCheckingResult in regex.matches(in: string, range: NSMakeRange(0, string.characters.count)) {
                    if textCheckingResult.numberOfRanges > 2 {
                        let key = (string as NSString).substring(with: textCheckingResult.rangeAt(1))
                        let value = (string as NSString).substring(with: textCheckingResult.rangeAt(2))
                        authData[key] = value
                    }
                }
                if authData.count > 0 {
                    User.login(authSource: .twitter, authData, completionHandler: completionHandler)
                }
            }
        }
    }
    
    func login(twitterAccount: ACAccount, completionHandler: @escaping User.UserHandler) {
        self.requestToken(twitterAccount: twitterAccount, completionHandler: completionHandler)
    }

    @IBAction func login(_ sender: Any) {
        userLabel.text = "Loading..."
        twitterAccount { granted, twitterAccounts in
            if granted {
                if let twitterAccounts = twitterAccounts, let twitterAccount = twitterAccounts.first {
                    self.login(twitterAccount: twitterAccount) { user, error in
                        if let user = user {
                            print("\(user)")
                            self.userLabel.text = "User ID: \(user.userId)"
                        } else if let error = error {
                            print("\(error)")
                            self.userLabel.text = error.localizedDescription
                        }
                    }
                } else {
                    self.userLabel.text = "Twitter Account Not Found"
                }
            } else {
                self.userLabel.text = "Not Allowed to access Twitter Accounts"
            }
        }
    }

}
