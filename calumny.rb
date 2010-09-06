require 'java'
Dir.glob("./lib/*.jar").each{|x| require x;}
require 'rlmock' #where the voldemort interface lives
server = org.mortbay.jetty.Server.new(8080)
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
    input = request.getParameter('input')
    response.writer.println('<html><head><title>Output</title>
<style>pre { font-family: Courier, monospace; border: .1em dotted black; display: table; }</style>
<script src="static/dojo.js" type="text/javascript"></script>
<script type="text/javascript">
var list=[];
var timeout;
xhr=dojo._xhrObj()
function stop() { window.clearTimeout(timeout); xhr.onreadystatechange=replac; }
function replac() {
  if (xhr.readyState == 4){
      ret=JSON.parse(xhr.responseText); // dojo fromjson tojson replaced due to speed
      dojo.byId("upload").innerHTML=ret["ih"];
      eval(ret["js"]);
      if(list.length>0) { doKey(list.pop()); }
  }
}
function doKey(e) {
  if (xhr.readyState == 4 || xhr.readyState == 0){
     xhr.open("POST", "upload",true);
     xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     xhr.send("evt="+JSON.stringify([e.toString(),e["charOrCode"]]));
     window.clearTimeout(timeout);
     timeout=window.setTimeout ("doKey(\'time\')", 1000);
  } else { list.push(e); }
};
dojo.addOnLoad(function()
{ dojo.connect(document.documentElement, "onkeypress", this, doKey); 
  xhr.onreadystatechange=replac; 
  doKey("init"); });
</script></head>
<body><div id="upload"></div><button type="button" onclick="stop()" >stop client</button></body></html>')
    request.handled = true
  end
  def doPost(request, response)
    start = Time.now
    begin
      input=fromJson(request.getParameter('evt')).to_a
      #puts request.getRequestURI()
      if(input[1]!=nil)
        @rl.move(input[1])
      end
      if(not request.cookies or (request.cookies and request.cookies.select{|x| x.name=="rougelikeclient"}.length==0))
        puts "Baking new cookie"
        cookie=javax.servlet.http.Cookie.new("rougelikeclient","FILE")
        cookie.path="/"
        cookie.max_age=3600
        cookie.version=1
        response.addCookie(cookie)
      end    
      re=@rl.rlview()
      response.writer.println(@gson.toJson({:ih=>"<pre>#{re}</pre><b>Response Time=#{@response}</b>"}))
      request.handled = true
    rescue Exception=>e
      puts e,e.backtrace
    end
    @response=(Time.now - start).to_s
  end
end
puts "Launching server"
context=org.mortbay.jetty.servlet.Context.new(server, '/', 0)
holder =org.mortbay.jetty.servlet.ServletHolder.new(ViewServlet.new(RLMockup.new))
context.addServlet(holder, '/')
server.start()
