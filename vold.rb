module Vold #utility functions for jruby voldemort- could eventually be javaized for speed
    def toJson(list) 
      sw=java.io.StringWriter.new()
      JsonWriter.new(sw).writeList(list)
      return sw.toString()
    end
    def loc(i,j)
      return toJson(["LOC",i,j])
    end
    def fromJson(string)
      return JsonReader.new(java.io.StringReader.new(string)).readArray()
    end
    def col(string) #does not test for loc
      return fromJson(string)[1..2].to_a
    end
    class ModifyJson < UpdateAction
      def initialize(key,value)
        @key=key
        @value=value
        super()
      end
      def update(store) #consistency lives here
        vers=store.get(@key)
        vers.object=toJson(action(fromJson(vers.value)))
        store.put(@key,vers)
      end
    end
    class AppendJson < ModifyJson
      def action(thing)
        return thing << @value
      end
    end
    class DeleteJson < ModifyJson
      def action(thing)
        t=thing.to_a
        t.delete(@value);
        return t
      end
    end
end
