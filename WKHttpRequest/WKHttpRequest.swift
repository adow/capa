//
//  WKHttpRequest.swift
//  WKHTTPRequestSwift
//
//  Created by 秦 道平 on 14-9-18.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation

let global_queue:NSOperationQueue=NSOperationQueue()

typealias dataCallback=(data:NSData)->()
typealias textCallback=(text:NSString?)->()
typealias errorCallback=(error:NSError)->()

/// MARK: - Form
///form表单中的一行
struct FormItem {
    let name:String
    let filename:String?
    let filedata:NSData?
    let value:String?
    func to_data(boundary:String)->(NSData){
        let data=NSMutableData()
        let header:NSString="--\(boundary)\r\n"
        data.appendData(header.dataUsingEncoding(NSUTF8StringEncoding)!)
        if let filedata = self.filedata{
            let key:NSString="Content-Disposition: form-data; name=\"\(self.name)\"; filename=\"\(self.filename!)\"\r\n"
            let type:NSString="Content-Type: application/octet-stream\r\n\r\n"
            data.appendData(key.dataUsingEncoding(NSUTF8StringEncoding)!)
            data.appendData(type.dataUsingEncoding(NSUTF8StringEncoding)!)
            data.appendData(filedata)
        }
        else{
            let key:NSString="Content-Disposition: form-data; name=\"\(self.name)\"\r\n\r\n"
            data.appendData(key.dataUsingEncoding(NSUTF8StringEncoding)!)
            if let value:NSString = self.value {
                data.appendData(value.dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        
        return data
    }
}
///创建多行的form内容
func _generate_http_body_multipule(items:Array<FormItem>,boundary:String)->(NSData){
    let data:NSMutableData = NSMutableData()
    for item:FormItem in items{
        let item_data=item.to_data(boundary)
        data.appendData(item_data)
        let returnStr:NSString="\r\n"
        data.appendData(returnStr.dataUsingEncoding(NSUTF8StringEncoding)!)
        if items.last!.name == item.name {
            let bottom:NSString="--\(boundary)--"
            data.appendData(bottom.dataUsingEncoding(NSUTF8StringEncoding)!)
        }
    }
    return data
}
///创建普通的form内容
func _generate_http_body_plain(items:Array<FormItem>)->NSData{
    var str=""
    for item:FormItem in items {
        str+="\(item.name)="
        if let has_value = item.value?.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) {
            str+=has_value
        }
        str+="&"
    }
    let str2=str as NSString
    return str2.dataUsingEncoding(NSUTF8StringEncoding)!
    
}
///form 是否带有文件数据，有文件数据的话将是多行内容
func _is_multiplue_form(items:Array<FormItem>)->Bool{
    for item:FormItem in items{
        if let _ = item.filedata {
            return true;
        }
    }
    return false;
}

/// MARK: - http
///通用http,提供request
func _http_request(request:NSURLRequest,
    onData:dataCallback,
    onError:errorCallback?=nil){
        NSURLConnection.sendAsynchronousRequest(request, queue:global_queue) { (response, data, error) -> Void in
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                NSLog("%@", request.URL.absoluteString!)
                if (error != nil){
                    NSLog("%@", error)
                    onError?(error: error)
                }
                else{
                    onData(data:data)
                }
            })            
        }
}
///通用http,提供method和url
func _http_url(method:String,
    url:NSURL,
    onData:dataCallback,
    onError:errorCallback?=nil){
        let request=NSMutableURLRequest(URL: url)
        request.HTTPMethod=method
        _http_request(request, { (data) -> () in
            onData(data: data)
        }) { (error) -> () in
            if let errorBlock = onError{
                errorBlock(error: error)
            }
        }
}

/// MARK: - GET
///get,返回字符串
func http_get_text(url:NSURL,
    onText:textCallback,
    onError:errorCallback?=nil){
        _http_url("GET",url,{(data)->() in
            let text:NSString?=NSString(data: data, encoding: NSUTF8StringEncoding)
                onText(text: text)
            }){(error)->() in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
            }
}
///get,返回data
func http_get_data(url:NSURL,
    onData:dataCallback,
    onError:errorCallback?=nil){
        _http_url("GET", url,{ (data) -> () in
            onData(data: data);
            }){(error)->() in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
        }
}
///get,返回json
func http_get_json(url:NSURL,
    onJson:(json:AnyObject?)->(),
    onError:((error:NSError)->())?=nil){
        _http_url("GET", url,
            { (data) -> () in
                let json: AnyObject?=NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                onJson(json: json)
            }){(error)->() in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
                
        }
}

