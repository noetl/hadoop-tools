package org.nonoetl.hive.udf.trans;

import org.apache.hadoop.hive.ql.exec.UDF;

/**
 * CREATE TEMPORARY  FUNCTION maskup AS 'org.noetl.hive.udf.trans.MaskUp';
 *
 */

public class MaskUp extends UDF {

    String[] lastKeys;
    String preval;

    public String evaluate(String id, int key) {
        int code0 = 48;                                 //48 is ASCII code for '0'
        StringBuffer mid = new StringBuffer(id);
        int temp;
        for(int i=0; i < mid.length(); i++){
            if(mid.charAt(i)!='0'){
                temp = mid.charAt(i) - code0;
                temp = (temp + key) % 10;
                if(temp < key) temp++;
                mid.setCharAt(i, (char)(temp + code0)); //set converted int to char into masked id
            }
        }
        return mid.toString();
    }
}

