import Foundation
import SwiftSignalKit

public class TimestampApiFetcher {
    var urlSession: URLSession
    var activeTask: URLSessionDataTask?
    
    public init() {
        self.urlSession = URLSession.shared
    }
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func getTimestamp() -> Signal<Int32?, NoError>  {
        return Signal<Int32?, NoError> { [weak self] subscriber in
            guard let strongSelf = self else { return EmptyDisposable }
            let urlString = "http://worldtimeapi.org/api/timezone/Europe/Moscow"
            
            guard let url = URL(string: urlString) else { return EmptyDisposable }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let dataTask = strongSelf.urlSession.dataTask(with: request) { data, response, error in
                Queue.mainQueue().async {
                    guard let data = data,
                          let jsonRaw = try? JSONSerialization.jsonObject(with: data, options: []),
                          let json = jsonRaw as? [String: Any],
                          let timestamp = json["unixtime"] as? Int32
                    else {
                        subscriber.putNext(nil)
                        return
                    }
                    subscriber.putNext(timestamp)
                    subscriber.putCompletion()
                }
            }
            
            strongSelf.activeTask = dataTask
            dataTask.resume()
            
            return ActionDisposable {
                strongSelf.activeTask?.cancel()
                strongSelf.activeTask = nil
            }
        }
    }
}
