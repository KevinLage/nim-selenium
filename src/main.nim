import httpclient, uri, json, tables, base64

type 
    WebDriver* = ref object
        url*: Uri
        client*: HttpClient
    Session* = object
        id*: string
        driver*: WebDriver

    WebDriverException* = object of Exception
    ProtocolException* = object of WebDriverException

proc newWebDriver*(url: string = "http://localhost:4444"): WebDriver =
    return WebDriver(url: url.parseUri, client: newHttpClient())

proc createSession*(self: WebDriver): Session =
    let resp = self.client.getContent($(self.url / "status"))
    let parsed = parseJson(resp)

    if parsed["value"]["ready"].isNil():
        let msg = "Readiness message does not follow the spec"
        raise newException(ProtocolException, msg)

    if not parsed["value"]["ready"].getBool():
        raise newException(WebDriverException, "WebDriver is not Ready")

    let sessionReq = %*{"caoabilities": {}}
    let sessionResp = self.client.postContent($(self.url / "session"),
                                                        $sessionReq)
    #echo sessionResp

    let parsedid = parseJson(sessionResp)
    if parsedid["value"]["sessionId"].isNil():
        raise newException(ProtocolException, "no sessionId in response")
    
    return Session(id: parsedid["value"]["sessionId"].getStr(), driver: self)

proc navigate*(self: Session, url:string) =
    let requrl = $(self.driver.url / "session" / self.id / "url")
    let obj = %*{"url": url}
    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].getFields().len != 0:
        raise newException(WebDriverException, $respObj)

proc getCurrentUrl*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "url")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)
    let parsedObj = respObj["value"]
    if parsedObj.getFields().len != 0:
        raise newException(WebDriverException, $respObj)

    return parsedObj.getStr()

proc back*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "back")
    let obj = %*{"":""}
    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc forward*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "forward")
    let obj = %*{"":""}
    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

    
proc refresh*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "refresh")
    let obj = %*{"":""}
    let resp = self.driver.client.postContent(requrl, $obj)

    let respObj = parseJson(resp)
    if respObj["value"].kind != JNull:
        raise newException(WebDriverException, $respObj)

proc getTitle*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "title")
    let resp = self.driver.client.getContent(requrl)
    #echo resp
    let respObj = parseJson(resp)
    
    return respObj["value"].getStr() 

proc getWindowHandle*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "window")
    let resp = self.driver.client.getContent(requrl)
    
    let respObj = parseJson(resp)

    return respObj["value"].getStr() 

proc closeWindow*(self: Session) =
    let requrl = $(self.driver.url / "session" / self.id / "window")
    let resp = self.driver.client.deleteContent(requrl)

proc getPageSource*(self: Session): string =
    let requrl = $(self.driver.url / "session" / self.id / "source")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    return respObj["value"].getStr()

proc getAllCookies*(self: Session): seq =
    let requrl = $(self.driver.url / "session" / self.id / "cookie")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    return respObj["value"].getElems()

proc takeScreenshot(self: Session, filename: string) =
    let requrl = $(self.driver.url / "session" / self.id / "screenshot")
    let resp = self.driver.client.getContent(requrl)

    let respObj = parseJson(resp)

    let decoded = decode(respObj["value"].getStr())
    writeFile(filename, decoded)

when isMainModule:
    let webDriver = newWebDriver()
    let session = webdriver.createSession()
    #echo session
    session.navigate("https://example.com/")
    echo session.getWindowHandle()
    echo session.getAllCookies()
    session.takeScreenshot("test.png") 
    session.closeWindow()