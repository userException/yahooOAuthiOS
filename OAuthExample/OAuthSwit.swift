

import UIKit
import CommonCrypto
import CoreLocation

class OAuthSwit: UIViewController {

    private var miamiBeachGeoPos = CLLocationCoordinate2DMake(25.7907, 80.1300)
    
    @IBOutlet var lableWeatherDesc: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let authHeader = self.generateOAuth()
        
        let headers = ["Authorization":authHeader,
                       "Yahoo-App-Id": "RaG2iD6k",
                       "Content-Type": "application/json"
                       ]
        
        
        
        var mutableReq = URLRequest.init(url: URL.init(string: String.init(format: "https://weather-ydn-yql.media.yahoo.com/forecastrss?lat=%f&lon=%f&format=json", miamiBeachGeoPos.latitude, miamiBeachGeoPos.longitude))!)
        
        mutableReq.allHTTPHeaderFields = headers
        
        mutableReq.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: mutableReq) {[weak self] (data, response, apiError) in
        
            let urlresponse = response as? HTTPURLResponse
            
            var descString: String?
        
            if (apiError == nil && urlresponse?.statusCode == 200){
                
                if let apiData = data{
                    
                    do{
                        let weatherResult = try JSONSerialization.jsonObject(with: apiData, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                        
                        if let currentObservation = weatherResult["current_observation"] as? [String:Any],
                            let condition = currentObservation["condition"] as? [String:Any]{
                         
                            descString = String.init(format: "%@°F, %@", condition["temperature"] as! NSNumber, condition["text"] as! String)
                        }
                    }
                    catch {
                        descString = "Something went wrong!"
                    }
                }
                
            }else{
                if let connectionError = apiError{
                    descString = connectionError.localizedDescription
                }else{
                    descString = "Something went wrong!"
                }
            }
            
            DispatchQueue.main.async {
                guard let strongSelf = self else {return}
                
                strongSelf.lableWeatherDesc.text = descString;
            }
        }
        
        task.resume()
    }
    
    
    //MARK:- IBAction
    @IBAction func backTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil);
    }
    
    
    //MARK:- OAuth
    func generateOAuth() -> String{
        let apiURL = "https://weather-ydn-yql.media.yahoo.com/forecastrss"
        let oauth_consumer_key = "dj0yJmk9ZEZhRmZUZlp5cVBxJnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PWQ3";
        let consumerSecret = "e1e4d05015cf323cff95c343a92e6f737c93b7ea";
        let oauth_nonce = String.init(format: "%.0f", NSDate.init().timeIntervalSince1970);
        let oauth_signature_method = "HMAC-SHA1";
        let oauth_timestamp = String.init(format: "%.0f", NSDate.init().timeIntervalSince1970);
        let oauth_version = "1.0";
        
        let encodedApiURL = urlformdata_encode(targetString: apiURL);
        
        let allParams: NSDictionary = [
            "oauth_consumer_key": oauth_consumer_key,
            "oauth_nonce": oauth_nonce,
            "oauth_signature_method": oauth_signature_method,
            "oauth_timestamp": oauth_timestamp,
            "oauth_version": "1.0",
            "lat": String.init(format: "%f", miamiBeachGeoPos.latitude),
            "lon": String.init(format: "%f", miamiBeachGeoPos.longitude),
            "format": "json"]
        
        let parametersString = NSMutableString.init()
        
        let sortedKeys = (allParams.allKeys as! [String]).sorted(by: <)
        
        for aKey in sortedKeys{
            parametersString.append(String.init(format: "%@=%@&", aKey, allParams.object(forKey: aKey) as! String))
        }
        
        let finalString = parametersString.substring(to: parametersString.length-1)
        
        let encodedParameters = urlformdata_encode(targetString: finalString)
        
        var signature = String.init(format: "GET&%@&%@", encodedApiURL, encodedParameters)
        
        signature = hmac(targetString: signature, key: consumerSecret + "&")
        
        let authorizationHeader = String.init(format: "OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_timestamp=\"%@\", oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_version=\"%@\"", oauth_consumer_key, oauth_nonce, oauth_timestamp, oauth_signature_method, signature, oauth_version)
        
        return authorizationHeader
    }

    
    func urlformdata_encode(targetString: String?) -> String{
        
        guard let myString = targetString else{
            return ""
        }
        
        let customAllowedSet =  CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted
        
        guard let escapedString = myString.addingPercentEncoding(withAllowedCharacters: customAllowedSet) else{
            return ""
        }

        return escapedString
    }
    
    
    func hmac(targetString: String, key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, targetString, targetString.count, &digest)
        let data = Data(bytes: digest)
        return data.base64EncodedString()
    }
}