/// MARK: - POST
///post,返回data
func http_post_data(url:NSURL,
    forms:Array<FormItem>?,
    onData:dataCallback,
    onError:errorCallback?=nil){
        let request=NSMutableURLRequest(URL: url)
        request.HTTPMethod="POST"
        if forms != nil && forms!.count>0{
            let boundary=NSUUID().UUIDString
            if _is_multiplue_form(forms!) {
                let contentType="multipart/form-data; boundary=\(boundary)"
                request.addValue(contentType, forHTTPHeaderField:"Content-Type")
                request.HTTPBody=_generate_http_body_multipule(forms!, boundary)
            }
            else{
                let contentType="application/x-www-form-urlencoded"
                request.addValue(contentType, forHTTPHeaderField:"Content-Type")
                request.HTTPBody=_generate_http_body_plain(forms!)
            }
            
        }
        
        _http_request(request, { (data) -> () in
            let test:NSString?=NSString(data: data, encoding: NSUTF8StringEncoding)
            onData(data: data)
        }) { (error) -> () in
            if let errorBlock = onError {
                errorBlock(error:error)
            }
        }
}
///post,返回字符串
func http_post_text(url:NSURL,
    forms:Array<FormItem>?,
    onText:textCallback,
    onError:errorCallback?=nil){
        http_post_data(url, forms, { (data) -> () in
            let text:NSString?=NSString(data: data, encoding: NSUTF8StringEncoding)
            onText(text: text)
        }) { (error) -> () in
            if let errorBlock = onError {
                errorBlock(error: error)
            }
        }
}
///post,返回json
func http_post_json(url:NSURL,
    forms:Array<FormItem>?,
    onJson:(json:AnyObject?)->(),
    onError:errorCallback?=nil){
        http_post_data(url, forms, { (data) -> () in
            let json: AnyObject?=NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil)
            onJson(json: json)
        }) { (error) -> () in
            if let errorBlock = onError {
                errorBlock(error: error)
            }
        }
}

/// MARK: - PUT
///put,返回data
func http_put_data(url:NSURL,
    forms:Array<FormItem>?,
    onData:dataCallback,
    onError:errorCallback?=nil){
        let request=NSMutableURLRequest(URL: url)
        request.HTTPMethod="PUT"
        if forms != nil && forms!.count>0{
            let boundary=NSUUID().UUIDString
            if _is_multiplue_form(forms!) {
                let contentType="multipart/form-data; boundary=\(boundary)"
                request.addValue(contentType, forHTTPHeaderField:"Content-Type")
                request.HTTPBody=_generate_http_body_multipule(forms!, boundary)
            }
            else{
                let contentType="application/x-www-form-urlencoded"
                request.addValue(contentType, forHTTPHeaderField:"Content-Type")
                request.HTTPBody=_generate_http_body_plain(forms!)
            }
            
        }
        _http_request(request, { (data) -> () in
            onData(data: data)
            }) { (error) -> () in
                if let errorBlock = onError {
                    errorBlock(error:error)
                }
        }
}
///put,返回字符串
func http_put_text(url:NSURL,
    forms:Array<FormItem>,
    onText:textCallback,
    onError:errorCallback?=nil){
        http_put_data(url, forms, { (data) -> () in
            let text:NSString?=NSString(data: data, encoding: NSUTF8StringEncoding)
            onText(text: text)
            }) { (error) -> () in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
        }
}
///put,返回json
func http_put_json(url:NSURL,
    forms:Array<FormItem>,
    onJson:(json:AnyObject?)->(),
    onError:errorCallback?=nil){
        http_put_data(url, forms, { (data) -> () in
            let json: AnyObject?=NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil)
            onJson(json: json)
            }) { (error) -> () in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
        }
}

/// MARK: - DELETE
///delete,返回data
func http_delete_data(url:NSURL,
    onData:dataCallback,
    onError:errorCallback?=nil){
        let request=NSMutableURLRequest(URL: url)
        request.HTTPMethod="delete"
        _http_request(request, { (data) -> () in
            onData(data: data)
            }) { (error) -> () in
                if let errorBlock = onError {
                    errorBlock(error:error)
                }
        }
}
///delete,返回text
func http_delete_text(url:NSURL,
    onText:textCallback,
    onError:errorCallback?=nil){
        http_delete_data(url,{ (data) -> () in
            let text:NSString?=NSString(data: data, encoding: NSUTF8StringEncoding)
            onText(text: text)
            }) { (error) -> () in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
        }
}
///delete,返回json
func http_delete_json(url:NSURL,
    onJson:(json:AnyObject?)->(),
    onError:errorCallback?=nil){
        http_delete_data(url, { (data) -> () in
            let json: AnyObject?=NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil)
            onJson(json: json)
            }) { (error) -> () in
                if let errorBlock = onError {
                    errorBlock(error: error)
                }
        }
}
