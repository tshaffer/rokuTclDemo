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
  showContentScreen()
end sub


Sub ProcessPlaybackPositionEvent(udp, videoId)
  udp.sendStr("roku:" + videoId)
End Sub


Function IsMediaEndEvent(msg) As Boolean
  return msg.isFullResult()
End Function


Function IsPlaybackProgressEvent(msg) As Boolean
  return msg.isPlaybackPosition()
End Function


Sub PrintVideoScreenEvent(msg)
  if msg.isStatusMessage() then
    print "status message: "; msg.GetMessage()
  else if msg.isFullResult() then
    print "isFullResult"
  else if msg.isRequestFailed() then
    print "request failed: "; msg.GetMessage()
  else if msg.isStreamStarted() then
    print "isStreamStarted"
    print "index = ";msg.GetIndex()
    print "info = ";msg.GetInfo()
  else if msg.isPlaybackPosition() then
    print "isPlaybackPosition"
    print "index = ";msg.GetIndex()
    print "info = ";msg.GetInfo()
  else if msg.isRequestFailed() then
    print "isRequestFailed"
  else if msg.isPaused() then
    print "isPaused"
  else if msg.isResumed() then
    print "isResumed"
  else if msg.isFormatDetected() then
    print "isFormatDetected"
    print "message = ";msg.GetMessage()
    print "info = ";msg.GetInfo()
  else if msg.isSegmentDownloadStarted() then
    eventRecognized = true
''    print "isSegmentDownloadStarted"
  else if msg.isDownloadSegmentInfo() then
    eventRecognized = true
''    print "isDownloadSegmentInfo"
  else if msg.isStreamSegmentInfo() then
    eventRecognized = true
''    print "isStreamSegmentInfo"
  else if msg.isTimedMetaData() then
    print "isTimedMetaData"
  else if msg.isCaptionModeChanged() then
    print "isCaptionModeChanged"
  else if msg.isRequestSucceeded() then
    print "isRequestSucceeded"
  else if msg.isListItemSelected() then
    print "isListItemSelected: index = ";msg.GetIndex()
  else
    print "unknown video screen event: "; msg.GetMessage()
  endif

End Sub


Function CreateUdp(msgPort) As Object

  udp = CreateObject("roDatagramSocket")
  udp.setMessagePort(msgPort) 'notifications for udp come to msgPort
  addr = CreateObject("roSocketAddress")
  addr.setPort(5000)
  udp.setAddress(addr) ' bind to all host addresses on port 5000
  addr.SetHostName("10.1.0.55")   ' BrightSign IP address
  udp.setSendToAddress(addr) ' destination IP and port
  udp.notifyReadable(true)

  return udp

End Function


Function PlayFromVideoScreen(port As Object, content As Object) As Object

  screen = CreateObject("roVideoScreen")
  screen.setMessagePort(port)
  screen.setLoop(true)
  screen.SetContent(content)
  screen.show()

  screen.SetPositionNotificationPeriod(4)

  return screen

End Function


Sub showContentScreen()

  print "main.brs - [showContentScreen]"
  msgPort = CreateObject("roMessagePort")

  udp = CreateUdp(msgPort)
  udp.sendStr("roku:attract")

  Stream = {}
  attractLoopUrl = "http://10.1.0.55:8080/Roku_4K_Streams/TCL_2017_C-Series_BBY_4K-res.mp4"
  Stream.url = attractLoopUrl

  content = {}
  content.Stream= Stream
  content.StreamFormat = "mp4"

  screen = PlayFromVideoScreen(msgPort, content)
  attractLoopPlaying = true
  videoId = "attract"

  while(true)
    msg = wait(0, msgPort)
    msgType = type(msg)

    if msgType="roSocketEvent" then
      if msg.getSocketID()=udp.getID() then
        if udp.isReadable() then
          message = udp.receiveStr(512) ' max 512 characters
          print "received socket message: '"; message; "'"

          print message

          if Instr(1, message, "videoId:") = 1 then
            videoId = mid(message, 9)
            print "videoId: ";videoId
          else
            url = message
            streamFormat = "mp4"
            Stream.url = url
            content.Stream= Stream
            content.StreamFormat = streamFormat

            screen = PlayFromVideoScreen(msgPort, content)
            attractLoopPlaying = false
          endif
        endif
      endif
    else if msgType = "roVideoScreenEvent" then

      PrintVideoScreenEvent(msg)

      if IsMediaEndEvent(msg) then
        ' restart attract loop
        Stream = {}
        Stream.url = attractLoopUrl
        content = {}
        content.Stream= Stream
        content.StreamFormat = "mp4"
        screen = PlayFromVideoScreen(msgPort, content)
        attractLoopPlaying = true
        videoId = "attract"

      else if IsPlaybackProgressEvent(msg) then
''        if attractLoopPlaying then
''          videoId = "attract"
''        else
''          videoId = "0"
''        endif
        ProcessPlaybackPositionEvent(udp, videoId)
      endif

    endif
  end while
end Sub

