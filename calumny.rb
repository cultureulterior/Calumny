require 'java'
Dir.glob("./lib/*.jar").each{|x| require x;}
require 'rlmock' #where the voldemort interface lives
server = org.mortbay.jetty.Server.new(8080)
thread_pool = org.mortbay.thread.QueuedThreadPool.new
thread_pool.min_threads  = 10 
thread_pool.max_threads  = 20
server.set_thread_pool(thread_pool)
context_static = org.mortbay.jetty.servlet.Context.new(server, '/static', 0)
context_static.handler=org.mortbay.jetty.handler.ResourceHandler.new
context_static.resource_base='./static'
context_static.context_path='/static'
class ViewServlet < javax.servlet.http.HttpServlet
  def initialize(rl)
    @gson=com.google.gson.Gson.new() #will use vold.rb eventually. It's faster than gson 
    @rl=rl
    super()
    @response=0
    puts "Ready to serve"
  end
  def doGet(request, response)
    input = request.getParameter('input') #main page
    response.writer.println('<html><head><title>Calumny</title>
<style>div,pre { font-family: Courier, monospace; border: .1em dotted black; display: table; }</style>
<script src="static/dojo.js" type="text/javascript"></script>
<script type="text/javascript">
var img=[]; for(var i in [0,1,2,3,4,5,6,7,8]) {img[i]=new Image();img[i].src="static/tiles/"+i+".png"}
asc=[" ","#",".","w","d","o","@","M","$","t"]; //cache basic replacement images and characters.
var list=[]; var data=null;
var timeout; var timeagain=true; keyconn=null;
xhr=dojo._xhrObj();
function connectkey() { if(keyconn==null) {keyconn=dojo.connect(document.documentElement, "onkeypress", this, doKey);} }
function stop()  { timeagain=false; timer(); dojo.disconnect(keyconn); keyconn=null; list=[]; }
function start()  { timeagain=true; timer(); connectkey();}
function timer()  { window.clearTimeout(timeout); if (timeagain) {timeout=window.setTimeout ("doEvt([\'time\',1000])", 1000);} }
function logout() { doEvt(["logout"]); }
function login() { doEvt(["login",dojo.byId("lu").value,dojo.byId("lp").value]); }
function creat() { doEvt(["create",dojo.byId("cu").value,dojo.byId("cp").value]); }
function asciiview() {
   view=data["view"]
   if(view==null)
   { dojo.byId("upload").innerHTML="<div id=error>Error: No View Data</div>" }
   else {  
     for(var i=0; i<view.length;i++)
       {for(var j=0; j<view[i].length;j++)
         { var contents=view[i][j];
           view[i][j]=asc[contents[contents.length-1]];}
           view[i]=view[i].join(""); }
     dojo.byId("upload").innerHTML=("<pre>"+view.join("\n")+"<pre>"+data["after"]); }
}
function setdata() { dojo.byId("upload").innerHTML=data; }
function canvasview() {}
function webglview() {}
function replac() {
  if (xhr.readyState == 4){
      ret=JSON.parse(xhr.responseText); // dojo fromjson tojson replaced due to speed
      //dojo.byId("upload").innerHTML=ret["ih"];
      data=ret["data"];
      eval(ret["js"]);
      if(list.length>0) { doEvt(list.pop()); }
  }
}
function doEvt(e) {
  if (xhr.readyState == 4 || xhr.readyState == 0){
     xhr.open("POST","evt/"+e[0],true);
     xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     xhr.send("evt="+JSON.stringify(e));     
     timer();
  } else { list.push(e); }
};
function doKey(e) { doEvt(["key",e["charOrCode"]]); }
dojo.addOnLoad(function()
{ connectkey();
  xhr.onreadystatechange=replac; 
  doEvt(["init"]); });
</script></head>
<body><h5>calumny</h5><div id="upload"></div><div id="control">
<button type="button" onclick="stop()" >stop client</button>
<button type="button" onclick="start()" >start client</button>
<button type="button" onclick="logout()" >logout client</button>
</div></body></html>')
    request.handled = true
  end
  def doPost(request, response)
    start = Time.now
    begin
      input=fromJson(request.getParameter('evt')).to_a # p input
      cookies = request.cookies.to_a.select{|x| x.name=="rougelikeclient"}
      if cookies.length>0 and (username=@rl.username((id=cookies[0].value)))!=nil #if is logged in and exists
        if(input[0]=="key" and (motion=input[1])!=nil)
          @rl.move(input[1],id)
        end
        re=@rl.rlview(id)
        response.writer.println(@gson.toJson({:js=>'start();asciiview();',:data=>{:view=>re,:after=>"Response Time=#{(Time.now - start).to_s}\nUsername=#{username}\nLocation=#{@rl.location(id).to_s}"}}))
      elsif ( input[0]=="login" or input[0]=="create" ) and input.length==3 and (username=input[1].gsub(/\W+/,""))!="" and (password=input[2])!="" #if user does not exist or is not logged in, but we got a login string
        puts "Logging in"
        val=@rl.spawn([username,password]) #login or create user, depending if user was known
        cookie=javax.servlet.http.Cookie.new("rougelikeclient",val)
        cookie.path="/"
        cookie.max_age=3600
        cookie.version=1
        response.addCookie(cookie)
        re=@rl.rlview(val) 
        response.writer.println(@gson.toJson({:js=>'start();asciiview();',:data=>{:view=>re,:after=>"Response Time=#{(Time.now - start).to_s}\nUsername=#{username}\nLocation=#{@rl.location(val).to_s}"}}))
      else # show login
        response.writer.println(@gson.toJson({:data=>'
<div id="up">
  <h2>Log In</h2>
  <div>Username:<input type="text" id="lu"></div>
  <div>Password: <input type="password" name="pwd" id="lp"></div>
<div id="l"><button type="button" onclick="login()">Log in!</button></div></div>
  <div id="create">
  <h2>Create Account</h2>
  <div>Username:<input type="text" id="cu"></div>
  <div>Password: <input type="password" name="pwd" id="cp"></div>
<div id="l"><button type="button" onclick="creat()">Create Account!</button></div></div>
', :js=>'stop();setdata();'}))
      end
      request.handled = true
    rescue Exception=>e
      puts "Exception: #{e}\nBacktrace:#{e.backtrace}"
    end    
  end
end
puts "Launching server"
context=org.mortbay.jetty.servlet.Context.new(server, '/', org.mortbay.jetty.servlet.Context::NO_SESSIONS)
holder =org.mortbay.jetty.servlet.ServletHolder.new(ViewServlet.new(RLMockup.new))
context.addServlet(holder, '/')
server.start()
