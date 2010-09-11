java_import "voldemort.client.SocketStoreClientFactory"
java_import "voldemort.client.ClientConfig"
java_import "voldemort.client.UpdateAction"
java_import "voldemort.serialization.json.JsonReader"
java_import "voldemort.serialization.json.JsonWriter"
require 'matrix' #from jruby distribution. Has e2mmap.rb as dependency
require 'vold'
require 'thread'
require 'digest/sha2'
include Vold
class ModifyUserLocation < ModifyJson
  def action(thing)
    loc=Vector[*thing.to_a]
    loc=loc+@value
    return loc.to_a
  end
end
class RLMockup
  def move(code,id) #does not test. fails badly on empty squares
    oldloc=location(id)
    sw=ModifyUserLocation.new(toJson(['USR/LOC',id]),@directions[code])
    @client.applyUpdate(sw)
    aj=AppendJson.new(loc(*location(id).to_a),6) 
    dj=DeleteJson.new(loc(*oldloc.to_a),6)    
    @client.applyUpdate(aj)
    @client.applyUpdate(dj)
  end
  def rlview(id) #gets view data in 2d array form
    wholeview=@view*2
    location=location(id)
    up=location-@view
    down=location+@view
    objstore=Array.new(wholeview[0]+1) { Array.new(wholeview[1]+1,[1]) }
    v=(up[0]..down[0]).map{|x| (up[1]..down[1]).map{|y| loc(x,y) }}.flatten
    map=@client.getAll(v)
    map.entrySet().iterator().each{|entry| 
      x,y=col(entry.key); 
      objstore[x-up[0]][y-up[1]]=fromJson(entry.value.value).to_a 
    }
    return objstore
  end
  def location(id) 
    return Vector[*(fromJson(@client.get(toJson(['USR/LOC',id])).value).to_a)];
  end
  def spawn(login) # Combined login / create user
    puts "Logging into voldemort"
    p login
    user=(Digest::SHA2.new << toJson(login)).to_s[0..8]
    if username(user)==nil 
      puts "Creating character"
      @client.put(toJson(['USR/LOC',user]),toJson(Vector[*[4,4]].to_a))
      @client.put(toJson(['USR/NAME',user]),login[0])
    end
    aj=AppendJson.new(loc(*location(user).to_a),6)
    @client.applyUpdate(aj)
    return user
  end
  def username(charid) #hashed id to username
    char=@client.get(toJson(['USR/NAME',charid]))    
    if char then return char.value else return nil end
  end
  def initialize()
    bootstrapUrl = "tcp://localhost:6666";
    factory = SocketStoreClientFactory.new(ClientConfig.new.setBootstrapUrls(bootstrapUrl));
    @client = factory.getStoreClient("test");
    @directions={38=>Vector[*[-1,0]],37=>Vector[*[0,-1]],40=>Vector[*[1,0]],39=>Vector[*[0,1]]}
    @view=Vector[*[10,20]]
  end
end
