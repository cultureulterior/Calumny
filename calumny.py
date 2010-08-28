#!/usr/bin/python
# -*- coding: utf-8 -*-
import cherrypy # requires python-cherrypy3 
import numpy
import random
import time
class rl(object):
    def __init__(self,loc):
        self.loc=numpy.array(loc)
        self.m=numpy.transpose(numpy.array([map(ord,i) for i in open("./dun").read().split("\n")], dtype=numpy.int))                  # mapmaking via mx artist-mode
        self.m[tuple(self.loc)]=ord("@")
        self.v=numpy.array([25,10])      # visible field
        self.s=numpy.array(self.m.shape) # array shape
        self.z=numpy.array([0,0])
    directions={37:numpy.array([-1,0]),38:numpy.array([0,-1]),39:numpy.array([1,0]),40:numpy.array([0,1])}
    def move(self,event):
        if event["keyCode"]!="undefined" and int(event["keyCode"]) in self.directions:
           motion=self.directions[int(event["keyCode"])]
           self.m[tuple(self.loc)]=ord(" ")
           self.loc+=motion
           self.m[tuple(self.loc)]=ord("@")
        return self.rlview()
    def char(self):
        return r'''<div style="position:absolute;left:%dem;top:%dem;"><pre>Name:%s
Location:%d,%d<pre></div>'''%(self.v[0]+2,0,str(self),self.loc[0],self.loc[1])
    def rlview(self):
        a=numpy.minimum(self.s-2*self.v,numpy.maximum(self.z,self.loc-self.v))
        b=a+2*self.v
        return (u"<pre>"+(u"\n".join("".join(map(unichr,self.m[a[0]:b[0],index])) for index in range(a[1],b[1])))+u"</pre>").encode("utf-8")+self.char()
class view(object):
    def __init__(self):
        self.i=0
        self.rls={}
    @cherrypy.expose
    def upload(self,evt):
        self.i+=1
        rli=self.getrli()
        event=dict(par.split(":",1) for par in evt.strip().split("\n"))
        return self.rls[rli].move(event)+("</pre><br><b>%d events ok</b>"%self.i).encode("utf-8")
        return "<b>OK %d</b>"%self.i
    def getrli(self):
        rli=cherrypy.request.cookie.get('rougelikeinstance',None)
        if rli==None:
            cookie = cherrypy.response.cookie
            rli=str(time.time())
            cookie['rougelikeinstance']=rli
            cookie['rougelikeinstance']['path'] = '/'
            cookie['rougelikeinstance']['max-age'] = 3600
            cookie['rougelikeinstance']['version'] = 1
        else:
            rli=rli.value
        if self.rls.get(rli,None) == None:            
            print "RESETTING CHARACTER"
            self.rls[rli]=rl((10,10))
        return rli
    @cherrypy.expose
    def index(self,*args):
        return r'''<html><head>
<style>
pre { font-family: Courier, monospace; border: .1em dotted black; display: table; }
</style>
<script type="text/javascript">
var list=[];
var timeout;
var xhr = new XMLHttpRequest();
var keys=["timeStamp","altKey","shiftKey","ctrlKey","metaKey","keyLocation","type","keyIdentifier","keyCode","charCode","button","clientX","clientY"];
function replac() {
  if (xhr.readyState == 4){
    if(list.length>0) {
        doKey(list.pop());
      }
      document.getElementById('upload').innerHTML=xhr.responseText;
  }
}
function doKey(e) {
  if (xhr.readyState == 4 || xhr.readyState == 0){    
     var params="evt=eventstring:"+e.toString()+"\n";
     for (attr in keys)
        params+=keys[attr]+":"+e[keys[attr]]+"\n";
     xhr.open("POST", "upload",true);
     xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     xhr.send(params);
     window.clearTimeout(timeout);
     timeout=window.setTimeout ("doKey('TIME')", 1000);
  } else {
     list.push(e)
  }
};
function stop() {
    window.clearTimeout(timeout);
    xhr.onreadystatechange=stop;
}
onload=function()
{
  if(navigator.userAgent.indexOf("Gecko/")==-1)
  { document.onkeydown=doKey; }
  else
  { document.onkeypress=doKey; }
  xhr.onreadystatechange=replac;
  doKey("INIT");
  timeout=window.setTimeout ("doKey('TIME')", 1000);

}
</script>
</head><body><div id="upload"></div><button type="button" onclick="stop()" >stop client</button></body></html>'''
cherrypy.quickstart(view())
