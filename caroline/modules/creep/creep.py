import json
import os
import signal
import sys
from threading import Lock
import time
import urllib
import traceback
import re

confirmation = 'a274bda9c14e'

print >> sys.stderr, os.getpid()

interrupted = [False]
closing = [False]

report_lock = Lock()
reqs = {}
rsps = {}
cookie = [[""]]

def handler(signum, frame):
  interrupted[0] = True
  print >> sys.stderr, "quitting %s..." % (os.getpid(),)
  print >> sys.stderr, "final report"
  try:
    print json.dumps({'requests':reqs,'responses':rsps,'cookie':'Cookie: ' + cookie[0][0]})
  except Exception as e:
    print >> sys.stderr, "Problem: " % (e,)
  finally:
    sys.exit(0)
signal.signal(signal.SIGINT, handler)

def javascribe(str):
  try:
    str = str.decode('utf8')
  except Exception as e:
    return ''

  js = []

  for c in str:
    if len(bytearray(c,'utf8')) == 1:
      js.append(chr(bytearray(c,'utf8')[0]))
    else:
      js.append('\\u')
      c = bytearray(c.encode('utf16').decode('utf16'),'utf16')
      js.append(hex(c[3])[2:])
      js.append(hex(c[2])[2:])

  return ''.join(js)

def foo(ctx,flw):
  print >> sys.stderr, "headers:"
  print >> sys.stderr, flw.request.headers
  print >> sys.stderr, "content:"
  print >> sys.stderr, flw.request.content
  print >> sys.stderr, "scheme:"
  print >> sys.stderr, flw.request.scheme
  print >> sys.stderr, "host:"
  print >> sys.stderr, flw.request.host
  print >> sys.stderr, "port:"
  print >> sys.stderr, flw.request.port
  print >> sys.stderr, "path:"
  print >> sys.stderr, flw.request.path
  print >> sys.stderr, "method:"
  print >> sys.stderr, flw.request.method
  print >> sys.stderr
  print >> sys.stderr

def request(ctx,flw):
  req = flw.request
  url = req.url
  url = url.replace("logout","nopenopenope")
  url = url.replace("log-out","nopenopenope")
  url = url.replace("&crawlerforminject=true","")
  url = url.replace("?crawlerforminject=true","")

  label = None
  cur_cookie = None
  try:
    if confirmation in url:
      url,label = url.split(confirmation)
  except Exception as e:
    print >> sys.stderr, "Problem: %s" % (e,)
    print >> sys.stderr, "Problem url: %s" % (url,)
  req.url = url

  if label:
    #double encoded JSON
    label = urllib.unquote(label)
    label = urllib.unquote(label)
    label = json.loads(label)
    req.label = label

  try:
    if 'accept-encoding' in flw.request.headers.keys():
      del flw.request.headers['Accept-Encoding']
    #if 'referer' in flw.request.headers.keys():
    #  del flw.request.headers['Referer']
    if 'cookie' in flw.request.headers.keys():
      if flw.request.headers['Host'] == ['%s' % (sys.argv[3])]:
        cur_cookie = flw.request.headers['Cookie']
  except Exception as e:
    print >> sys.stderr, "Problem: %s" % (e,)

  if not label:
    return

  req_str = []
  req_str.append("%s %s HTTP/1.1\r\n" % (flw.request.method,urllib.unquote(url)))
  req_str.append(str(flw.request.headers))
  req_str.append("\r\n")
  if (flw.request.content):
    req_str.append(str(flw.request.content))
  req_str = ''.join(req_str)

  try:
    report_lock.acquire()
    reqs[label['tick']] = req_str
    if (cur_cookie):
      cookie[0] = cur_cookie
  except Exception as e:
    print >> sys.stderr, "Problem: %s" % (e,)
  finally:
    report_lock.release()

def response(ctx,flw):
  if interrupted[0]:
    flw.response.headers['Creep-Command'] = ['halt']
    #return

  #kerb free hack
  if 'www-authenticate' in flw.response.headers.keys():
    del flw.response.headers['WWW-Authenticate']


  if not hasattr(flw.request,'label'):
    flw.request.label = ''
    return

  label = flw.request.label

  rsp_str = []
  rsp_str.append("HTTP/1.1 %s\r\n" % (flw.response.code,))
  rsp_str.append(str(flw.response.headers))
  rsp_str.append("\r\n")

  try:
    if len(flw.response.headers['Content-Type']) > 0:
      content_type = flw.response.headers['Content-Type'][0].lower()
      if "text/" in content_type or "/javascript" in content_type or "/x-javascript" in content_type or "/ecmascript" in content_type or "/json" in content_type or "/x-json" in content_type or "/xml" in content_type or "/css" in content_type:
        flw.response.content = re.sub(r'(?i)mailto:',"#",flw.response.content)
        rsp_str.append(javascribe(flw.response.content),)
  except Exception as e:
    print >> sys.stderr, "problem: %s" % (e,)

  rsp_str = ''.join(rsp_str)

  try:
    report_lock.acquire()
    rsps[label['tick']] = rsp_str
  except Exception as e:
    print >> sys.stderr, "Problem: %s" % (e,)
  finally:
    report_lock.release()

def clientdisconnect(ctx, dis):
  None
