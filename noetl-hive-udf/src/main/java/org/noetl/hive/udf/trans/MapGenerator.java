package org.noetl.hive.udf.trans;

import java.util.HashMap;

/**class = MapGenerator  - Class of Generator of Map<String, String>")
 *
 * @author Alexey Kuksin
 *
 */

public class MapGenerator {

    public static HashMap<String, String> mapGen(String... vals){

        HashMap<String, String> result = new HashMap<String, String>();

        if(vals.length % 2 != 0)
            throw new IllegalArgumentException("arguments are wrong");

        String key = null;
        Integer step = -1;

        for(String value : vals){
            switch(++step % 2){
                case 0:
                    if(value == null)
                        throw new IllegalArgumentException("Key is null");
                    key = value;
                    continue;
                case 1:
                    result.put(key, value);
                    break;
            }
        }

        return result;
    }
}
