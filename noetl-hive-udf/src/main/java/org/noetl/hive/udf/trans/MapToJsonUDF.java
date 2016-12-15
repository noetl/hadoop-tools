package org.noetl.hive.udf.trans;

import java.io.IOException;
import java.rmi.NotBoundException;
import java.text.ParseException;
import java.util.Map;

import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDF;
import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.map.JsonMappingException;
import org.codehaus.jackson.map.ObjectMapper;


/**
 * CREATE TEMPORARY  FUNCTION Map_to_json AS 'org.hive.udf.trans.MapToJsonUDF';
 */

@Description(name = "to_json_string", value = "_FUNC_(pars...) - Returns JsonString of all fields and values", extended = "Example:\n"
        + "select Map_to_json('product_name',product_name,'product_category',product_category) as json_string"
        + " from product ")
public class MapToJsonUDF extends UDF {

    public static final JsonFactory factory = new JsonFactory();

    public static final ObjectMapper mapper = new ObjectMapper(factory);


    static boolean checkprint = true;

    public String evaluate(String... pairs) throws NotBoundException {
        if (pairs.length % 2 != 0)
            throw new NotBoundException("Not even number of parameters ...");

        try {
            return  mapper.writeValueAsString(MapGenerator.mapGen(pairs));
        } catch (Exception e) {
            return "JSON conversion failed - " + e;
        }

    }

    public String evaluate(Map<String,String> maparg) throws ParseException {
        try {
            if (checkprint) {
                checkprint = false;
            }
            return mapper.writeValueAsString(maparg);
        } catch (JsonGenerationException e) {
            e.printStackTrace();
        } catch (JsonMappingException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "JSON conversion failed";

    } // evaluate(Map<String,String> mapargs)

} // Map2JsonUDF

