java_import "voldemort.client.SocketStoreClientFactory"
java_import "voldemort.client.ClientConfig"
java_import "voldemort.client.UpdateAction"
java_import "voldemort.serialization.json.JsonReader"
java_import "voldemort.serialization.json.JsonWriter"
require 'matrix' #from jruby distribution. Has e2mmap.rb as dependency
require 'vold'
include Vold
class RLMockup
  def move(code)
    new=@location+@directions[code]
    aj=AppendJson.new(loc(*new.to_a),"@") #does not test, but will fail if empty
    dj=DeleteJson.new(loc(*@location.to_a),"@")
    @client.applyUpdate(aj)
    @client.applyUpdate(dj)
    @location=new
  end
  def rlview()
    wholeview=@view*2
    up=@location-@view
    down=@location+@view
    objstore=Array.new(wholeview[0]+1) { Array.new(wholeview[1]+1,"#") }
    v=(up[0]..down[0]).map{|x| (up[1]..down[1]).map{|y| loc(x,y) }}.flatten
    map=@client.getAll(v)
    map.entrySet().iterator().each{|entry| 
      x,y=col(entry.key); 
      objstore[x-up[0]][y-up[1]]=fromJson(entry.value.value).to_a.last 
    }
    return objstore.map{|line| line.join("")}.join("\n")
  end
  def initialize()
    bootstrapUrl = "tcp://localhost:6666";
    factory = SocketStoreClientFactory.new(ClientConfig.new.setBootstrapUrls(bootstrapUrl));
    @client = factory.getStoreClient("test");
    IO.readlines("./dun").each_with_index{|x,i| x.split("").each_with_index{|y,j| if y!="#" then @client.put(loc(i,j),toJson([y])) else @client.delete(loc(i,j)) end}}
    @directions={38=>Vector[*[-1,0]],37=>Vector[*[0,-1]],40=>Vector[*[1,0]],39=>Vector[*[0,1]]}
    @location=Vector[*[4,4]]
    @view=Vector[*[10,20]]
    aj=AppendJson.new(loc(*@location.to_a),"@")
    @client.applyUpdate(aj)
  end
end
