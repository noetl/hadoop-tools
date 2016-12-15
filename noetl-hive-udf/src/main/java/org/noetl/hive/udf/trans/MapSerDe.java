package org.noetl.hive.udf.trans;

import java.io.Serializable;
import java.util.Map;

import org.apache.commons.lang.SerializationUtils;
import org.apache.hadoop.hive.ql.exec.Description;

@Description("class = MapSerDe  - Class of Serialization and Deserialization of Map<String, Object>")
public class 	MapSerDe {

    @Description(name = "mapser", value = "Map<String, Object> - Returns serialized byte[]")
    public byte[] mapser(Map<String, Object> valMap) {
        return (byte[]) SerializationUtils.serialize((Serializable) valMap);
    }

    @Description(name = "mapde", value = "byte[] - Returns deserialized Map<String, Object>")
    public Map<?, ?> mapde(byte[] bt) {
        return (Map<?, ?>) SerializationUtils.deserialize(bt);
    }
}
