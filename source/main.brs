' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function called when channel application starts.
sub Main(input as Dynamic)
  print "################"
  print "Start of Channel"
  print "################"
  ' Add deep linking support here. Input is an associative array containing
  ' parameters that the client defines. Examples include "options, contentID, etc."
  ' See guide here: https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
  ' For example, if a user clicks on an ad for a movie that your app provides,
  ' you will have mapped that movie to a contentID and you can parse that ID
  ' out from the input parameter here.
  ' Call the service provider API to look up
  ' the content details, or right data from feed for id
  if input <> invalid
    print "Received Input -- write code here to check it!"
    print input
    if input.reason <> invalid
      if input.reason = "ad" then
        print "Channel launched from ad click"
        'do ad stuff here
      end if
    end if
    if input.contentID <> invalid
      m.contentID = input.contentID
      print "contentID is: " + input.contentID
      'launch/prep the content mapped to the contentID here
    end if
  end if
  showHeroScreen()
end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen()



  print "main.brs - [showHeroScreen]"
''  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")

  print "create video player"
  v = CreateObject("roVideoPlayer")
  v.SetDestinationRect(0, 0, 1920, 1080)
  print v
  v.setMessagePort(m.port)

''  stream = {}
''  stream.url = "http://10.1.0.95:3000/Roku_4K_Streams/TCL_2017_C-Series_BBY_4K-res.mp4"
''  stream.url = "http://10.1.0.95:3000/fox5/play.m3u8"
''  stream.quality = true
''  stream.contentid = "bsStream"

''  content = {}
''  content.streamFormat = "mp4"
''  content.url = "http://10.1.0.95:3000/Roku_4K_Streams/TCL_2017_C-Series_BBY_4K-res.mp4"
''  content.streamFormat = "mp4"
''  content.url = "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"

''  content.Stream = stream

 '' v.AddContent(content)

''  content = {
''    Stream: { url : "http://10.1.0.95:3000/fox5/play.m3u8" }
''    StreamFormat: "hls"
''    Stream: { url : "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4" }
''  }

  Stream = {}
''  Stream.url = "http://10.1.0.95:3000/fox5/play.m3u8"
  Stream.url = "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"

  content = {}
  content.Stream= Stream
''  content.StreamFormat = "hls"
  content.StreamFormat = "mp4"

  contentList = []
  contentList.push(content)

  v.setContentList( contentList )

  print v

  ok = v.Play()
  print ok

  udp = createobject("roDatagramSocket")
  udp.setMessagePort(m.port) 'notifications for udp come to msgPort
  addr = createobject("roSocketAddress")
  addr.setPort(5000)
  udp.setAddress(addr) ' bind to all host addresses on port 5000
  addr.SetHostName("10.8.1.89")
  udp.setSendToAddress(addr) ' peer IP and port
  udp.notifyReadable(true)

''  screen.setMessagePort(m.port)
''  scene = screen.CreateScene("SimpleVideoScene")
''  screen.show()

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    print msgType
    if msgType = "roSGScreenEvent"
''      if msg.isScreenClosed() then return
      if msg.isScreenClosed() then return
      stop
    else if msgType="roSocketEvent" then
      if msg.getSocketID()=udp.getID() then
        if udp.isReadable() then
          message = udp.receiveStr(512) ' max 512 characters
          print "received socket message: '"; message; "'"
        endif
      endif
    else if msgType = "roVideoPlayerEvent" then
      print "roVideoPlayerEvent received"
''      print "isStreamStarted: "; msg.isStreamStarted()
''      print "isStatusMessage: "; msg.isStatusMessage()
''      print "isFormatDetected: "; msg.isFormatDetected()
''      print "isRequestFailed: "; msg.isRequestFailed()
''      print "isRequestSucceeded: "; msg.isRequestSucceeded()

      if msg.isStatusMessage() then
        print "status message: "; msg.GetMessage()
      else if msg.isRequestFailed() then
        print "request failed: "; msg.GetMessage()
        ' An unexpected problem (but not server timeout or HTTP error) has been detected
      else
        print "unknown video player event: "; msg.GetMessage()
      endif
    end if
  end while
end sub
