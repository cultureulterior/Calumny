require 'java'
Dir.glob("./lib/*.jar").each{|x| require x;}
java_import "voldemort.client.SocketStoreClientFactory"
java_import "voldemort.client.ClientConfig"
java_import "voldemort.client.UpdateAction"
java_import "voldemort.serialization.json.JsonReader"
java_import "voldemort.serialization.json.JsonWriter"
require 'vold'
include Vold
bootstrapUrl = "tcp://localhost:6666"; 
factory = SocketStoreClientFactory.new(ClientConfig.new.setBootstrapUrls(bootstrapUrl));
client = factory.getStoreClient("test");
asc=[" ","#",".","w","d","o","@","M","$","t"]
a={}
asc.each_with_index{|x,i| a[x]=i}
p a
IO.readlines("./dun.emacs").each_with_index{|x,i| 
  x.split("").each_with_index{|y,j| 
    if y!="#" 
      client.put(loc(i,j),toJson([0,a[y]])) 
    else 
      client.delete(loc(i,j)) 
    end}}
